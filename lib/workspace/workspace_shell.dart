import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walld_flutter/core/permissions_cache.dart';
import 'package:walld_flutter/workspace/universal_top_bar.dart';
import 'package:walld_flutter/workspace/workspace_controller.dart';
import 'package:walld_flutter/workspace/workspace_ids.dart';

import '../core/performance_state.dart';
import '../core/wallpaper_service.dart';
import '../dynamic_screen/dashboard_screen.dart';
import '../task/task_workspace.dart';

// Imports from the other 2 files
import 'widgets/fps_counter.dart';
import 'mixins/shell_performance_mixin.dart';

class WorkspaceShell extends StatefulWidget {
  final WorkspaceController workspaceController;

  const WorkspaceShell({
    super.key,
    required this.workspaceController,
  });

  @override
  State<WorkspaceShell> createState() => WorkspaceShellState();
}

// Mixin added here to separate performance logic
class WorkspaceShellState extends State<WorkspaceShell>
    with SingleTickerProviderStateMixin, ShellPerformanceMixin {
  
  // DEBUG INSTANCE TRACKING
  static int _instanceCounter = 0;
  final int _instanceNumber;
  final String _instanceId = DateTime.now().millisecondsSinceEpoch.toString();

  late final AnimationController animationController;
  late final Animation<Offset> _slideForward;
  late final Animation<Offset> _slideBackward;
  late final Animation<double> _fadeOut;
  late final Animation<double> _fadeIn;

  int _currentIndex = 0;
  int _previousIndex = 0;
  bool _isAnimating = false;
  bool _isForward = true;

  Duration _lastBuildDuration = Duration.zero;

  WorkspaceShellState() : _instanceNumber = ++_instanceCounter {
    debugPrint('🏢 WorkspaceShell INSTANCE #$_instanceNumber CREATED (ID: $_instanceId)');
  }

  @override
  void initState() {
    super.initState();
    debugPrint('🏢 WorkspaceShell #$_instanceNumber - initState()');

    _currentIndex = _getCurrentIndex();
    _previousIndex = _currentIndex;

    animationController = AnimationController(
      duration: const Duration(milliseconds: 360),
      vsync: this,
    );

    _setupCachedAnimations();

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        setAnimating(true); // From Mixin
        if (mounted) setState(() => _isAnimating = true);
      } else if (status == AnimationStatus.completed) {
        setAnimating(false); // From Mixin
        if (mounted) {
          setState(() {
            _isAnimating = false;
            _previousIndex = _currentIndex;
          });
        }
      }
    });

    widget.workspaceController.addListener(_onWorkspaceChanged);
    
    // Initialize performance tracking from Mixin
    initPerformanceTracking();
  }

  void _setupCachedAnimations() {
    const curve = Curves.easeInOutCubicEmphasized;

    _slideForward = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    ).animate(CurvedAnimation(parent: animationController, curve: curve));

    _slideBackward = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0),
    ).animate(CurvedAnimation(parent: animationController, curve: curve));

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.0, 0.60, curve: Curves.easeOut),
      ),
    );

    _fadeIn = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.10, 0.85, curve: Curves.easeIn),
      ),
    );
  }

  int _getCurrentIndex() {
    return widget.workspaceController.current == WorkspaceIds.task ? 1 : 0;
  }

  void _onWorkspaceChanged() {
    final newIndex = _getCurrentIndex();
    if (newIndex == _currentIndex) return;
    if (_isAnimating) return;

    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = newIndex;
      _isForward = newIndex > _previousIndex;
    });

    animationController.forward(from: 0.0);
  }

  // NOTE: This logic stays here because it accesses AnimationController
  @override
  void onLowEndModeChanged(bool isLowEnd) {
    if (isLowEnd) {
      animationController.duration = const Duration(milliseconds: 300);
    }
  }

  Future<void> pickWallpaperFromWindows() async {
    await WallpaperService.instance.pickWallpaper();
  }

  Future<void> signOut() async {
  try {
    debugPrint('WorkspaceShell #$_instanceNumber - Starting logout process...');

    PermissionsCache.instance.clearCache();
    debugPrint('Permissions cache cleared');

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint('SharedPreferences cleared');

    WallpaperService.instance.wallpaperPath = null;
    WallpaperService.instance.globalGlassOpacity = 0.12;
    WallpaperService.instance.globalGlassBlur = 16.0;
    debugPrint('WallpaperService reset');

    await FirebaseAuth.instance.signOut();
    debugPrint('Firebase Auth signed out');

    if (!mounted) return;

    

    // SnackBar...
  } catch (e) {
    debugPrint('Sign out error: $e');
  }
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
                    const Text('Glass settings', style: TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text('Opacity', style: TextStyle(color: Colors.white70)),
                        Expanded(
                          child: Slider(
                            min: 0.04, max: 0.30, divisions: 26,
                            value: tempOpacity.clamp(0.04, 0.30),
                            onChanged: (v) => setModalState(() => tempOpacity = v),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Blur', style: TextStyle(color: Colors.white70)),
                        Expanded(
                          child: Slider(
                            min: 0, max: 30, divisions: 30,
                            value: tempBlur.clamp(0, 30),
                            onChanged: (v) => setModalState(() => tempBlur = v),
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Apply'),
                      ),
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

  @override
  void dispose() {
    debugPrint('🏢 WorkspaceShell #$_instanceNumber DISPOSED');
    widget.workspaceController.removeListener(_onWorkspaceChanged);
    animationController.dispose();
    disposePerformanceTracking(); // From Mixin
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buildStart = DateTime.now();

    final outgoingSlide = _isForward ? _slideForward : _slideBackward;
    final incomingSlide = _isForward
        ? Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
            CurvedAnimation(parent: animationController, curve: Curves.easeInOutCubicEmphasized))
        : Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(
            CurvedAnimation(parent: animationController, curve: Curves.easeInOutCubicEmphasized));

    final result = Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1) Wallpaper
          Positioned.fill(
            child: AnimatedBuilder(
              animation: WallpaperService.instance,
              builder: (_, __) => DecoratedBox(
                decoration: WallpaperService.instance.backgroundDecoration,
              ),
            ),
          ),

          // 2) Content
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: animationController,
              builder: (context, child) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Visibility(
                        visible: _currentIndex == 0 || _isAnimating,
                        child: SlideTransition(
                          position: _currentIndex == 0 ? incomingSlide : outgoingSlide,
                          child: FadeTransition(
                            opacity: _currentIndex == 0 ? _fadeIn : _fadeOut,
                            child: const RepaintBoundary(
                                child: DashboardScreen(key: PageStorageKey('dashboardscreen'))),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Visibility(
                        visible: _currentIndex == 1 || _isAnimating,
                        child: SlideTransition(
                          position: _currentIndex == 1 ? incomingSlide : outgoingSlide,
                          child: FadeTransition(
                            opacity: _currentIndex == 1 ? _fadeIn : _fadeOut,
                            child: const RepaintBoundary(
                                child: TaskWorkspace(key: PageStorageKey('taskworkspace'))),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // 3) Top Bar
          RepaintBoundary(
            child: UniversalTopBar(
              workspaceController: widget.workspaceController,
              onWallpaperSettings: pickWallpaperFromWindows,
              onGlassSettings: openGlobalGlassSheet,
              onSignOut: signOut,
            ),
          ),

          // 4) FPS Counter (Using Mixin Data)
          if (showFPS)
            Positioned(
              top: 60, right: 16,
              child: ValueListenableBuilder<double>(
                valueListenable: fpsNotifier,
                builder: (context, fps, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: isAnimatingNotifier,
                    builder: (context, isAnimating, _) {
                      return FPSCounter(
                        fps: fps,
                        isAnimating: isAnimating,
                        isLowEnd: isLowEndDevice,
                        vsyncLocked: vsyncLockDetected,
                        avgFrameTime: avgFrameTimeWindow,
                        warmupStable: PerformanceState.instance.isWarmupStable,
                        onToggle: toggleFPS,
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );

    _lastBuildDuration = DateTime.now().difference(buildStart);
    if (kDebugMode && _lastBuildDuration.inMilliseconds > 24) {
      debugPrint('[BUILD] #$_instanceNumber dt=${_lastBuildDuration.inMilliseconds}ms');
    }

    return result;
  }
}
