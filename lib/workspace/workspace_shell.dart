import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/wallpaper_service.dart';
import '../dynamic_screen/dashboardpanel.dart';
import '../task/task_workspace.dart';

import 'universal_top_bar.dart';
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
    widget.workspaceController.addListener(onWorkspaceChanged);
  }

  @override
  void dispose() {
    widget.workspaceController.removeListener(onWorkspaceChanged);
    super.dispose();
  }

  void onWorkspaceChanged() {
    setState(() {});
  }

  // --- Global Actions ---
  Future<void> pickWallpaperFromWindows() async {
    await WallpaperService.instance.pickWallpaper();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> openGlobalGlassSheet() async {
    final service = WallpaperService.instance;
    double tempOpacity = service.globalGlassOpacity;
    double tempBlur = service.globalGlassBlur;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF05040A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag Handle
                    Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    // Title
                    const Row(
                      children: [
                        Icon(
                          Icons.blur_on_rounded,
                          color: Colors.cyanAccent,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Glass settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Opacity Slider
                    Row(
                      children: [
                        const SizedBox(
                          width: 70,
                          child: Text(
                            'Opacity',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            min: 0.04,
                            max: 0.30,
                            divisions: 26,
                            value: tempOpacity.clamp(0.04, 0.30),
                            label: tempOpacity.toStringAsFixed(2),
                            onChanged: (v) {
                              setModalState(() => tempOpacity = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    // Blur Slider
                    Row(
                      children: [
                        const SizedBox(
                          width: 70,
                          child: Text(
                            'Blur',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            min: 0,
                            max: 30,
                            divisions: 30,
                            value: tempBlur.clamp(0, 30),
                            label: tempBlur.toStringAsFixed(0),
                            onChanged: (v) {
                              setModalState(() => tempBlur = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Apply Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => Navigator.pop(context, true),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (applied == true) {
      service.setGlassOpacity(tempOpacity);
      service.setGlassBlur(tempBlur);
      await service.saveSettings();
    }
  }

  int getCurrentIndex() {
    if (widget.workspaceController.current == WorkspaceIds.task) {
      return 1;
    }
    return 0; // Default to Dashboard
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Ultra-smooth animated screen switching
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500), // Slightly longer for smoothness
            switchInCurve: Curves.easeInOutCubicEmphasized, // Premium curve
            switchOutCurve: Curves.easeInOutCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              // Determine direction
              final isForward = child.key == const ValueKey('task');
              
              // Slide animation with custom curve for natural motion
              final slideAnimation = Tween<Offset>(
                begin: Offset(isForward ? 1.0 : -1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubicEmphasized, // Smooth deceleration
                ),
              );
              
              // Fade animation - synchronized throughout the transition
              final fadeAnimation = Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.6, curve: Curves.easeIn), // Fade gradually
                ),
              );
              
              // Subtle scale for depth perception
              final scaleAnimation = Tween<double>(
                begin: 0.95,
                end: 1.0,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
                ),
              );
              
              return SlideTransition(
                position: slideAnimation,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: ScaleTransition(
                    scale: scaleAnimation,
                    child: child,
                  ),
                ),
              );
            },
            child: _buildCurrentScreen(),
          ),
          
          // 2. Universal Top Bar (stays fixed during transitions)
          UniversalTopBar(
            workspaceController: widget.workspaceController,
            onWallpaperSettings: pickWallpaperFromWindows,
            onGlassSettings: openGlobalGlassSheet,
            onSignOut: signOut,
          ),
        ],
      ),
    );
  }

  // Helper method to build the current screen with unique key
  Widget _buildCurrentScreen() {
    final currentIndex = getCurrentIndex();
    
    if (currentIndex == 1) {
      // Task Workspace
      return TaskWorkspace(
        key: const ValueKey('task'),
        workspaceController: widget.workspaceController,
      );
    } else {
      // Dashboard Panel
      return DashboardPanel(
        key: const ValueKey('dashboard'),
        workspaceController: widget.workspaceController,
      );
    }
  }
}
