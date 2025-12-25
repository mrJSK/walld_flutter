import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/glass_container.dart';
import '../core/wallpaper_service.dart';
import '../workspace/universal_top_bar.dart';
import '../workspace/workspace_controller.dart';
import 'task_tabs_manifest.dart';
import 'widgets/task_side_panel.dart';

class TaskWorkspace extends StatefulWidget {
  final WorkspaceController workspaceController;

  const TaskWorkspace({
    super.key,
    required this.workspaceController,
  });

  @override
  State<TaskWorkspace> createState() => _TaskWorkspaceState();
}

class _TaskWorkspaceState extends State<TaskWorkspace> {
  String tabId = taskTabs.first.id;

  double glassBlur = 18;
  double glassOpacity = 0.16;

  @override
  void initState() {
    super.initState();
    _loadGlassSettings();
  }

  Future<void> _loadGlassSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      glassBlur = prefs.getDouble('task_glass_blur') ?? 18;
      glassOpacity = prefs.getDouble('task_glass_opacity') ?? 0.16;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTab =
        taskTabs.firstWhere((t) => t.id == tabId, orElse: () => taskTabs.first);

    return Stack(
      children: [
        // Wallpaper background (repaints only this layer)
        Positioned.fill(
          child: AnimatedBuilder(
            animation: WallpaperService.instance,
            builder: (_, __) => DecoratedBox(
              decoration: WallpaperService.instance.backgroundDecoration,
            ),
          ),
        ),

        Column(
          children: [
            UniversalTopBar(
              workspaceController: widget.workspaceController,
              onWallpaperSettings: () async {
                await WallpaperService.instance.pickWallpaper();
              },
              onGlassSettings: () {
                // Keep your existing glass sheet if you have one
              },
              onSignOut: () async {
                // Keep your existing signOut if you have one
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
  }
}
