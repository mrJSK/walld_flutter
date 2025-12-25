import 'package:flutter/material.dart';

import '../../core/glass_container.dart';
import '../../core/wallpaper_service.dart';
import 'model/floating_widget.dart';
import 'widget_factory.dart';
import 'model/screen_grid.dart';

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
    gridColumns: 24,
    gridRows: 14,
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

  // 🔥 FIX: Cache widget content to avoid rebuilding on every frame
  Widget? _cachedContent;
  String? _cachedWidgetId;

  bool get isInteracting => dragLastGlobal != null || resizeLastGlobal != null;

  @override
  void initState() {
    super.initState();
    left = widget.initialLeft;
    top = widget.initialTop;
    widthPx = widget.initialWidthPx;
    heightPx = widget.initialHeightPx;
    
    // Cache the widget content
    _buildCachedContent();
  }

  @override
  void didUpdateWidget(covariant FreeDragResizeItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Rebuild cached content if widget ID changed
    if (oldWidget.item.widgetId != widget.item.widgetId) {
      _buildCachedContent();
    }
    
    if (!isInteracting) {
      left = (widget.item.col * widget.cellW).clamp(0.0, widget.maxW - widget.cellW);
      top = (widget.item.row * widget.cellH).clamp(0.0, widget.maxH - widget.cellH);
      widthPx = (widget.item.colSpan * widget.cellW)
          .clamp(widget.cellW * 2, widget.maxW);
      heightPx = (widget.item.rowSpan * widget.cellH)
          .clamp(widget.cellH * 2, widget.maxH);
    }
  }

  // 🔥 FIX: Build and cache widget content once
  void _buildCachedContent() {
    _cachedWidgetId = widget.item.widgetId;
    _cachedContent = RepaintBoundary(
      child: DynamicWidgetFactory.create(widget.item.widgetId),
    );
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
    // 🔥 FIX: Use cached content instead of rebuilding every frame
    final content = _cachedContent ?? const SizedBox.shrink();

    // 🔥 FIX: Reduce blur during interaction for better performance
    final effectiveBlur = isInteracting 
        ? (widget.globalBlur * 0.5).clamp(0.0, 8.0)  // Half blur when dragging
        : widget.globalBlur;

    final glassCard = GlassContainer(
      blur: effectiveBlur,
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
          
          setState(() {
            if (isResize) {
              resizeLastGlobal = details.globalPosition;
            } else {
              dragLastGlobal = details.globalPosition;
            }
          });
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
          setState(() {
            dragLastGlobal = null;
            resizeLastGlobal = null;
          });
          snapToGridAndPersist();
        },
        onPanCancel: () {
          setState(() {
            dragLastGlobal = null;
            resizeLastGlobal = null;
          });
          snapToGridAndPersist();
        },
        child: Stack(
          children: [
            // 🔥 FIX: Isolate glass card repaints
            Positioned.fill(
              child: RepaintBoundary(
                child: glassCard,
              ),
            ),
            
            // Resize handle
            if (!isInteracting || resizeLastGlobal != null)
              Positioned(
                right: 4,
                bottom: 4,
                child: _ResizeHandle(
                  isActive: resizeLastGlobal != null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 🔥 FIX: Extract resize handle to prevent rebuilds
class _ResizeHandle extends StatelessWidget {
  final bool isActive;

  const _ResizeHandle({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeDownRight,
      child: Container(
        width: 24.0,
        height: 24.0,
        alignment: Alignment.bottomRight,
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: isActive ? 16 : 14,
          height: isActive ? 16 : 14,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? Colors.cyanAccent : Colors.cyanAccent.withOpacity(0.8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
