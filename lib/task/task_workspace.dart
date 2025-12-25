import 'package:flutter/material.dart';

import '../core/wallpaper_service.dart';
import '../core/glass_container.dart';
import '../workspace/workspace_controller.dart';
import 'task_tabs_manifest.dart';
import 'widgets/task_side_panel.dart';

class TaskWorkspace extends StatefulWidget {
  const TaskWorkspace({
    super.key,
    required this.workspaceController,
  });

  final WorkspaceController workspaceController;

  @override
  State<TaskWorkspace> createState() => _TaskWorkspaceState();
}

class _TaskWorkspaceState extends State<TaskWorkspace> {
  String tabId = taskTabs.first.id;

  @override
  Widget build(BuildContext context) {
    final wallpaper = WallpaperService.instance;

    // React to global wallpaper/glass changes so both side panel and
    // main content update when sliders move.
    return AnimatedBuilder(
      animation: wallpaper,
      builder: (context, _) {
        final currentTab = taskTabs.firstWhere(
          (t) => t.id == tabId,
          orElse: () => taskTabs.first,
        );

        final double glassBlur = wallpaper.globalGlassBlur;
        final double glassOpacity = wallpaper.globalGlassOpacity;

        return Padding(
          // Top padding to clear the UniversalTopBar drawn by WorkspaceShell.
          padding: const EdgeInsets.fromLTRB(18, 70, 18, 18),
          child: Row(
            children: [
              // LEFT: Tab list + info
              SizedBox(
                width: 240,
                child: TaskSidePanel(
                  selectedTabId: tabId,
                  onSelect: (id) => setState(() => tabId = id),
                ),
              ),
              const SizedBox(width: 12),

              // RIGHT: Main glass content area for current tab
              Expanded(
                child: GlassContainer(
                  blur: glassBlur,
                  opacity: glassOpacity,
                  tint: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  padding: const EdgeInsets.all(14),
                  // When interacting inside the page, keep quality auto.
                  blurMode: GlassBlurMode.auto,
                  qualityMode: GlassQualityMode.auto,
                  isInteracting: false,
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
