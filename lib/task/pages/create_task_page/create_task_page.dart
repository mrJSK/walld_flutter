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

  Future<void> _createTaskFromPayload(
    Map<String, dynamic> values,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
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

      final renderer = _rendererKey.currentState;
      if (renderer == null) {
        throw Exception('Form renderer not available');
      }

      final assignmentData = renderer.getAssignmentData();
      if (assignmentData == null || !assignmentData.isValid) {
        throw Exception('Invalid assignment data');
      }

      if (assignmentData.assignmentType == 'subordinate_unit') {
        final headUid =
            assignmentData.nodeToHeadUserMap[assignmentData.selectedNodeId];
        await _createSingleTask(
          tasksCol,
          values,
          user.uid,
          now,
          headUid,
          null,
        );
      } else if (assignmentData.assignmentType == 'team_member') {
        // ✅ pass leadMemberId into multi-user creation
        await _createTeamMemberTasks(
          tasksCol,
          values,
          user.uid,
          now,
          assignmentData.selectedUserIds,
          assignmentData.groupName,
          assignmentData.leadMemberId, // PASS lead member ID
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task(s) created successfully'),
          backgroundColor: Colors.cyan,
        ),
      );
      _rendererKey.currentState?.resetForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create task: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // single-assignee path (subordinate unit)
  Future<void> _createSingleTask(
    CollectionReference tasksCol,
    Map<String, dynamic> values,
    String assignerUid,
    DateTime now,
    String? assignedToUserId,
    String? groupId, {
    String? groupName,
  }) async {
    final data = {
      'title': values['title'] ?? '',
      'description': values['description'] ?? '',
      'status': 'PENDING',
      'assigned_by': assignerUid,
      if (assignedToUserId != null) 'assigned_to': assignedToUserId,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'group_id': groupId,
      if (groupName != null && groupName.isNotEmpty) 'group_name': groupName,
      'custom_fields': Map<String, dynamic>.from(values),
    };

    data['custom_fields'].remove('title');
    data['custom_fields'].remove('description');
    data['custom_fields'].remove('assignee');

    final renderer = _rendererKey.currentState;
    final due = renderer?.getSelectedDueDate();
    if (due != null) {
      data['due_date'] = due.toIso8601String();
    }

    final docRef = await tasksCol.add(data);
    debugPrint('✅ Task created for user: $assignedToUserId (doc: ${docRef.id})');
  }

  // multi-user path (team members) with lead_member
  Future<void> _createTeamMemberTasks(
    CollectionReference tasksCol,
    Map<String, dynamic> values,
    String assignerUid,
    DateTime now,
    List<String> userIds,
    String? groupName,
    String? leadMemberId, // NEW PARAMETER
  ) async {
    String? groupId;

    if (userIds.length > 1 &&
        groupName != null &&
        groupName.isNotEmpty) {
      final groupDoc = await FirebaseFirestore.instance
          .collection('tenants')
          .doc(tenantId)
          .collection('task_groups')
          .add({
        'name': groupName,
        'created_by': assignerUid,
        'created_at': now.toIso8601String(),
        'member_count': userIds.length,
        'members': userIds,
        'lead_member': leadMemberId, // also store in group doc
      });
      groupId = groupDoc.id;
      debugPrint('✅ Task group created: $groupName (id: $groupId)');
    }

    final allAssigneesString = userIds.join(',');

    final data = {
      'title': values['title'] ?? '',
      'description': values['description'] ?? '',
      'status': 'PENDING',
      'assigned_by': assignerUid,
      'assigned_to': allAssigneesString,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'group_id': groupId,
      'group_name': groupName,
      'lead_member': leadMemberId, // NEW FIELD on task
      'custom_fields': Map<String, dynamic>.from(values),
    };

    data['custom_fields'].remove('title');
    data['custom_fields'].remove('description');
    data['custom_fields'].remove('assignee');

    final renderer = _rendererKey.currentState;
    final due = renderer?.getSelectedDueDate();
    if (due != null) {
      data['due_date'] = due.toIso8601String();
    }

    final docRef = await tasksCol.add(data);
    debugPrint(
      '✅ Group task created for users: $allAssigneesString '
      '(lead: $leadMemberId, doc: ${docRef.id})',
    );
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
