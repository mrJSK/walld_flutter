// lib/task/task_workspace.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/glass_container.dart';
import '../core/wallpaper_service.dart';

import 'pages/complete_task_page.dart';
import 'pages/create_task_page.dart';
import 'pages/view_all_tasks_page.dart';
import 'pages/view_assigned_tasks_page.dart';

import 'task_tabs_manifest.dart';
import 'widgets/task_side_panel.dart';

class TaskWorkspace extends StatefulWidget {
  const TaskWorkspace({super.key});

  @override
  State<TaskWorkspace> createState() => TaskWorkspaceState();
}

class TaskWorkspaceState extends State<TaskWorkspace> {
  // Match TaskTabIds from task_tabs_manifest.dart
  String selectedTabId = TaskTabIds.viewAssigned;

  TaskTabDef get _currentTab =>
      taskTabs.firstWhere((t) => t.id == selectedTabId, orElse: () => taskTabs.first);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: WallpaperService.instance,
      builder: (context, _) {
        final double glassBlur = WallpaperService.instance.globalGlassBlur;
        final double glassOpacity = WallpaperService.instance.globalGlassOpacity;

        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 70, 18, 18),
          child: Row(
            children: [
              // LEFT: side panel – API fixed to match TaskSidePanel
              SizedBox(
                width: 240,
                child: TaskSidePanel(
                  selectedTabId: selectedTabId,
                  onSelect: (id) {
                    setState(() {
                      selectedTabId = id;
                    });
                  },
                ),
              ),

              const SizedBox(width: 18),

              // RIGHT: main glass content
              Expanded(
                child: GlassContainer(
                  blur: glassBlur,
                  opacity: glassOpacity,
                  tint: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  padding: const EdgeInsets.all(24),
                  // OLD:
                  // blurMode: GlassBlurMode.auto,
                  // NEW: force blur for this panel
                  blurMode: GlassBlurMode.perWidget,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header uses TaskTabDef.title/icon (no .name)
                      Row(
                        children: [
                          Icon(
                            _currentTab.icon,
                            color: Colors.cyan,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _currentTab.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (kDebugMode)
                            Text(
                              'Blur: ${glassBlur.toStringAsFixed(1)}  |  '
                              'Opacity: ${(glassOpacity * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Body: use builder from TaskTabDef so pages stay single‑sourced
                      Expanded(
                        child: _currentTab.builder(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
