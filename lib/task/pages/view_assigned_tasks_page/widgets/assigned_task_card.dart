// lib/task/pages/view_assigned_tasks_page/widgets/assigned_task_card.dart

import 'package:flutter/material.dart';

import '../../../../core/glass_container.dart';
import '../models/assigned_task_view_model.dart';

class AssignedTaskCard extends StatelessWidget {
  final AssignedTaskViewModel task;
  final String leadMemberName;
  final bool isCurrentUserLead;

  const AssignedTaskCard({
    super.key,
    required this.task,
    required this.leadMemberName,
    required this.isCurrentUserLead,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 18,
      opacity: 0.18,
      tint: Colors.black,
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleRow(),
          const SizedBox(height: 4),
          if (task.groupName.isNotEmpty) _buildGroupRow(),
          if (leadMemberName.isNotEmpty) _buildLeadRow(),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 6),
          _buildStatusRow(),
        ],
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            task.title.isEmpty ? '(No title)' : task.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (task.isGroupTask)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purpleAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.purpleAccent.withOpacity(0.8),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.group,
                    size: 14, color: Colors.purpleAccent),
                const SizedBox(width: 4),
                Text(
                  '${task.assigneeCount} members',
                  style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGroupRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        'Group: ${task.groupName}',
        style: const TextStyle(
          color: Colors.purpleAccent,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildLeadRow() {
  // leadMemberName is already the full name (e.g. "Pool Black")
  final label = isCurrentUserLead
      ? 'Lead: You ($leadMemberName)'
      : 'Lead: $leadMemberName';

  return Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.amberAccent,
            fontSize: 12,
          ),
        ),
        if (isCurrentUserLead) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber, width: 0.8),
            ),
            child: const Text(
              'YOU ARE THE LEAD',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}


  Widget _buildStatusRow() {
    return Row(
      children: [
        if (task.priority.isNotEmpty)
          _Chip(
            label: task.priority,
            color: Colors.deepOrangeAccent,
          ),
        const SizedBox(width: 6),
        _Chip(
          label: task.status,
          color: task.status == 'COMPLETED'
              ? Colors.greenAccent
              : Colors.cyanAccent,
        ),
        const Spacer(),
        if (task.dueDate != null)
          Text(
            'Due: '
            '${task.dueDate!.year}-${task.dueDate!.month.toString().padLeft(2, '0')}-'
            '${task.dueDate!.day.toString().padLeft(2, '0')} '
            '${task.dueDate!.hour.toString().padLeft(2, '0')}:'
            '${task.dueDate!.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.8), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
