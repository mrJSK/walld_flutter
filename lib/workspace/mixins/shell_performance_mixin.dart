import 'dart:collection';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';

import '../../core/performance_state.dart';
import '../../core/wallpaper_service.dart';

mixin ShellPerformanceMixin<T extends StatefulWidget> on State<T> {
  
  // State variables for Performance
  final ValueNotifier<double> fpsNotifier = ValueNotifier<double>(60.0);
  final ValueNotifier<bool> isAnimatingNotifier = ValueNotifier<bool>(false);
  
  bool showFPS = true;
  bool isLowEndDevice = false;
  bool vsyncLockDetected = false;
  double avgFrameTimeWindow = 0.0;
  
  // Internal trackers
  final Queue<double> _frameMsWindow = Queue<double>();
  static const int _windowSize = 180;
  static const double _targetFrameTime = 16.67;
  static const double _jankThreshold = 33.33;
  static const double _severeJankThreshold = 50.0;
  
  int _frameCount = 0;
  int _consecutive30fpsLike = 0;
  int _stableChecks = 0;
  bool _warmupMarked = false;
  
  DateTime _lastPerfLog = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastJankLog = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastSevereJankLog = DateTime.fromMillisecondsSinceEpoch(0);

  // Method to be overridden by Shell to adjust animations
  void onLowEndModeChanged(bool isLowEnd) {}

  void initPerformanceTracking() {
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
  }

  void disposePerformanceTracking() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    fpsNotifier.dispose();
    isAnimatingNotifier.dispose();
  }

  void setAnimating(bool animating) {
    isAnimatingNotifier.value = animating;
  }
  
  void toggleFPS() {
    if (mounted) setState(() => showFPS = !showFPS);
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

      avgFrameTimeWindow = avgMs;

      final fps = (1000.0 / avgMs).clamp(1.0, 240.0);
      _frameCount++;

      PerformanceState.instance.currentFps = fps;

      if (_frameCount % 10 == 0) {
        fpsNotifier.value = fps;
      }

      if (!isLowEndDevice && fps < 50) {
        isLowEndDevice = true;
        onLowEndModeChanged(true);
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
          'stable=${PerformanceState.instance.isWarmupStable ? "Y" : "N"}',
        );
      }
    }
  }

  void _logJank({required bool severe, required double frameMs, required double fps}) {
    final tag = severe ? 'JANK:S' : 'JANK:M';
    final dropped = (frameMs / _targetFrameTime).floor();
    debugPrint('[$tag] dt=${frameMs.toStringAsFixed(1)}ms drop=$dropped fps=${fps.toStringAsFixed(1)}');
    
    if (severe) {
      developer.Timeline.instantSync('JANK_SEVERE', arguments: {'dtMs': frameMs, 'fps': fps});
    }
  }

  void _detectVsyncLock(double avgMs) {
    if (avgMs > 30.0 && avgMs < 36.5) {
      if (++_consecutive30fpsLike >= 12) vsyncLockDetected = true;
    } else if (avgMs < 22.0) {
      _consecutive30fpsLike = 0;
      vsyncLockDetected = false;
    }
  }

  void _checkWarmupStability(double avgMs, double fps) {
    if (_warmupMarked || _frameMsWindow.length < 120) return;
    
    final severeCount = _frameMsWindow.where((ms) => ms >= _severeJankThreshold).length;
    final stable = fps >= 45 && !isAnimatingNotifier.value && severeCount <= 6;

    if (stable) {
      if (++_stableChecks >= 6) {
        _warmupMarked = true;
        PerformanceState.instance.isWarmupStable = true;
        if (kDebugMode) debugPrint('[WARMUP] Stable! fps=${fps.toStringAsFixed(1)}');
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
      if (kDebugMode) debugPrint('[OPT] extreme blur=0 op=0.04');
    } else if (avgFps < 40) {
      ws.setGlassBlur(6.0);
      ws.setGlassOpacity(0.08);
      if (kDebugMode) debugPrint('[OPT] medium blur=6 op=0.08');
    } else if (avgFps < 50) {
      ws.setGlassBlur(8.0);
      ws.setGlassOpacity(0.10);
      if (kDebugMode) debugPrint('[OPT] light blur=8 op=0.10');
    }
  }
}
