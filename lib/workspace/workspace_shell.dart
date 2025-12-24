import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../dynamic_screen/dashboardpanel.dart';
import '../task/task_workspace.dart';
import '../core/wallpaper_service.dart';
import 'workspace_controller.dart';
import 'workspace_ids.dart';

// IMPORTANT: Ensure this import matches the file you just created
import 'universal_top_bar.dart'; 

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
    widget.workspaceController.addListener(_onWorkspaceChanged);
  }

  @override
  void dispose() {
    widget.workspaceController.removeListener(_onWorkspaceChanged);
    super.dispose();
  }

  void _onWorkspaceChanged() {
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
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Glass Settings', style: TextStyle(color: Colors.white, fontSize: 18)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text('Blur', style: TextStyle(color: Colors.white)),
                        Expanded(child: Slider(value: tempBlur, min: 0, max: 30, onChanged: (v) => setModalState(() => tempBlur = v))),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Opacity', style: TextStyle(color: Colors.white)),
                        Expanded(child: Slider(value: tempOpacity, min: 0.0, max: 0.5, onChanged: (v) => setModalState(() => tempOpacity = v))),
                      ],
                    ),
                    ElevatedButton(
                         onPressed: () => Navigator.pop(context, true), 
                         child: const Text("Apply")
                    )
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

  int _getCurrentIndex() {
    if (widget.workspaceController.current == WorkspaceIds.task) return 1;
    return 0; // Default to Dashboard
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Screens (with padding for the top bar)
          Padding(
            padding: const EdgeInsets.only(top: 80.0), 
            child: IndexedStack(
              index: _getCurrentIndex(),
              children: [
                DashboardPanel(
                  key: const PageStorageKey('dashboard_panel'),
                  workspaceController: widget.workspaceController,
                ),
                TaskWorkspace(
                  key: const PageStorageKey('task_workspace'),
                  workspaceController: widget.workspaceController,
                ),
              ],
            ),
          ),

          // 2. Universal Top Bar
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
}