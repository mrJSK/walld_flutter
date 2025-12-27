import 'package:flutter/material.dart';
import '../models/assigned_task_view_model.dart';
import '../../../utils/user_helper.dart';

class TaskDetailsPanel extends StatefulWidget {
  final AssignedTaskViewModel task;
  final String tenantId;

  const TaskDetailsPanel({
    super.key,
    required this.task,
    required this.tenantId,
  });

  @override
  State<TaskDetailsPanel> createState() => _TaskDetailsPanelState();
}

class _TaskDetailsPanelState extends State<TaskDetailsPanel> {
  String? leadMemberName;
  bool isLoadingLeadName = false;

  @override
  void initState() {
    super.initState();
    _fetchLeadMemberName();
  }

  Future<void> _fetchLeadMemberName() async {
    if (widget.task.hasLead && widget.task.leadMemberId != null) {
      setState(() => isLoadingLeadName = true);
      
      final name = await UserHelper.getUserDisplayName(
        tenantId: widget.tenantId,
        userId: widget.task.leadMemberId!,
      );
      
      if (mounted) {
        setState(() {
          leadMemberName = name;
          isLoadingLeadName = false;
        });
      }
    }
  }

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
          if (widget.task.description.isNotEmpty) ...[
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
              widget.task.description,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
          ],

          // Group Name
          if (widget.task.groupName.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.label_outline,
              label: 'Group',
              value: widget.task.groupName,
            ),
            const SizedBox(height: 12),
          ],

          // Status & Priority
          Row(
            children: [
              _buildChip('Status', widget.task.status, Colors.cyanAccent),
              const SizedBox(width: 8),
              if (widget.task.priority.isNotEmpty)
                _buildChip('Priority', widget.task.priority, Colors.deepOrangeAccent),
            ],
          ),
          const SizedBox(height: 16),

          // Assignees
          _buildInfoRow(
            icon: Icons.people,
            label: 'Team Members',
            value: '${widget.task.assigneeCount} member(s)',
          ),
          const SizedBox(height: 12),

          // Lead Member with name
          if (widget.task.hasLead) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.star,
                  size: 18,
                  color: Colors.amberAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lead Member',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      isLoadingLeadName
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.amberAccent),
                              ),
                            )
                          : Text(
                              leadMemberName ?? widget.task.leadMemberId ?? 'Not assigned',
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Due date
          if (widget.task.dueDate != null) ...[
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Due Date',
              value: _formatDueDate(widget.task.dueDate!),
              valueColor: _getDueDateColor(widget.task.dueDate!),
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
