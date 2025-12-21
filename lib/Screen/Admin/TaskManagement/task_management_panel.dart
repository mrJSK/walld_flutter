import 'package:flutter/material.dart';
import 'task_repository.dart';
import 'task_model.dart';
import 'package:walld_flutter/core/app_colors.dart';

class TaskManagementPanel extends StatefulWidget {
  final String tenantId;

  const TaskManagementPanel({super.key, required this.tenantId});

  @override
  State<TaskManagementPanel> createState() => _TaskManagementPanelState();
}

class _TaskManagementPanelState extends State<TaskManagementPanel> {
  final TaskRepository _repo = TaskRepository();
  List<TaskMeta> _tasks = [];
  bool _loading = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final tasks = await _repo.loadAllTasks(widget.tenantId);
      setState(() {
        _tasks = tasks;
        _status = 'Loaded ${tasks.length} tasks';
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Task Management',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'View and manage all tasks in your organization.',
            style: TextStyle(color: AppColors.grey400),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _loading ? null : _reload,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('Reload'),
              ),
              const Spacer(),
              if (_status != null)
                Text(
                  _status!,
                  style: const TextStyle(color: Colors.cyan, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              color: const Color(0xFF111118),
              child: _tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'No tasks found.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _tasks.length,
                      separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return ListTile(
                          leading: _getStatusIcon(task.status),
                          title: Text(
                            task.title,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${task.status} • ${task.priority} • ${task.assigneeName ?? "Unassigned"}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: PopupMenuButton(
                            icon: const Icon(Icons.more_vert, color: Colors.white54),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                            onSelected: (value) async {
                              if (value == 'delete') {
                                await _repo.deleteTask(widget.tenantId, task.id);
                                _reload();
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'COMPLETED':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'IN_PROGRESS':
        return const Icon(Icons.pending, color: Colors.cyan);
      case 'BLOCKED':
        return const Icon(Icons.block, color: Colors.red);
      default:
        return const Icon(Icons.circle_outlined, color: Colors.orange);
    }
  }
}
