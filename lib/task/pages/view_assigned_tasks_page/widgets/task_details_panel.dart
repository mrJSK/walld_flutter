import 'package:flutter/material.dart';
import '../models/assigned_task_view_model.dart';

class TaskDetailsPanel extends StatelessWidget {
  final AssignedTaskViewModel task;

  const TaskDetailsPanel({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Task Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          if (task.description.isNotEmpty) ...[
            const Text(
              'Description',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              task.description,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
          ],

          // Group Name
          if (task.groupName.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.label_outline,
              label: 'Group',
              value: task.groupName,
            ),
            const SizedBox(height: 12),
          ],

          // Status & Priority
          Row(
            children: [
              _buildChip('Status', task.status, Colors.cyanAccent),
              const SizedBox(width: 8),
              if (task.priority.isNotEmpty)
                _buildChip('Priority', task.priority, Colors.deepOrangeAccent),
            ],
          ),
          const SizedBox(height: 16),

          // Assignees
          _buildInfoRow(
            icon: Icons.people,
            label: 'Team Members',
            value: '${task.assigneeCount} member(s)',
          ),
          const SizedBox(height: 12),

          // Lead info
          if (task.hasLead) ...[
            _buildInfoRow(
              icon: Icons.star,
              label: 'Lead Member',
              value: task.leadMemberId ?? 'Not assigned',
              valueColor: Colors.amberAccent,
            ),
            const SizedBox(height: 12),
          ],

          // Due date
          if (task.dueDate != null) ...[
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Due Date',
              value: _formatDueDate(task.dueDate!),
              valueColor: _getDueDateColor(task.dueDate!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.white54,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.8)),
      ),
      child: Text(
        '$label: ${value.toUpperCase()}',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      return Colors.redAccent;
    } else if (difference.inDays <= 1) {
      return Colors.orangeAccent;
    } else if (difference.inDays <= 3) {
      return Colors.yellowAccent;
    } else {
      return Colors.white70;
    }
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.isNegative) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} (Overdue)';
    } else if (difference.inDays == 0) {
      return 'Today at ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${_formatTime(date)}';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
