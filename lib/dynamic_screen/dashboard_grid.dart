import 'package:flutter/material.dart';
import '../core/wallpaper_service.dart';
import 'model/screen_grid.dart';
import 'model/floating_widget.dart';
import 'widgets/widgets.dart'; // exposes buildGridWidget

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth / grid.columns;
        final cellH = constraints.maxHeight / grid.rows;

        final visibleItems = items;

        return Stack(
          children: visibleItems.map((item) {
            final left = cellW * item.col;
            final top = cellH * item.row;
            final widthPx = cellW * item.colSpan;
            final heightPx = cellH * item.rowSpan;

            return buildGridWidget(
              item: item,
              cellW: cellW,
              cellH: cellH,
              maxW: constraints.maxWidth,
              maxH: constraints.maxHeight,
              initialLeft: left,
              initialTop: top,
              initialWidthPx: widthPx,
              initialHeightPx: heightPx,
              globalBlur: WallpaperService.instance.globalGlassBlur,
              globalOpacity: WallpaperService.instance.globalGlassOpacity,
              globalTint: const Color(0xFFFFFFFF),
              onSnap: onSnap,
            );
          }).toList(),
        );
      },
    );
  }
}
