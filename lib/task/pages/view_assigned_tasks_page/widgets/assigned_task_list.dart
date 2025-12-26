// lib/task/pages/view_assigned_tasks_page/widgets/assigned_task_list.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/assigned_task_view_model.dart';
import 'assigned_task_card.dart';

class AssignedTaskList extends StatefulWidget {
  final String tenantId;
  final String currentUserUid;
  final List<AssignedTaskViewModel> tasks;

  const AssignedTaskList({
    super.key,
    required this.tenantId,
    required this.currentUserUid,
    required this.tasks,
  });

  @override
  State<AssignedTaskList> createState() => _AssignedTaskListState();
}

class _AssignedTaskListState extends State<AssignedTaskList> {
  final Map<String, String> _userNameCache = {};

  @override
  void initState() {
    super.initState();
    _prefetchLeadNames();
  }

  Future<void> _prefetchLeadNames() async {
    final leadIds = widget.tasks
        .map((t) => t.leadMemberId)
        .whereType<String>()
        .where((id) => !_userNameCache.containsKey(id))
        .toSet();

    if (leadIds.isEmpty) return;

    try {
      final futures = leadIds.map((uid) async {
        final doc = await FirebaseFirestore.instance
            .collection('tenants')
            .doc(widget.tenantId)
            .collection('users')
            .doc(uid)
            .get();

        if (!doc.exists) {
          _userNameCache[uid] = uid;
          return;
        }

        final data = doc.data();
        final fullName = data?['profiledata']?['fullName'] ??
            data?['fullName'] ??
            uid;
        _userNameCache[uid] = fullName.toString();
      });

      await Future.wait(futures);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error prefetching lead member names: $e');
    }
  }

  String _getLeadName(String? leadUid) {
    if (leadUid == null) return '';
    return _userNameCache[leadUid] ?? leadUid;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.separated(
        itemCount: widget.tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final task = widget.tasks[index];
          final leadName = _getLeadName(task.leadMemberId);
          final isLead = task.leadMemberId == widget.currentUserUid;

          return AssignedTaskCard(
            task: task,
            leadMemberName: leadName,
            isCurrentUserLead: isLead,
          );
        },
      ),
    );
  }
}
