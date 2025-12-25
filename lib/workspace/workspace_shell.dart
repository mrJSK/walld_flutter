// lib/workspace/workspace_shell.dart
import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/performance_state.dart';
import '../core/wallpaper_service.dart';
import '../dynamic_screen/dashboard_screen.dart';
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

class _WorkspaceShellState extends State<WorkspaceShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  late final Animation<Offset> _slideForward;
  late final Animation<Offset> _slideBackward;
  late final Animation<double> _fadeOut;
  late final Animation<double> _fadeIn;

  int _currentIndex = 0;
  int _previousIndex = 0;
  bool _isAnimating = false;
  bool _isForward = true;
  bool _isLowEndDevice = false;

  // FPS / perf tracking
  final ValueNotifier<double> _fpsNotifier = ValueNotifier<double>(60.0);
  final ValueNotifier<bool> _isAnimatingNotifier = ValueNotifier<bool>(false);
  bool _showFPS = true;

  final Queue<double> _frameMsWindow = Queue<double>();
  static const int _windowSize = 180; // ~3s at 60fps
  int _frameCount = 0;

  static const double _targetFrameTime = 16.67;
  static const double _jankThreshold = 33.33;
  static const double _severeJankThreshold = 50.0;

  // Rate-limit logs
  DateTime _lastPerfLog = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastJankLog = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastSevereJankLog = DateTime.fromMillisecondsSinceEpoch(0);

  // Vsync lock detection
  int _consecutive30fpsLike = 0;
  bool _vsyncLockDetected = false;
  double _avgFrameTimeWindow = 0.0;

  // Warm-up stability
  bool _warmupMarked = false;
  int _stableChecks = 0;

  Duration _lastBuildDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    _currentIndex = getCurrentIndex();
    _previousIndex = _currentIndex;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 360),
      vsync: this,
    );

    _setupCachedAnimations();

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        _isAnimatingNotifier.value = true;
        if (mounted) setState(() => _isAnimating = true);
      } else if (status == AnimationStatus.completed) {
        _isAnimatingNotifier.value = false;
        if (mounted) {
          setState(() {
            _isAnimating = false;
            _previousIndex = _currentIndex;
          });
        }
      }
    });

    widget.workspaceController.addListener(_onWorkspaceChanged);

    // Real frame timings
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
  }

  void _setupCachedAnimations() {
    const curve = Curves.easeInOutCubicEmphasized;

    _slideForward = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    ).animate(CurvedAnimation(parent: _animationController, curve: curve));

    _slideBackward = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0),
    ).animate(CurvedAnimation(parent: _animationController, curve: curve));

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.60, curve: Curves.easeOut),
      ),
    );

    _fadeIn = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.10, 0.85, curve: Curves.easeIn),
      ),
    );
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      final frameMs = t.totalSpan.inMicroseconds / 1000.0;

      _frameMsWindow.addLast(frameMs);
      while (_frameMsWindow.length > _windowSize) {
        _frameMsWindow.removeFirst();
      }

      final avgMs = _frameMsWindow.isEmpty
          ? _targetFrameTime
          : _frameMsWindow.reduce((a, b) => a + b) / _frameMsWindow.length;

      _avgFrameTimeWindow = avgMs;

      final fps = (1000.0 / avgMs).clamp(1.0, 240.0);
      _frameCount++;

      PerformanceState.instance.currentFps = fps;

      if (_frameCount % 10 == 0) {
        _fpsNotifier.value = fps;
      }

      if (!_isLowEndDevice && fps < 50) {
        _isLowEndDevice = true;
        _animationController.duration = const Duration(milliseconds: 300);
        _applyPerformanceOptimizations(fps);
      }

      if (!kDebugMode) continue;

      if (frameMs >= _severeJankThreshold) {
        final now = DateTime.now();
        if (now.difference(_lastSevereJankLog).inMilliseconds >= 700) {
          _lastSevereJankLog = now;
          _logJank(severe: true, frameMs: frameMs, fps: fps);
        }
      } else if (frameMs >= _jankThreshold) {
        final now = DateTime.now();
        if (now.difference(_lastJankLog).inMilliseconds >= 900) {
          _lastJankLog = now;
          _logJank(severe: false, frameMs: frameMs, fps: fps);
        }
      }

      _detectVsyncLock(avgMs);
      _checkWarmupStability(avgMs, fps);

      final now = DateTime.now();
      if (now.difference(_lastPerfLog).inSeconds >= 10) {
        _lastPerfLog = now;
        debugPrint(
          '[PERF] fps=${fps.toStringAsFixed(1)} avg=${avgMs.toStringAsFixed(1)}ms '
          'anim=${_isAnimating ? "Y" : "N"} stable=${PerformanceState.instance.isWarmupStable ? "Y" : "N"}',
        );
      }
    }
  }

  void _logJank({
    required bool severe,
    required double frameMs,
    required double fps,
  }) {
    final tag = severe ? 'JANK:S' : 'JANK:M';
    final screen = _currentIndex == 0 ? 'Dashboard' : 'Task';
    final dropped = (frameMs / _targetFrameTime).floor();

    debugPrint(
      '[$tag] dt=${frameMs.toStringAsFixed(1)}ms drop=$dropped '
      'fps=${fps.toStringAsFixed(1)} scr=$screen anim=${_isAnimating ? "Y" : "N"} '
      'build=${_lastBuildDuration.inMilliseconds}ms',
    );

    if (severe) {
      developer.Timeline.instantSync(
        'JANK_SEVERE',
        arguments: {
          'dtMs': frameMs,
          'fps': fps,
          'screen': screen,
          'animating': _isAnimating,
          'buildMs': _lastBuildDuration.inMilliseconds,
        },
      );
    }
  }

  void _detectVsyncLock(double avgMs) {
    final looksLike30 = avgMs > 30.0 && avgMs < 36.5;
    if (looksLike30) {
      _consecutive30fpsLike++;
      if (_consecutive30fpsLike >= 12) {
        _vsyncLockDetected = true;
      }
    } else {
      if (avgMs < 22.0) {
        _consecutive30fpsLike = 0;
        _vsyncLockDetected = false;
      }
    }
  }

  void _checkWarmupStability(double avgMs, double fps) {
    if (_warmupMarked) return;
    if (_frameMsWindow.length < 120) return;

    final severeCount =
        _frameMsWindow.where((ms) => ms >= _severeJankThreshold).length;

    final stable = fps >= 45 &&
        !_animationController.isAnimating &&
        severeCount <= 6;

    if (stable) {
      _stableChecks++;
      if (_stableChecks >= 6) {
        _warmupMarked = true;
        PerformanceState.instance.isWarmupStable = true;
        if (kDebugMode) {
          debugPrint(
            '[WARMUP] stable fps=${fps.toStringAsFixed(1)} '
            'avg=${avgMs.toStringAsFixed(1)}ms severe=$severeCount',
          );
        }
      }
    } else {
      _stableChecks = 0;
    }
  }

  void _applyPerformanceOptimizations(double avgFps) {
    final ws = WallpaperService.instance;

    if (avgFps < 25) {
      ws.setGlassBlur(0.0);
      ws.setGlassOpacity(0.04);
      if (kDebugMode) {
        debugPrint('[OPT] extreme blur=0 op=0.04 fps=${avgFps.toStringAsFixed(1)}');
      }
    } else if (avgFps < 40) {
      ws.setGlassBlur(6.0);
      ws.setGlassOpacity(0.08);
      if (kDebugMode) {
        debugPrint('[OPT] medium blur=6 op=0.08 fps=${avgFps.toStringAsFixed(1)}');
      }
    } else if (avgFps < 50) {
      ws.setGlassBlur(8.0);
      ws.setGlassOpacity(0.10);
      if (kDebugMode) {
        debugPrint('[OPT] light blur=8 op=0.10 fps=${avgFps.toStringAsFixed(1)}');
      }
    }
  }

  int getCurrentIndex() {
    return widget.workspaceController.current == WorkspaceIds.task ? 1 : 0;
  }

  void _onWorkspaceChanged() {
    final newIndex = getCurrentIndex();
    if (newIndex == _currentIndex) return;
    if (_isAnimating) return;

    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = newIndex;
      _isForward = newIndex > _previousIndex;
    });

    _animationController.forward(from: 0.0);
  }

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
                    Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.blur_on_rounded,
                            color: Colors.cyanAccent, size: 18),
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
                    Row(
                      children: [
                        const SizedBox(
                          width: 70,
                          child: Text('Opacity',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ),
                        Expanded(
                          child: Slider(
                            min: 0.04,
                            max: 0.30,
                            divisions: 26,
                            value: tempOpacity.clamp(0.04, 0.30),
                            label: tempOpacity.toStringAsFixed(2),
                            onChanged: (v) =>
                                setModalState(() => tempOpacity = v),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const SizedBox(
                          width: 70,
                          child: Text('Blur',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ),
                        Expanded(
                          child: Slider(
                            min: 0,
                            max: 30,
                            divisions: 30,
                            value: tempBlur.clamp(0, 30),
                            label: tempBlur.toStringAsFixed(0),
                            onChanged: (v) => setModalState(() => tempBlur = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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

  /// Global blur sigma applied ONCE on wallpaper layer (root-level).
  ///
  /// This intentionally reduces blur when:
  /// - Warmup not stable (startup stutters)
  /// - FPS is low
  /// - Animations are running
  double _effectiveGlobalWallpaperBlurSigma() {
    final requested = WallpaperService.instance.globalGlassBlur.clamp(0.0, 40.0);
    final fps = PerformanceState.instance.currentFps;

    // During startup / unknown fps: be conservative.
    if (!PerformanceState.instance.isWarmupStable || fps == null) {
      return requested.clamp(0.0, 2.0);
    }

    // During transitions: drop blur hard.
    if (_isAnimating) {
      return requested.clamp(0.0, 2.0);
    }

    // Low FPS: reduce blur.
    if (fps < 30) return 0.0;
    if (fps < 45) return requested.clamp(0.0, 2.0);
    if (fps < 55) return requested.clamp(0.0, 6.0);

    return requested.clamp(0.0, 18.0);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    widget.workspaceController.removeListener(_onWorkspaceChanged);

    _animationController.dispose();
    _fpsNotifier.dispose();
    _isAnimatingNotifier.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buildStart = DateTime.now();

    final outgoingSlide = _isForward ? _slideForward : _slideBackward;
    final incomingSlide = _isForward
        ? Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeInOutCubicEmphasized,
            ),
          )
        : Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeInOutCubicEmphasized,
            ),
          );

    final result = Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1) Wallpaper background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: WallpaperService.instance,
              builder: (_, __) => DecoratedBox(
                decoration: WallpaperService.instance.backgroundDecoration,
              ),
            ),
          ),

          // 2) GLOBAL BLUR LAYER (applies blur ONCE to wallpaper only)
          // In WorkspaceShell, replace global blur layer with:
          Positioned.fill(
            child: const SizedBox.expand(), // No BackdropFilter
          ),


          // 3) Animated screens (UI is ABOVE blur, so UI is not blurred)
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Visibility(
                        visible: _currentIndex == 0 || _isAnimating,
                        maintainState: true,
                        maintainAnimation: true,
                        child: SlideTransition(
                          position: _currentIndex == 0
                              ? incomingSlide
                              : outgoingSlide,
                          child: FadeTransition(
                            opacity: _currentIndex == 0 ? _fadeIn : _fadeOut,
                            child: const RepaintBoundary(
                              child: DashboardScreen(
                                key: PageStorageKey('dashboardscreen'),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Visibility(
                        visible: _currentIndex == 1 || _isAnimating,
                        maintainState: true,
                        maintainAnimation: true,
                        child: SlideTransition(
                          position: _currentIndex == 1
                              ? incomingSlide
                              : outgoingSlide,
                          child: FadeTransition(
                            opacity: _currentIndex == 1 ? _fadeIn : _fadeOut,
                            child: RepaintBoundary(
                              child: TaskWorkspace(
                                key: const PageStorageKey('taskworkspace'),
                                workspaceController: widget.workspaceController,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Top bar
          RepaintBoundary(
            child: UniversalTopBar(
              workspaceController: widget.workspaceController,
              onWallpaperSettings: pickWallpaperFromWindows,
              onGlassSettings: openGlobalGlassSheet,
              onSignOut: signOut,
            ),
          ),

          // FPS counter
          if (_showFPS)
            Positioned(
              top: 60,
              right: 16,
              child: ValueListenableBuilder<double>(
                valueListenable: _fpsNotifier,
                builder: (context, fps, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _isAnimatingNotifier,
                    builder: (context, isAnimating, _) {
                      return _FPSCounter(
                        fps: fps,
                        isAnimating: isAnimating,
                        isLowEnd: _isLowEndDevice,
                        vsyncLocked: _vsyncLockDetected,
                        avgFrameTime: _avgFrameTimeWindow,
                        warmupStable: PerformanceState.instance.isWarmupStable,
                        onToggle: () => setState(() => _showFPS = !_showFPS),
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
      debugPrint(
        '[BUILD] dt=${_lastBuildDuration.inMilliseconds}ms anim=${_isAnimating ? "Y" : "N"}',
      );
    }

    return result;
  }
}

class _FPSCounter extends StatelessWidget {
  final double fps;
  final bool isAnimating;
  final bool isLowEnd;
  final bool vsyncLocked;
  final double avgFrameTime;
  final bool warmupStable;
  final VoidCallback onToggle;

  const _FPSCounter({
    required this.fps,
    required this.isAnimating,
    required this.isLowEnd,
    required this.vsyncLocked,
    required this.avgFrameTime,
    required this.warmupStable,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    Color fpsColor;
    String status;

    if (fps >= 58) {
      fpsColor = Colors.greenAccent;
      status = 'EXCELLENT';
    } else if (fps >= 50) {
      fpsColor = Colors.yellowAccent;
      status = 'GOOD';
    } else if (fps >= 40) {
      fpsColor = Colors.orangeAccent;
      status = 'FAIR';
    } else if (fps >= 28 && fps <= 32) {
      fpsColor = Colors.redAccent;
      status = 'VSYNC 30FPS';
    } else {
      fpsColor = Colors.red;
      status = 'LOW';
    }

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: fpsColor.withOpacity(0.6), width: 2),
          boxShadow: [
            BoxShadow(
              color: fpsColor.withOpacity(0.25),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.speed, color: fpsColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${fps.toStringAsFixed(1)} FPS',
                  style: TextStyle(
                    color: fpsColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: TextStyle(
                color: fpsColor.withOpacity(0.9),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            if (avgFrameTime > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Frame: ${avgFrameTime.toStringAsFixed(1)}ms',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
            if (warmupStable) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.45),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'WARM-UP OK',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            if (vsyncLocked) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.redAccent, width: 1),
                ),
                child: const Text(
                  'VSYNC LOCKED',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
            if (isLowEnd) ...[
              const SizedBox(height: 4),
              const Text(
                'OPTIMIZED',
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (isAnimating) ...[
              const SizedBox(height: 4),
              const Text(
                'ANIMATING',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
