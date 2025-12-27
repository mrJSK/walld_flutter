import 'package:flutter/material.dart';
import '../models/created_task_view_model.dart';

class ManagerTaskDetailsPanel extends StatelessWidget {
  final CreatedTaskViewModel task;

  const ManagerTaskDetailsPanel({
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
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              task.description,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
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
          Text(
            'Assigned to ${task.assigneeCount} member(s)',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          // Lead info
          if (task.hasLead)
            Text(
              'Lead: ${task.leadMemberId}',
              style: const TextStyle(color: Colors.amberAccent),
            ),
          // Due date
          if (task.dueDate != null) ...[
            const SizedBox(height: 16),
            Text(
              'Due: ${task.dueDate}',
              style: const TextStyle(color: Colors.white60),
            ),
          ],
        ],
      ),
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
        '$label: $value',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
