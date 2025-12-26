import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:walld_flutter/dynamic_screen/dashboard_layout_persistence.dart';// show ScreenGridWidgetSpan, ScreenGridConfig
import 'package:walld_flutter/dynamic_screen/model/screen_grid.dart';
import '../core/wallpaper_service.dart';
import 'dashboard_grid.dart';
import 'widget_manifest.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  // DEBUG: Track instances to find duplicates
  static int _instanceCounter = 0;
  final int _instanceNumber;
  final String _instanceId = DateTime.now().millisecondsSinceEpoch.toString();

  DashboardScreenState() : _instanceNumber = ++_instanceCounter {
    debugPrint('🔷 DashboardScreen INSTANCE #$_instanceNumber CREATED (ID: $_instanceId)');
  }

  static const ScreenGridConfig grid = ScreenGridConfig(columns: 24, rows: 14);
  
  bool loading = true;
  String? error;
  Set<String> allowedWidgetIds = const {'login'};
  final List<ScreenGridWidgetSpan> items = [];
  
  StreamSubscription<User?>? authSubscription;
  String get userId => FirebaseAuth.instance.currentUser?.uid ?? 'anon';
  String get layoutPrefsKey => 'dashboard_layout_v1_$userId';

  @override
  void initState() {
    super.initState();
    debugPrint('🔷 DashboardScreen #$_instanceNumber - initState() - Setting up auth listener');

    // Listen to auth state changes
    authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      debugPrint('🔷 DashboardScreen #$_instanceNumber AUTH CHANGED: user=${user?.uid}');
      
      if (user == null) {
        debugPrint('🔷 DashboardScreen #$_instanceNumber - User logged out, showing login only');
        showLoginOnly();
      } else {
        debugPrint('🔷 DashboardScreen #$_instanceNumber - User logged in, calling bootstrap()');
        unawaited(bootstrap());
      }
    });
    
    // Initial load
    debugPrint('🔷 DashboardScreen #$_instanceNumber - Initial bootstrap call');
    unawaited(bootstrap());
  }

  @override
  void dispose() {
    debugPrint('🔷 DashboardScreen #$_instanceNumber DISPOSED');
    authSubscription?.cancel();
    super.dispose();
  }

  void showLoginOnly() {
    setState(() {
      loading = false;
      error = null;
      allowedWidgetIds = const {'login'};
      items.clear();
      items.add(ScreenGridWidgetSpan(
        widgetId: 'login',
        col: 6,
        row: 3,
        colSpan: 12,
        rowSpan: 8,
      ));
    });
  }

  Future<void> bootstrap() async {
    debugPrint('🔷🔷🔷 BOOTSTRAP START - DashboardScreen #$_instanceNumber');
    
    setState(() {
      loading = true;
      error = null;
    });

    try {
      // 1. Get all widgets from manifest
      allowedWidgetIds = widgetManifest
          .map((w) => w['id'] as String)
          .toSet();

      // 2. Load layout from persistence
      await DashboardLayoutPersistence.loadLayout(
        prefsKey: layoutPrefsKey,
        onLoaded: (loaded) {
          debugPrint('🔷 DashboardScreen #$_instanceNumber - Layout loaded from disk: ${loaded.length} widgets');
          items
            ..clear()
            ..addAll(filterToAllowed(loaded));
        },
        defaultItemsBuilder: defaultItemsForAllowed,
      );

      // 3. Fallback if empty
      if (items.isEmpty) {
        debugPrint('🔷 DashboardScreen #$_instanceNumber - Layout empty, using defaults');
        items.addAll(defaultItemsForAllowed());
      }

      if (!mounted) {
        debugPrint('🔷 DashboardScreen #$_instanceNumber - Widget not mounted after bootstrap, aborting');
        return;
      }

      setState(() {
        loading = false;
      });
      
      debugPrint('🔷🔷🔷 BOOTSTRAP END - DashboardScreen #$_instanceNumber - ${items.length} widgets loaded');
      
    } catch (e) {
      debugPrint('❌ DashboardScreen #$_instanceNumber - Bootstrap error: $e');
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  List<ScreenGridWidgetSpan> filterToAllowed(List<ScreenGridWidgetSpan> input) {
    return input.where((w) => allowedWidgetIds.contains(w.widgetId)).toList();
  }

  List<ScreenGridWidgetSpan> defaultItemsForAllowed() {
    if (allowedWidgetIds.length == 1 && allowedWidgetIds.contains('login')) {
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
    
    final ids = allowedWidgetIds.where((id) => id != 'login').toList();
    if (ids.isEmpty) {
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

    final out = <ScreenGridWidgetSpan>[];
    int c = 0;
    int r = 0;

    for (final id in ids) {
      out.add(ScreenGridWidgetSpan(
        widgetId: id,
        col: c,
        row: r,
        colSpan: 8,
        rowSpan: 6,
      ));
      c += 8;
      if (c >= grid.columns || c + 8 > grid.columns) {
        c = 0;
        r += 6;
      }
      if (r >= grid.rows) {
        r = 0; 
      }
    }
    return out;
  }

  Future<void> saveLayout() async {
    await DashboardLayoutPersistence.saveLayout(
      prefsKey: layoutPrefsKey,
      items: items,
    );
  }

  void onSnap() {
    unawaited(saveLayout());
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(color: Colors.cyan),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Text(
          'Dashboard error: $error',
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
                  grid: grid,
                  items: items,
                  onSnap: onSnap,
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
                    'Widgets: ${items.length} | Allowed: ${allowedWidgetIds.length} | Instance: #$_instanceNumber',
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
