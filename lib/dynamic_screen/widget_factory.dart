import 'package:flutter/material.dart';
import 'widgets.dart';

class WidgetFactory {
  static Widget createWidget(String widgetId) {
    switch (widgetId) {
      case 'create_task':
        return const CreateTaskWidget();
      case 'view_assigned_tasks':
        return const ViewAssignedTasksWidget();
      case 'complete_task':
        return const CompleteTaskWidget();
      case 'view_all_tasks':
        return const ViewAllTasksWidget();
      default:
        return const Text('Widget not found');
    }
  }
}
