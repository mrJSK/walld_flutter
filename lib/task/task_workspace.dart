import 'dart:io';

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

  Future<void> _saveGlassSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('task_glass_blur', glassBlur);
    await prefs.setDouble('task_glass_opacity', glassOpacity);
  }

  @override
  Widget build(BuildContext context) {
    final tab = taskTabs.firstWhere((x) => x.id == tabId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: WallpaperService.instance.backgroundDecoration,
        child: SafeArea(
          // Adjusted top padding slightly as the internal header is gone
          // (Parent layout with UniversalTopBar should handle top spacing)
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
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

  // NOTE: These dialog methods are kept in case you wire them up
  // to the UniversalTopBar in a parent widget later.

  Future<void> _openWallpaperSettingsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111118),
          title: const Text(
            'Wallpaper settings',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: Colors.cyan),
                title: const Text(
                  'Change wallpaper',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await WallpaperService.instance.pickWallpaper();
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.orange),
                title: const Text(
                  'Reset to default',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await WallpaperService.instance.resetWallpaper();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openGlassSettingsDialog() async {
    double tempBlur = glassBlur;
    double tempOpacity = glassOpacity;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF111118),
              title: const Text(
                'Glass settings',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Blur',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    Slider(
                      value: tempBlur,
                      min: 0,
                      max: 40,
                      divisions: 40,
                      label: tempBlur.toStringAsFixed(0),
                      onChanged: (v) {
                        setDialogState(() {
                          tempBlur = v;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Opacity',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    Slider(
                      value: tempOpacity,
                      min: 0.02,
                      max: 0.40,
                      divisions: 38,
                      label: tempOpacity.toStringAsFixed(2),
                      onChanged: (v) {
                        setDialogState(() {
                          tempOpacity = v;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      glassBlur = tempBlur;
                      glassOpacity = tempOpacity;
                    });
                    _saveGlassSettings();
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}