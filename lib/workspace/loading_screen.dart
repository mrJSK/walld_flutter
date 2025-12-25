import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/permissions_cache.dart';
import '../core/wallpaper_service.dart';
import '../dynamic_screen/dashboard_permissions.dart';

class LoadingScreen extends StatefulWidget {
  final VoidCallback onLoadingComplete;

  const LoadingScreen({
    super.key,
    required this.onLoadingComplete,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  final ValueNotifier<double> _progress = ValueNotifier<double>(0.0);
  final ValueNotifier<String> _status = ValueNotifier<String>('Initializing…');

  bool _completed = false;
  Object? _error;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start after first frame so context is stable.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startLoadingSequence());
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progress.dispose();
    _status.dispose();
    super.dispose();
  }

  Future<void> _startLoadingSequence() async {
    if (_completed) return;

    try {
      _error = null;

      await _step(0.10, 'Loading wallpaper…', () async {
        // Safe even if already loaded (WallpaperService guards internally)
        await WallpaperService.instance.loadSettings();
      });

      await _step(0.35, 'Checking authentication…', () async {
        // Just touching currentUser is cheap; no extra delay needed
        FirebaseAuth.instance.currentUser;
      });

      await _step(0.65, 'Loading permissions…', () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        // Use cache first
        final cached = PermissionsCache.instance.getCachedPermissions(user.uid);
        if (cached != null) return;

        final ids = await _loadPermissions(user.uid);
        PermissionsCache.instance.setCachedPermissions(user.uid, ids);
      });

      await _step(0.90, 'Finalizing…', () async {
        // Tiny yield to ensure UI paints last progress update
        await Future<void>.delayed(const Duration(milliseconds: 60));
      });

      _progress.value = 1.0;
      _status.value = 'Ready';

      await Future<void>.delayed(const Duration(milliseconds: 160));
      _complete();
    } catch (e) {
      _error = e;
      _status.value = 'Loading failed. Retry?';
      if (kDebugMode) {
        debugPrint('[LoadingScreen] error: $e');
      }
    }
  }

  Future<void> _step(
    double progress,
    String message,
    Future<void> Function() action,
  ) async {
    _progress.value = progress;
    _status.value = message;
    await action();
  }

  Future<Set<String>> _loadPermissions(String userId) async {
    final completer = Completer<Set<String>>();

    await DashboardPermissions.loadUserPermissions(
      context: context,
      userId: userId,
      onAllowedWidgetIds: (ids) {
        if (!completer.isCompleted) completer.complete(ids);
      },
    );

    // Safety: don't hang forever on network issues.
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => <String>{'login'},
    );
  }

  void _complete() {
    if (_completed) return;
    _completed = true;
    widget.onLoadingComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Wallpaper background: repaints only this layer on wallpaper changes.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: WallpaperService.instance,
              builder: (_, __) => DecoratedBox(
                decoration: WallpaperService.instance.backgroundDecoration,
              ),
            ),
          ),

          // Subtle dark overlay for legibility
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
              ),
            ),
          ),

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: ScaleTransition(
                  scale: _pulse,
                  child: _Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 6),
                        const Text(
                          'WALL-D',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Preparing your workspace…',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 18),

                        ValueListenableBuilder<double>(
                          valueListenable: _progress,
                          builder: (_, p, __) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: p.clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: Colors.white.withOpacity(0.10),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.cyanAccent,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        ValueListenableBuilder<String>(
                          valueListenable: _status,
                          builder: (_, msg, __) {
                            return Text(
                              msg,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _complete,
                                child: const Text('Continue'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () {
                                  _error = null;
                                  unawaited(_startLoadingSequence());
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xCC0B0B12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: const [
          BoxShadow(
            color: Color(0xAA000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}
