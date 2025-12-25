import 'package:flutter/material.dart';

import '../core/wallpaper_service.dart';
import '../core/glass_container.dart';
import '../workspace/workspace_controller.dart';
import 'task_tabs_manifest.dart';
import 'widgets/task_side_panel.dart';

class TaskWorkspace extends StatefulWidget {
  const TaskWorkspace({super.key, required this.workspaceController});

  final WorkspaceController workspaceController;

  @override
  State<TaskWorkspace> createState() => _TaskWorkspaceState();
}

class _TaskWorkspaceState extends State<TaskWorkspace> {
  String tabId = taskTabs.first.id;

  @override
  Widget build(BuildContext context) {
    final wallpaper = WallpaperService.instance;

    // Only react to global wallpaper/glass changes; the outer shell already
    // draws the wallpaper and top bar.
    return AnimatedBuilder(
      animation: wallpaper,
      builder: (context, _) {
        final currentTab = taskTabs.firstWhere(
          (t) => t.id == tabId,
          orElse: () => taskTabs.first,
        );

        final glassBlur = wallpaper.globalGlassBlur;
        final glassOpacity = wallpaper.globalGlassOpacity;

        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 70, 18, 18),
          // Top padding to clear the global UniversalTopBar that WorkspaceShell draws.
          child: Row(
            children: [
              SizedBox(
                width: 240,
                child: TaskSidePanel(
                  selectedTabId: tabId,
                  onSelect: (id) => setState(() => tabId = id),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassContainer(
                  blur: glassBlur,
                  opacity: glassOpacity,
                  tint: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  padding: const EdgeInsets.all(14),
                  child: currentTab.builder(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
