import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/glass_container.dart';
import '../workspace/workspace_controller.dart';
import '../workspace/workspace_switcher.dart';
import 'task_tabs_manifest.dart';
import 'widgets/task_side_panel.dart';

class TaskWorkspace extends StatefulWidget {
  final WorkspaceController workspaceController;

  const TaskWorkspace({super.key, required this.workspaceController});

  @override
  State<TaskWorkspace> createState() => _TaskWorkspaceState();
}

class _TaskWorkspaceState extends State<TaskWorkspace> {
  String tabId = taskTabs.first.id;

  double glassBlur = 18;
  double glassOpacity = 0.16;

  @override
  Widget build(BuildContext context) {
    final tab = taskTabs.firstWhere((x) => x.id == tabId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: _backgroundDecoration(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
            child: Column(
              children: [
                // TOP BAR with centered WorkspaceSwitcher (your existing Stack)
                SizedBox(
                  height: 40,
                  child: GlassContainer(
                    blur: glassBlur,
                    opacity: glassOpacity,
                    tint: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.blur_on_rounded,
                                color: Colors.cyan,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Wall-D · Task Workspace',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: WorkspaceSwitcher(
                            controller: widget.workspaceController,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // MAIN TASK LAYOUT with slide+fade
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final offsetAnimation = Tween<Offset>(
                        begin: const Offset(-0.04, 0), // from left for contrast
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
                            onSelect: (id) => setState(() => tabId = id),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassContainer(
                            blur: glassBlur,
                            opacity: glassOpacity,
                            tint: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            padding:
                                const EdgeInsets.fromLTRB(18, 16, 18, 16),
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
                                Expanded(child: tab.builder(context)),
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
  BoxDecoration _backgroundDecoration() {
  return const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF050716),
        Color(0xFF020308),
      ],
    ),
  );
}

}

