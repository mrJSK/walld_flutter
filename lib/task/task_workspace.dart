// lib/task/task_workspace.dart
import 'package:flutter/material.dart';

import '../core/wallpaper_service.dart';
import '../core/glass_container.dart';
import '../workspace/universal_top_bar.dart';
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

    return AnimatedBuilder(
      animation: wallpaper,
      builder: (context, _) {
        final currentTab = taskTabs.firstWhere(
          (t) => t.id == tabId,
          orElse: () => taskTabs.first,
        );

        // Glass settings come only from WallpaperService and are applied
        // to foreground widgets (side panel + main card), not the wallpaper.
        //final glassBlur = wallpaper.globalGlassBlur;
        final glassOpacity = wallpaper.globalGlassOpacity;
        final glassBlur = 2000.0; 

        return Stack(
          children: [
            // Plain wallpaper background (no per-widget blur here).
            Positioned.fill(
              child: DecoratedBox(
                decoration: wallpaper.backgroundDecoration,
              ),
            ),

            // Foreground UI with glass widgets.
            Column(
              children: [
                UniversalTopBar(
                  workspaceController: widget.workspaceController,
                  onWallpaperSettings: () async {
                    await wallpaper.pickWallpaper();
                  },
                  onGlassSettings: () {
                    // open your shared glass settings UI here
                  },
                  onSignOut: () async {
                    // your sign-out logic
                  },
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
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
                            // Apply blur/opacity only to this card.
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
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
