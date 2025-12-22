// lib/dynamic_screen/widget_factory.dart
import 'package:flutter/material.dart';
import 'widgets.dart';
import 'widgets/login_widget.dart';

class WidgetFactory {
  static Widget createWidget(String widgetId) {
    switch (widgetId) {
      case 'login':
        return const LoginWidget();
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
