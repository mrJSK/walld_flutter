import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:walld_flutter/dynamic_screen/dashboard_layout_persistence.dart';
import 'package:walld_flutter/dynamic_screen/model/screen_grid.dart'
    show ScreenGridWidgetSpan, ScreenGridConfig;

import 'widget_manifest.dart';
import '../core/wallpaper_service.dart';
// import 'dashboard_drawer.dart';
import 'dashboard_grid.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  static const ScreenGridConfig grid = ScreenGridConfig(columns: 24, rows: 14);

  bool loading = true;
  String? error;

  Set<String> allowedWidgetIds = const {'login'};
  final List<ScreenGridWidgetSpan> items = <ScreenGridWidgetSpan>[];

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? 'anon';
  String get _layoutPrefsKey => 'dashboard_layout_v1_$_userId';

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      // 1) Allow ALL widgets, no per-user filtering.
      allowedWidgetIds = widgetManifest
          .map((w) => w['id'] as String)
          .toSet();

      // 2) Layout
      await DashboardLayoutPersistence.loadLayout(
        prefsKey: _layoutPrefsKey,
        onLoaded: (loaded) {
          items
            ..clear()
            ..addAll(_filterToAllowed(loaded));
          if (items.isEmpty) {
            items.addAll(_defaultItemsForAllowed());
          }
        },
        defaultItemsBuilder: _defaultItemsForAllowed,
      );

      if (!mounted) return;
      setState(() => loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  List<ScreenGridWidgetSpan> _filterToAllowed(
    List<ScreenGridWidgetSpan> input,
  ) {
    return input.where((w) => allowedWidgetIds.contains(w.widgetId)).toList();
  }

  List<ScreenGridWidgetSpan> _defaultItemsForAllowed() {
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
      if (c >= grid.columns) {
        c = 0;
        r += 6;
      }
      if (r >= grid.rows) {
        r = 0;
      }
    }
    return out;
  }

  Future<void> _saveLayout() async {
    await DashboardLayoutPersistence.saveLayout(
      prefsKey: _layoutPrefsKey,
      items: items,
    );
  }

  void _onSnap() {
    unawaited(_saveLayout());
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

  return AnimatedBuilder(
    animation: WallpaperService.instance,
    builder: (context, _) {
      return Stack(
        children: [
          // Only the grid (and optional debug label) remain.
          Positioned.fill(
            child: RepaintBoundary(
              child: DashboardGrid(
                grid: grid,
                items: items,
                onSnap: _onSnap,
              ),
            ),
          ),
          if (kDebugMode)
            Positioned(
              left: 12,
              bottom: 10,
              child: IgnorePointer(
                child: Text(
                  'Widgets: ${items.length} | Allowed: ${allowedWidgetIds.length}',
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
