import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:walld_flutter/dynamic_screen/dashboard_layout_persistence.dart';
import 'package:walld_flutter/dynamic_screen/model/screen_grid.dart'
    show ScreenGridWidgetSpan, ScreenGridConfig;

import '../core/wallpaper_service.dart';
import 'dashboard_grid.dart';
import 'dashboard_permissions.dart';
import 'widget_manifest.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const ScreenGridConfig _grid = ScreenGridConfig(columns: 24, rows: 14);

  bool _loading = true;
  String? _error;
  Set<String> _allowedWidgetIds = const {'login'};
  final List<ScreenGridWidgetSpan> _items = [];
  
  StreamSubscription<User?>? _authSubscription;

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? 'anon';
  String get _layoutPrefsKey => 'dashboard_layout_v1_$_userId';

  @override
  void initState() {
    super.initState();
    
    // Listen to auth state changes
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        // User logged out - show only login widget
        debugPrint('🔒 User logged out - showing login widget only');
        _showLoginOnly();
      } else {
        // User logged in - load permissions
        debugPrint('✅ User logged in: ${user.uid} - loading permissions');
        unawaited(_bootstrap());
      }
    });
    
    // Initial bootstrap
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Show only login widget (when logged out)
  void _showLoginOnly() {
    setState(() {
      _loading = false;
      _error = null;
      _allowedWidgetIds = const {'login'};
      _items.clear();
      _items.add(
        ScreenGridWidgetSpan(
          widgetId: 'login',
          col: 6,
          row: 3,
          colSpan: 12,
          rowSpan: 8,
        ),
      );
    });
  }

  /// Bootstrap - load user permissions and layout
  Future<void> _bootstrap() async {
    final user = FirebaseAuth.instance.currentUser;
    
    // If no user, show login only
    if (user == null) {
      _showLoginOnly();
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Load user permissions from Firestore
      await DashboardPermissions.loadUserPermissions(
        context: context,
        userId: user.uid,
        onAllowedWidgetIds: (allowed) {
          setState(() {
            _allowedWidgetIds = allowed;
          });
        },
      );

      debugPrint('📋 Allowed widgets: $_allowedWidgetIds');

      // Load layout from SharedPreferences
      await DashboardLayoutPersistence.loadLayout(
        prefsKey: _layoutPrefsKey,
        onLoaded: (loaded) {
          _items
            ..clear()
            ..addAll(_filterToAllowed(loaded));

          // If no items after filtering, use defaults
          if (_items.isEmpty) {
            _items.addAll(_defaultItemsForAllowed());
          }
        },
        defaultItemsBuilder: _defaultItemsForAllowed,
      );

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  /// Filter items to only show allowed widgets
  List<ScreenGridWidgetSpan> _filterToAllowed(
    List<ScreenGridWidgetSpan> input,
  ) {
    return input.where((w) => _allowedWidgetIds.contains(w.widgetId)).toList();
  }

  /// Generate default layout for allowed widgets
  List<ScreenGridWidgetSpan> _defaultItemsForAllowed() {
    // If only login is allowed, center it
    if (_allowedWidgetIds.length == 1 && _allowedWidgetIds.contains('login')) {
      return [
        ScreenGridWidgetSpan(
          widgetId: 'login',
          col: 6,
          row: 3,
          colSpan: 12,
          rowSpan: 8,
        ),
      ];
    }

    // Get all allowed widgets except login
    final ids = _allowedWidgetIds.where((id) => id != 'login').toList();
    
    if (ids.isEmpty) {
      // Fallback to login if no other widgets
      return [
        ScreenGridWidgetSpan(
          widgetId: 'login',
          col: 6,
          row: 3,
          colSpan: 12,
          rowSpan: 8,
        ),
      ];
    }

    // Generate grid layout for allowed widgets
    final out = <ScreenGridWidgetSpan>[];
    int c = 0;
    int r = 0;

    for (final id in ids) {
      out.add(
        ScreenGridWidgetSpan(
          widgetId: id,
          col: c,
          row: r,
          colSpan: 8,
          rowSpan: 6,
        ),
      );

      c += 8;
      if (c >= _grid.columns) {
        c = 0;
        r += 6;
        if (r >= _grid.rows) {
          r = 0;
        }
      }
    }

    return out;
  }

  Future<void> _saveLayout() async {
    await DashboardLayoutPersistence.saveLayout(
      prefsKey: _layoutPrefsKey,
      items: _items,
    );
  }

  void _onSnap() {
    unawaited(_saveLayout());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(color: Colors.cyan),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Dashboard error: $_error',
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }

    final wallpaper = WallpaperService.instance;

    return AnimatedBuilder(
      animation: wallpaper,
      builder: (context, _) {
        final glassBlur = wallpaper.globalGlassBlur;
        final glassOpacity = wallpaper.globalGlassOpacity;

        return Stack(
          children: [
            // Wallpaper background
            Positioned.fill(
              child: DecoratedBox(
                decoration: wallpaper.backgroundDecoration,
              ),
            ),

            // Foreground widgets
            Positioned.fill(
              child: RepaintBoundary(
                child: DashboardGrid(
                  grid: _grid,
                  items: _items,
                  onSnap: _onSnap,
                  globalBlur: glassBlur,
                  globalOpacity: glassOpacity,
                ),
              ),
            ),

            // Debug info
            if (kDebugMode)
              Positioned(
                left: 12,
                bottom: 10,
                child: IgnorePointer(
                  child: Text(
                    'Widgets: ${_items.length} | Allowed: ${_allowedWidgetIds.length}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
