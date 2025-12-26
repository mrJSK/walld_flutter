import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/glass_container.dart';
import '../models/assigned_task_view_model.dart';
import 'lead_badge.dart';

class TaskDetailsPanel extends StatefulWidget {
  final AssignedTaskViewModel task;
  final String currentUserUid;
  final VoidCallback onAskDoubt;
  final VoidCallback onSubmitProgress;

  const TaskDetailsPanel({
    super.key,
    required this.task,
    required this.currentUserUid,
    required this.onAskDoubt,
    required this.onSubmitProgress,
  });

  @override
  State<TaskDetailsPanel> createState() => _TaskDetailsPanelState();
}

class _TaskDetailsPanelState extends State<TaskDetailsPanel> {
  static const String tenantId = 'default_tenant';

  String? _assignedByName;
  List<String>? _assignedToNames;
  String? _leadMemberName;
  bool _loadingNames = true;

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  @override
  void didUpdateWidget(covariant TaskDetailsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.docId != widget.task.docId) {
      _loadNames();
    }
  }

  Future<void> _loadNames() async {
    setState(() {
      _loadingNames = true;
      _assignedByName = null;
      _assignedToNames = null;
      _leadMemberName = null;
    });

    try {
      final assignedByUid = widget.task.assignedByUid;
      final leadUid = widget.task.leadMemberId;
      final assigneeUids = widget.task.assignedToUids;

      final futures = <Future<void>>[];

      if (assignedByUid != null) {
        futures.add(_loadSingleUserName(assignedByUid)
            .then((name) => _assignedByName = name));
      }

      if (leadUid != null) {
        futures.add(_loadSingleUserName(leadUid)
            .then((name) => _leadMemberName = name));
      }

      if (assigneeUids.isNotEmpty) {
        futures.add(_loadMultipleUserNames(assigneeUids)
            .then((names) => _assignedToNames = names));
      }

      await Future.wait(futures);
    } catch (e) {
      debugPrint('Error loading names for task details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingNames = false;
        });
      }
    }
  }

  Future<String> _loadSingleUserName(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('tenants')
          .doc(tenantId)
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) return uid;

      final data = doc.data();
      final fullName = data?['profiledata']?['fullName'] ??
          data?['fullName'] ??
          uid;
      return fullName.toString();
    } catch (_) {
      return uid;
    }
  }

  Future<List<String>> _loadMultipleUserNames(List<String> uids) async {
    final results = <String>[];
    for (final uid in uids) {
      results.add(await _loadSingleUserName(uid));
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isCurrentUserLead =
        task.leadMemberId != null && task.leadMemberId == widget.currentUserUid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: title + lead badge (if current user is lead)
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                task.title.isEmpty ? '(No title)' : task.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            LeadBadge(isCurrentUserLead: isCurrentUserLead),
          ],
        ),

        const SizedBox(height: 8),

        if (task.groupName.isNotEmpty)
          Text(
            'Group: ${task.groupName}',
            style: const TextStyle(
              color: Colors.purpleAccent,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),

        const SizedBox(height: 4),

        if (task.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              task.description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),

        const Divider(color: Colors.white10, height: 16),

        if (_loadingNames)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.cyanAccent),
              ),
            ),
          )
        else
          _buildMetaRows(isCurrentUserLead),

        const Spacer(),

        _buildFooterButtons(isCurrentUserLead),
      ],
    );
  }

  Widget _buildMetaRows(bool isCurrentUserLead) {
    final task = widget.task;

    final assignedBy = _assignedByName ?? task.assignedByUid ?? 'Unknown';
    final assignees = _assignedToNames ?? task.assignedToUids;
    final lead = _leadMemberName ?? task.leadMemberId ?? '—';

    final leadLabel = isCurrentUserLead ? 'You ($lead)' : lead;

    final due = task.dueDate;
    final dueText = due == null
        ? '—'
        : '${_monthName(due.month)} ${due.day}, ${due.year} '
          'at ${due.hour.toString().padLeft(2, '0')}:${due.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _metaRow('Assigned by', assignedBy),
        const SizedBox(height: 4),
        _metaRow('Assigned to', assignees.isEmpty ? '—' : assignees.join(', ')),
        const SizedBox(height: 4),
        _metaRow('Lead', leadLabel),
        const SizedBox(height: 4),
        _metaRow('Status', task.status),
        const SizedBox(height: 4),
        _metaRow('Priority', task.priority.isEmpty ? '—' : task.priority),
        const SizedBox(height: 4),
        _metaRow('Due date', dueText),
      ],
    );
  }

  Widget _metaRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterButtons(bool isCurrentUserLead) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onAskDoubt,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.cyanAccent),
              foregroundColor: Colors.cyanAccent,
              padding: const EdgeInsets.symmetric(vertical: 10),
              textStyle: const TextStyle(fontSize: 12),
            ),
            icon: const Icon(Icons.help_outline_rounded, size: 16),
            label: const Text('Ask Doubt'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            onPressed: isCurrentUserLead ? widget.onSubmitProgress : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              backgroundColor:
                  isCurrentUserLead ? Colors.greenAccent : Colors.green.shade200,
              foregroundColor: Colors.black,
              textStyle: const TextStyle(fontSize: 12),
            ),
            icon: const Icon(Icons.task_alt_rounded, size: 16),
            label: const Text('Submit Progress'),
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (month < 1 || month > 12) return month.toString();
    return names[month - 1];
  }
}
