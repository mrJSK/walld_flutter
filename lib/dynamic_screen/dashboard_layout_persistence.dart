import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/screen_grid.dart';

class DashboardLayoutPersistence {
  static Future<void> loadLayout({
    required String prefsKey,
    required void Function(List<ScreenGridWidgetSpan>) onLoaded,
    required List<ScreenGridWidgetSpan> Function() defaultItemsBuilder,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(prefsKey);
    if (jsonString == null) {
      debugPrint('[LAYOUT] No saved layout, using defaults');
      onLoaded(defaultItemsBuilder());
      return;
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      final loaded = decoded.map((e) {
        final m = e as Map<String, dynamic>;
        return ScreenGridWidgetSpan(
          widgetId: m['id'] as String,
          col: m['col'] as int,
          row: m['row'] as int,
          colSpan: m['colSpan'] as int,
          rowSpan: m['rowSpan'] as int,
        );
      }).toList();
      debugPrint('[LAYOUT] Loaded ${loaded.length} items');
      onLoaded(loaded);
    } catch (e) {
      debugPrint('[LAYOUT] Failed to parse layout: $e');
      onLoaded(defaultItemsBuilder());
    }
  }

  static Future<void> saveLayout({
    required String prefsKey,
    required List<ScreenGridWidgetSpan> items,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = items
        .map((w) => {
              'id': w.widgetId,
              'col': w.col,
              'row': w.row,
              'colSpan': w.colSpan,
              'rowSpan': w.rowSpan,
            })
        .toList();
    await prefs.setString(prefsKey, jsonEncode(data));
    debugPrint('[LAYOUT] Saved layout with ${items.length} items');
  }
}
