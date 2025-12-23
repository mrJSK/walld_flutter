// lib/workspace/workspace_shell.dart
import 'package:flutter/material.dart';

import '../dynamic_screen/dashboardpanel.dart';
import '../task/task_workspace.dart';
import 'workspace_controller.dart';
import 'workspace_ids.dart';

class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({super.key});

  @override
  State<WorkspaceShell> createState() => WorkspaceShellState();
}

class WorkspaceShellState extends State<WorkspaceShell>
    with SingleTickerProviderStateMixin {
  late final WorkspaceController controller;

  // Current workspace id: dashboard / task
  String current = WorkspaceIds.dashboard;

  @override
  void initState() {
    super.initState();
    controller = WorkspaceController();
    controller.addListener(_onWorkspaceChange);
  }

  @override
  void dispose() {
    controller.removeListener(_onWorkspaceChange);
    controller.dispose();
    super.dispose();
  }

  void _onWorkspaceChange() {
    final target = controller.current;
    if (target == current) return;

    setState(() {
      current = target;
    });
  }

  Widget _buildWorkspace(String id) {
    switch (id) {
      case WorkspaceIds.dashboard:
        return DashboardPanel(workspaceController: controller);
      case WorkspaceIds.task:
        return TaskWorkspace(workspaceController: controller);
      default:
        return DashboardPanel(workspaceController: controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    // No heavy slide here; just show current workspace.
    // Use small animations inside each workspace (AnimatedSwitcher, etc.)
    // to keep tab switching smooth.
    return _buildWorkspace(current);
  }
}
