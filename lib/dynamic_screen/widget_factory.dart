import 'package:flutter/material.dart';
import 'widgets/login_widget.dart';
import 'widgets/create_task_widget.dart';
import 'widgets/view_assigned_tasks_widget.dart';
import 'widgets/view_all_tasks_widget.dart';
import 'widgets/complete_task_widget.dart';

class DynamicWidgetFactory {
  static Widget create(String widgetId) {
    // 1. Normalize the ID: remove underscores and make lowercase
    // This ensures 'create_task' and 'createtask' both work.
    final normalizedId = widgetId.toLowerCase().replaceAll('_', '');

    switch (normalizedId) {
      case 'login':
        return const LoginWidget();
        
      case 'createtask':
        return const CreateTaskWidget();
        
      case 'viewassignedtasks':
        return const ViewAssignedTasksWidget();
        
      case 'viewalltasks':
        return const ViewAllTasksWidget();
        
      case 'completetask':
        return const CompleteTaskWidget();

      default:
        // This handles the "Widget Not Found" error gracefully
        return _buildNotFoundWidget(widgetId);
    }
  }

  static Widget _buildNotFoundWidget(String id) {
    return Container(
      color: Colors.red.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(
              'Unknown Widget\n"$id"',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}