
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/glass_container.dart';
import '../core/wallpaper_service.dart';
import '../workspace/workspace_controller.dart';
// Removed unused WorkspaceSwitcher import
import 'task_tabs_manifest.dart';
import 'widgets/task_side_panel.dart';

class TaskWorkspace extends StatefulWidget {
  final WorkspaceController workspaceController;

  const TaskWorkspace({
    super.key,
    required this.workspaceController,
  });

  @override
  State<TaskWorkspace> createState() => TaskWorkspaceState();
}

class TaskWorkspaceState extends State<TaskWorkspace> {
  String tabId = taskTabs.first.id;

  double glassBlur = 18;
  double glassOpacity = 0.16;

  @override
  void initState() {
    super.initState();
    _loadGlassSettings();
    // Listen to wallpaper service changes
    WallpaperService.instance.addListener(_onWallpaperChanged);
  }

  @override
  void dispose() {
    WallpaperService.instance.removeListener(_onWallpaperChanged);
    super.dispose();
  }

  void _onWallpaperChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadGlassSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      glassBlur = prefs.getDouble('task_glass_blur') ?? 18.0;
      glassOpacity = prefs.getDouble('task_glass_opacity') ?? 0.16;
    });
  }

  

  @override
  Widget build(BuildContext context) {
    final tab = taskTabs.firstWhere((x) => x.id == tabId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        
        child: SafeArea(
          // Adjusted top padding slightly as the internal header is gone
          // (Parent layout with UniversalTopBar should handle top spacing)
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 64, 18, 14),
            child: Column(
              children: [
                // REMOVED: Internal Top Bar & Spacer

                // MAIN TASK LAYOUT WITH SLIDE/FADE
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final offsetAnimation = Tween<Offset>(
                        begin: const Offset(-0.04, 0),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: Row(
                      key: ValueKey('task-layout-$tabId'),
                      children: [
                        SizedBox(
                          width: 240,
                          child: TaskSidePanel(
                            selectedTabId: tabId,
                            onSelect: (id) {
                              setState(() {
                                tabId = id;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassContainer(
                            blur: glassBlur,
                            opacity: glassOpacity,
                            tint: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            padding: const EdgeInsets.fromLTRB(
                              18,
                              16,
                              18,
                              16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tab.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: tab.builder(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  
}