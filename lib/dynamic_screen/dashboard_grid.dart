// lib/dynamic_screen/dashboard_grid.dart

import 'package:flutter/material.dart';

import '../core/wallpaper_service.dart';
import 'model/screen_grid.dart';
import 'widgets/widgets.dart';

class DashboardGrid extends StatelessWidget {
  final ScreenGridConfig grid;
  final List<ScreenGridWidgetSpan> items;
  final VoidCallback onSnap;

  const DashboardGrid({
    super.key,
    required this.grid,
    required this.items,
    required this.onSnap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellW = constraints.maxWidth / grid.columns;
          final cellH = constraints.maxHeight / grid.rows;

          final globalBlur = WallpaperService.instance.globalGlassBlur;
          final globalOpacity = WallpaperService.instance.globalGlassOpacity;
          const globalTint = Color(0xFFFFFFFF);

          return ClipRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                for (final item in items)
                  // IMPORTANT: do NOT wrap this in another Positioned or RepaintBoundary.
                  buildGridWidget(
                    item: item,
                    cellW: cellW,
                    cellH: cellH,
                    maxW: constraints.maxWidth,
                    maxH: constraints.maxHeight,
                    initialLeft: cellW * item.col,
                    initialTop: cellH * item.row,
                    initialWidthPx: cellW * item.colSpan,
                    initialHeightPx: cellH * item.rowSpan,
                    globalBlur: globalBlur,
                    globalOpacity: globalOpacity,
                    globalTint: globalTint,
                    onSnap: onSnap,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
