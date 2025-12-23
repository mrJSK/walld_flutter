import 'package:flutter/material.dart';

import '../../core/glass_container.dart';
import '../../core/wallpaper_service.dart';
import '../model/screen_grid.dart';
import '../model/floating_widget.dart';
import '../widget_factory.dart';

Widget buildGridWidget({
  required ScreenGridWidgetSpan item,
  required double cellW,
  required double cellH,
  required double maxW,
  required double maxH,
  required double initialLeft,
  required double initialTop,
  required double initialWidthPx,
  required double initialHeightPx,
  required double globalBlur,
  required double globalOpacity,
  required Color globalTint,
  required VoidCallback onSnap,
}) {
  return FreeDragResizeItem(
    key: ValueKey(item.widgetId),
    item: item,
    gridColumns: 24, // the grid.columns value used previously
    gridRows: 14,    // the grid.rows value used previously
    cellW: cellW,
    cellH: cellH,
    maxW: maxW,
    maxH: maxH,
    initialLeft: initialLeft,
    initialTop: initialTop,
    initialWidthPx: initialWidthPx,
    initialHeightPx: initialHeightPx,
    globalBlur: globalBlur,
    globalOpacity: globalOpacity,
    globalTint: globalTint,
    onSnap: onSnap,
  );
}

/// Draggable + resizable wrapper used by the dashboard grid.
class FreeDragResizeItem extends StatefulWidget {
  final ScreenGridWidgetSpan item;
  final int gridColumns;
  final int gridRows;

  final double cellW;
  final double cellH;
  final double maxW;
  final double maxH;

  final double initialLeft;
  final double initialTop;
  final double initialWidthPx;
  final double initialHeightPx;

  final double globalBlur;
  final double globalOpacity;
  final Color globalTint;
  final VoidCallback onSnap;

  const FreeDragResizeItem({
    super.key,
    required this.item,
    required this.gridColumns,
    required this.gridRows,
    required this.cellW,
    required this.cellH,
    required this.maxW,
    required this.maxH,
    required this.initialLeft,
    required this.initialTop,
    required this.initialWidthPx,
    required this.initialHeightPx,
    required this.globalBlur,
    required this.globalOpacity,
    required this.globalTint,
    required this.onSnap,
  });

  @override
  State<FreeDragResizeItem> createState() => _FreeDragResizeItemState();
}

class _FreeDragResizeItemState extends State<FreeDragResizeItem> {
  late double left;
  late double top;
  late double widthPx;
  late double heightPx;

  Offset? dragLastGlobal;
  Offset? resizeLastGlobal;

  bool get isInteracting => dragLastGlobal != null || resizeLastGlobal != null;

  @override
  void initState() {
    super.initState();
    left = widget.initialLeft;
    top = widget.initialTop;
    widthPx = widget.initialWidthPx;
    heightPx = widget.initialHeightPx;
  }

  @override
  void didUpdateWidget(covariant FreeDragResizeItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isInteracting) {
      left = (widget.item.col * widget.cellW).clamp(0.0, widget.maxW - widget.cellW);
      top = (widget.item.row * widget.cellH).clamp(0.0, widget.maxH - widget.cellH);
      widthPx = (widget.item.colSpan * widget.cellW)
          .clamp(widget.cellW * 2, widget.maxW);
      heightPx = (widget.item.rowSpan * widget.cellH)
          .clamp(widget.cellH * 2, widget.maxH);
    }
  }

  void snapToGridAndPersist() {
    int col = (left / widget.cellW).round();
    int row = (top / widget.cellH).round();
    int colSpan = (widthPx / widget.cellW).round();
    int rowSpan = (heightPx / widget.cellH).round();

    colSpan = colSpan.clamp(2, widget.gridColumns);
    rowSpan = rowSpan.clamp(2, widget.gridRows);

    col = col.clamp(0, widget.gridColumns - colSpan);
    row = row.clamp(0, widget.gridRows - rowSpan);

    widget.item
      ..col = col
      ..row = row
      ..colSpan = colSpan
      ..rowSpan = rowSpan;

    setState(() {
      left = col * widget.cellW;
      top = row * widget.cellH;
      widthPx = colSpan * widget.cellW;
      heightPx = rowSpan * widget.cellH;
    });

    widget.onSnap();
  }

  @override
  Widget build(BuildContext context) {
    final content = WidgetFactory.createWidget(widget.item.widgetId);

    final glassCard = GlassContainer(
      blur: widget.globalBlur,
      opacity: widget.globalOpacity,
      tint: widget.globalTint,
      borderRadius: BorderRadius.circular(24),
      child: content,
    );

    const hitHandleSize = 24.0;

    return Positioned(
      left: left.clamp(0.0, widget.maxW - widthPx),
      top: top.clamp(0.0, widget.maxH - heightPx),
      width: widthPx.clamp(widget.cellW * 2, widget.maxW),
      height: heightPx.clamp(widget.cellH * 2, widget.maxH),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          final local = details.localPosition;
          final isResize =
              local.dx > widthPx - hitHandleSize && local.dy > heightPx - hitHandleSize;
          if (isResize) {
            resizeLastGlobal = details.globalPosition;
          } else {
            dragLastGlobal = details.globalPosition;
          }
        },
        onPanUpdate: (details) {
          setState(() {
            if (resizeLastGlobal != null) {
              final delta = details.globalPosition - resizeLastGlobal!;
              widthPx = (widthPx + delta.dx)
                  .clamp(widget.cellW * 2, widget.maxW - left);
              heightPx = (heightPx + delta.dy)
                  .clamp(widget.cellH * 2, widget.maxH - top);
              resizeLastGlobal = details.globalPosition;
            } else if (dragLastGlobal != null) {
              final delta = details.globalPosition - dragLastGlobal!;
              left = (left + delta.dx).clamp(0.0, widget.maxW - widthPx);
              top = (top + delta.dy).clamp(0.0, widget.maxH - heightPx);
              dragLastGlobal = details.globalPosition;
            }
          });
        },
        onPanEnd: (_) {
          dragLastGlobal = null;
          resizeLastGlobal = null;
          snapToGridAndPersist();
        },
        onPanCancel: () {
          dragLastGlobal = null;
          resizeLastGlobal = null;
          snapToGridAndPersist();
        },
        child: Stack(
          children: [
            Positioned.fill(child: glassCard),
            // Resize handle
            Positioned(
              right: 4,
              bottom: 4,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeDownRight,
                child: Container(
                  width: hitHandleSize,
                  height: hitHandleSize,
                  alignment: Alignment.bottomRight,
                  color: Colors.transparent,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.cyanAccent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
