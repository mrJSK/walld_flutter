import 'package:flutter/material.dart';
import 'pages/create_task_page.dart';
import 'pages/view_all_tasks_page.dart';
import 'pages/view_assigned_tasks_page.dart';
import 'pages/complete_task_page.dart';

class TaskTabIds {
  static const create = 'create';
  static const viewAll = 'view_all';
  static const viewAssigned = 'view_assigned';
  static const complete = 'complete';
}

class TaskTabDef {
  final String id;
  final String title;
  final IconData icon;
  final WidgetBuilder builder;

  TaskTabDef({
    required this.id,
    required this.title,
    required this.icon,
    required this.builder,
  });
}

// IMPORTANT: NOT const
final List<TaskTabDef> taskTabs = <TaskTabDef>[
  TaskTabDef(
    id: TaskTabIds.create,
    title: 'Create',
    icon: Icons.add_task_rounded,
    builder: (_) => const CreateTaskPage(),
  ),
  TaskTabDef(
    id: TaskTabIds.viewAssigned,
    title: 'Assigned',
    icon: Icons.assignment_ind_rounded,
    builder: (_) => const ViewAssignedTasksPage(),
  ),
  TaskTabDef(
    id: TaskTabIds.viewAll,
    title: 'All',
    icon: Icons.view_list_rounded,
    builder: (_) => const ViewAllTasksPage(),
  ),
  TaskTabDef(
    id: TaskTabIds.complete,
    title: 'Complete',
    icon: Icons.check_circle_rounded,
    builder: (_) => const CompleteTaskPage(),
  ),
];
