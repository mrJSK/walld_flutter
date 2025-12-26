import 'package:flutter/material.dart';
import '../core/wallpaper_service.dart'; // NEW IMPORT
import 'pages/create_task_page/create_task_page.dart';
import 'pages/view_all_tasks_page.dart';
import 'pages/view_assigned_tasks_page.dart';
import 'pages/complete_task_page.dart';

class TaskTabIds {
  static const create = 'create';
  static const viewAll = 'viewall';
  static const viewAssigned = 'viewassigned';
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

final List<TaskTabDef> taskTabs = [
  TaskTabDef(
    id: TaskTabIds.create,
    title: 'Create',
    icon: Icons.add_task_rounded,
    builder: (context) => const CreateTaskPage(),
  ),
  TaskTabDef(
    id: TaskTabIds.viewAssigned,
    title: 'Assigned',
    icon: Icons.assignment_ind_rounded,
    builder: (context) => const ViewAssignedTasksPage(),
  ),
  TaskTabDef(
    id: TaskTabIds.viewAll,
    title: 'All',
    icon: Icons.view_list_rounded,
    builder: (context) => const ViewAllTasksPage(),
  ),
  TaskTabDef(
    id: TaskTabIds.complete,
    title: 'Complete',
    icon: Icons.check_circle_rounded,
    builder: (context) => const CompleteTaskPage(),
  ),
];

/// UPDATED: Now uses WallpaperService instead of local gradient
BoxDecoration backgroundDecoration() {
  return WallpaperService.instance.backgroundDecoration;
}