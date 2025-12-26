import 'package:flutter/material.dart';

import '../../../../core/glass_container.dart';
import '../models/assigned_task_view_model.dart';
import 'lead_badge.dart';

class AssignedTaskCard extends StatelessWidget {
  final AssignedTaskViewModel task;
  final bool isSelected;
  final String? leadMemberName;
  final bool isCurrentUserLead;

  const AssignedTaskCard({
    super.key,
    required this.task,
    required this.isSelected,
    this.leadMemberName,
    required this.isCurrentUserLead, 
  });

  @override
  Widget build(BuildContext context) {
    final bgOpacity = isSelected ? 0.22 : 0.18;
    final borderColor =
        isSelected ? Colors.cyanAccent.withOpacity(0.8) : Colors.white12;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: isSelected ? 1.2 : 0.6),
      ),
      child: GlassContainer(
        blur: 18,
        opacity: bgOpacity,
        tint: Colors.black,
        borderRadius: BorderRadius.circular(18),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleRow(),
            const SizedBox(height: 4),
            if (task.groupName.isNotEmpty) _buildGroupRow(),
            _buildLeadRow(),
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
    final name = (leadMemberName != null && leadMemberName!.isNotEmpty)
        ? leadMemberName
        : task.leadMemberId;

    String leadText;
    if (name == null || name.isEmpty) {
      leadText = 'Lead: —';
    } else if (isCurrentUserLead) {
      leadText = 'Lead: You ($name)';  // ← Show "You (Full Name)"
    } else {
      leadText = 'Lead: $name';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        leadText,
        style: const TextStyle(
          color: Colors.amberAccent,
          fontSize: 12,
        ),
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
