import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../Developer/DynamicForms/dynamic_forms_repository.dart';
import '../../../Developer/DynamicForms/form_models.dart';
import 'models/assignment_data.dart';
import 'widgets/task_form_renderer.dart';

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({super.key});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  static const String tenantId = 'default_tenant';

  static FormSchemaMeta? _cachedTaskCreationForm;
  static Object? _cachedLoadError;

  final DynamicFormsRepository _repo = DynamicFormsRepository();
  final GlobalKey<TaskFormRendererState> _rendererKey =
      GlobalKey<TaskFormRendererState>();

  FormSchemaMeta? _form;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (_cachedTaskCreationForm != null || _cachedLoadError != null) {
      _form = _cachedTaskCreationForm;
      _loading = false;
    } else {
      _loadFormOnce();
    }
  }

  Future<void> _loadFormOnce() async {
    try {
      final forms = await _repo.loadForms(tenantId);
      final found = forms.firstWhere(
        (f) => f.formId == 'task_creation',
        orElse: () => forms.first,
      );
      _cachedTaskCreationForm = found;
      _cachedLoadError = null;
      if (!mounted) return;
      setState(() {
        _form = found;
        _loading = false;
      });
    } catch (e) {
      _cachedLoadError = e;
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _createTaskFromPayload(Map<String, dynamic> values) async {
  final user = FirebaseAuth.instance.currentUser;
  debugPrint('TASK_CREATE: createTaskFromPayload START, values=$values');

  if (user == null) {
    debugPrint('TASK_CREATE: ERROR – user is null (not logged in)');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You must be logged in to create a task'),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  setState(() => _submitting = true);

  try {
    final now = DateTime.now();
    final tasksCol = FirebaseFirestore.instance
        .collection('tenants')
        .doc(tenantId)
        .collection('tasks');

    debugPrint('TASK_CREATE: tasksCol path = tenants/$tenantId/tasks');

    final renderer = _rendererKey.currentState;
    if (renderer == null) {
      debugPrint('TASK_CREATE: ERROR – rendererKey.currentState is null');
      throw Exception('Form renderer not available');
    }

    final assignmentData = renderer.getAssignmentData();
    debugPrint('TASK_CREATE: assignmentData = $assignmentData');

    if (assignmentData == null || !assignmentData.isValid) {
      debugPrint('TASK_CREATE: ERROR – assignmentData invalid or null');
      throw Exception('Invalid assignment data');
    }

    if (assignmentData.assignmentType == 'subordinateunit') {
  // hierarchy / subordinate unit path
  final headUid =
      assignmentData.nodeToHeadUserMap[assignmentData.selectedNodeId];
  debugPrint(
      'TASK_CREATE: path=subordinateunit, headUid=$headUid, nodeId=${assignmentData.selectedNodeId}');

  await _createSingleTask(
    tasksCol,
    values,
    user.uid,
    now,
    headUid,
    null,
    assignmentData.groupName,
  );
} else if (assignmentData.assignmentType == 'teammember' ||
           assignmentData.assignmentType == 'team_member') {
  // ✅ team member path (both spellings)
  debugPrint(
      'TASK_CREATE: path=team_member, raw selectedUserIds=${assignmentData.selectedUserIds}, lead=${assignmentData.leadMemberId}, group=${assignmentData.groupName}');

  final cleanedUserIds = assignmentData.selectedUserIds
      .where((id) => id != user.uid)
      .toList();

  debugPrint(
      'TASK_CREATE: cleaned selectedUserIds (without self)=$cleanedUserIds');

  if (cleanedUserIds.isEmpty) {
    debugPrint('TASK_CREATE: ERROR – cleanedUserIds is empty');
    throw Exception('You must assign the task to at least one team member');
  }

  await _createTeamMemberTasks(
    tasksCol,
    values,
    user.uid,
    now,
    cleanedUserIds,
    assignmentData.groupName,
    assignmentData.leadMemberId,
  );
} else {
  debugPrint(
      'TASK_CREATE: ERROR – unknown assignmentType=${assignmentData.assignmentType}');
  throw Exception('Unknown assignment type');
}


    debugPrint('TASK_CREATE: SUCCESS – all writes finished');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tasks created successfully'),
        backgroundColor: Colors.cyan,
      ),
    );

    _rendererKey.currentState?.resetForm();
  } catch (e, st) {
    debugPrint('TASK_CREATE: EXCEPTION $e');
    debugPrint('TASK_CREATE: STACKTRACE $st');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to create task: $e'),
        backgroundColor: Colors.redAccent,
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _submitting = false);
      debugPrint('TASK_CREATE: FINISHED (submitting=false)');
    }
  }
}



  // single-assignee path (subordinate unit)
  Future<void> _createSingleTask(
  CollectionReference tasksCol,
  Map<String, dynamic> values,
  String assignerUid,
  DateTime now,
  String? assignedToUserId,
  String? groupId,
  String? groupName,
) async {
  debugPrint(
      'TASK_CREATE_SINGLE: START assignedTo=$assignedToUserId groupId=$groupId groupName=$groupName');

  final data = <String, dynamic>{
    'title': values['title'] ?? '',
    'description': values['description'] ?? '',
    'status': 'PENDING',
    'assignedby': assignerUid,
    if (assignedToUserId != null) 'assignedto': assignedToUserId,
    'created_at': now.toIso8601String(),
    'updatedat': now.toIso8601String(),
    if (groupId != null) 'groupid': groupId,
    if (groupName != null && groupName.isNotEmpty) 'groupname': groupName,
  };

  final customfields = Map<String, dynamic>.from(values)
    ..remove('title')
    ..remove('description')
    ..remove('assignee');

  final renderer = _rendererKey.currentState;
  final due = renderer?.getSelectedDueDate();
  if (due != null) {
    data['duedate'] = due.toIso8601String();
  }

  if (customfields.isNotEmpty) {
    data['customfields'] = customfields;
  }

  debugPrint('TASK_CREATE_SINGLE: data payload = $data');

  final docRef = await tasksCol.add(data);
  debugPrint(
      'TASK_CREATE_SINGLE: Firestore add OK docId=${docRef.id} assignedTo=$assignedToUserId');
}


  // multi-user path (team members) with lead_member
  Future<void> _createTeamMemberTasks(
  CollectionReference tasksCol,
  Map<String, dynamic> values,
  String assignerUid,
  DateTime now,
  List<String> userIds,
  String? groupName,
  String? leadMemberId,
) async {
  debugPrint(
      'TASK_CREATE_GROUP: START users=$userIds groupName=$groupName lead=$leadMemberId');

  String? groupId;

  if (userIds.length == 1) {
    // Single assignee path
    await _createSingleTask(
      tasksCol,
      values,
      assignerUid,
      now,
      userIds.first,
      null,
      groupName,
    );
    debugPrint('TASK_CREATE_GROUP: Delegated to createSingleTask (1 user)');
    return;
  }

  // Multi-user group path
  try {
    if (groupName != null && groupName.trim().isNotEmpty) {
      final groupDoc = await FirebaseFirestore.instance
          .collection('tenants')
          .doc(tenantId)
          .collection('taskgroups')
          .add({
        'name': groupName,
        'createdby': assignerUid,
        'createdat': now.toIso8601String(),
        'membercount': userIds.length,
        'members': userIds,
        'leadmember': leadMemberId,
      });

      groupId = groupDoc.id;
      debugPrint('TASK_CREATE_GROUP: group doc created id=$groupId');
    } else {
      debugPrint('TASK_CREATE_GROUP: WARNING – groupName is null/empty');
    }

    final allAssigneesString = userIds.join(',');
    final data = <String, dynamic>{
      'title': values['title'] ?? '',
      'description': values['description'] ?? '',
      'status': 'PENDING',
      'assignedby': assignerUid,
      'assignedto': allAssigneesString,
      'createdat': now.toIso8601String(),
      'updatedat': now.toIso8601String(),
      'groupid': groupId,
      'groupname': groupName,
      'leadmember': leadMemberId,
    };

    final customfields = Map<String, dynamic>.from(values)
      ..remove('title')
      ..remove('description')
      ..remove('assignee');

    final renderer = _rendererKey.currentState;
    final due = renderer?.getSelectedDueDate();
    if (due != null) {
      data['duedate'] = due.toIso8601String();
    }

    if (customfields.isNotEmpty) {
      data['customfields'] = customfields;
    }

    debugPrint('TASK_CREATE_GROUP: task payload = $data');

    final docRef = await tasksCol.add(data);
    debugPrint(
        'TASK_CREATE_GROUP: Firestore add OK docId=${docRef.id} users=$allAssigneesString lead=$leadMemberId');
  } catch (e, st) {
    debugPrint('TASK_CREATE_GROUP: EXCEPTION $e');
    debugPrint('TASK_CREATE_GROUP: STACKTRACE $st');
    rethrow;
  }
}


  Future<void> _onCreatePressed() async {
    final state = _rendererKey.currentState;
    if (state == null) return;

    final payload = await state.submitExternally();
    if (payload == null) return;

    await _createTaskFromPayload(payload);
  }

  @override
  Widget build(BuildContext context) {
    final loadError = _cachedLoadError;

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Colors.cyanAccent),
        ),
      );
    }

    if (_form == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              loadError == null
                  ? 'Create Task form config not available.'
                  : 'Failed to load form',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (loadError != null) ...[
              const SizedBox(height: 8),
              Text(
                loadError.toString(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_form!.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _form!.description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        Expanded(
          child: TaskFormRenderer(
            key: _rendererKey,
            tenantId: tenantId,
            form: _form!,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: _submitting ? null : _onCreatePressed,
            icon: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.black),
                    ),
                  )
                : const Icon(Icons.add_task_rounded),
            label: Text(_submitting ? 'Creating…' : 'Create Task'),
          ),
        ),
      ],
    );
  }
  
}
