import 'package:flutter/material.dart';

import '../dynamic_screen/dashboardpanel.dart';
import '../task/task_workspace.dart';
import 'workspace_controller.dart';
import 'workspace_ids.dart';

class WorkspaceShell extends StatefulWidget {
  final WorkspaceController workspaceController;

  const WorkspaceShell({
    super.key,
    required this.workspaceController,
  });

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  @override
  void initState() {
    super.initState();
    // Listen to the controller directly (No Provider needed)
    widget.workspaceController.addListener(_onWorkspaceChanged);
  }

  @override
  void dispose() {
    widget.workspaceController.removeListener(_onWorkspaceChanged);
    super.dispose();
  }

  void _onWorkspaceChanged() {
    // Rebuild the shell when the workspace changes
    setState(() {});
  }

  /// Helper to map the current ID to an integer index for IndexedStack
  int _getCurrentIndex() {
    final current = widget.workspaceController.current;
    
    // Check against IDs defined in lib/workspace/workspace_ids.dart
    if (current == WorkspaceIds.dashboard) {
      return 0;
    } else if (current == WorkspaceIds.task) {
      return 1;
    }
    
    // Default to dashboard if unknown
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Important for wallpaper visibility
      body: IndexedStack(
        index: _getCurrentIndex(),
        children: [
          // Index 0: Dashboard
          // Wrapped in a Key so Flutter knows it's the same widget
          DashboardPanel(
            key: const PageStorageKey('dashboard_panel'),
            workspaceController: widget.workspaceController,
          ),

          // Index 1: Task Workspace
          // Wrapped in a Key
          TaskWorkspace(
            key: const PageStorageKey('task_workspace'),
            workspaceController: widget.workspaceController,
          ),
        ],
      ),
    );
  }
}