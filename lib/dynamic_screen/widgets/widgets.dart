// lib/dynamic_screen/widgets/widgets.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/glass_container.dart';
import '../../core/wallpaper_service.dart';
import '../model/screen_grid.dart';
import '../widget_factory.dart';

/// Used by DashboardGrid to build a draggable/resizable widget tile.
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

class _LiveLayout {
  final double left;
  final double top;
  final double width;
  final double height;

  const _LiveLayout({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  _LiveLayout copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
  }) {
    return _LiveLayout(
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}

/// Draggable + resizable wrapper used by the dashboard grid.
///
/// Performance fixes:
/// - No setState() on each pointer update (uses ValueNotifier for layout).
/// - While dragging/resizing, renders a cheap outline placeholder (no blur/shadow).
/// - Cached inner widget content so it does not rebuild while moving.
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
  // Cached widget content
  Widget? _cachedContent;
  String? _cachedWidgetId;

  // Live layout updated without setState()
  late final ValueNotifier<_LiveLayout> _layoutVN;

  // Interaction state (dragging/resizing)
  late final ValueNotifier<bool> _interactingVN;

  // Drag state
  Offset? _dragStartGlobal;
  _LiveLayout? _dragStartLayout;

  // Resize state
  Offset? _resizeStartGlobal;
  _LiveLayout? _resizeStartLayout;

  static const double _minSpan = 2; // min 2x2 cells
  static const double _handleSize = 18;

  bool get _isDragging => _dragStartGlobal != null;
  bool get _isResizing => _resizeStartGlobal != null;
  bool get _isInteracting => _isDragging || _isResizing;

  @override
  void initState() {
    super.initState();

    _layoutVN = ValueNotifier<_LiveLayout>(
      _LiveLayout(
        left: widget.initialLeft,
        top: widget.initialTop,
        width: widget.initialWidthPx,
        height: widget.initialHeightPx,
      ),
    );

    _interactingVN = ValueNotifier<bool>(false);

    _buildCachedContent();
  }

  @override
  void didUpdateWidget(covariant FreeDragResizeItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.item.widgetId != widget.item.widgetId) {
      _buildCachedContent();
    }

    if (!_isInteracting) {
      _layoutVN.value = _LiveLayout(
        left: (widget.item.col * widget.cellW)
            .clamp(0.0, math.max(0.0, widget.maxW - widget.cellW)),
        top: (widget.item.row * widget.cellH)
            .clamp(0.0, math.max(0.0, widget.maxH - widget.cellH)),
        width: (widget.item.colSpan * widget.cellW)
            .clamp(widget.cellW * _minSpan, widget.maxW),
        height: (widget.item.rowSpan * widget.cellH)
            .clamp(widget.cellH * _minSpan, widget.maxH),
      );
    }
  }

  @override
  void dispose() {
    _layoutVN.dispose();
    _interactingVN.dispose();
    super.dispose();
  }

  void _buildCachedContent() {
    _cachedWidgetId = widget.item.widgetId;
    _cachedContent = RepaintBoundary(
      child: DynamicWidgetFactory.create(widget.item.widgetId),
    );
  }

  double _clampLeft(double left, double width) {
    final maxLeft = math.max(0.0, widget.maxW - width);
    return left.clamp(0.0, maxLeft);
  }

  double _clampTop(double top, double height) {
    final maxTop = math.max(0.0, widget.maxH - height);
    return top.clamp(0.0, maxTop);
  }

  double _clampWidth(double width) {
    final minW = widget.cellW * _minSpan;
    return width.clamp(minW, widget.maxW);
  }

  double _clampHeight(double height) {
    final minH = widget.cellH * _minSpan;
    return height.clamp(minH, widget.maxH);
  }

  void _setInteracting(bool v) {
    if (_interactingVN.value != v) _interactingVN.value = v;
  }

  // Drag handlers
  void _onDragStart(DragStartDetails d) {
    _dragStartGlobal = d.globalPosition;
    _dragStartLayout = _layoutVN.value;
    _setInteracting(true);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_dragStartGlobal == null || _dragStartLayout == null) return;

    final delta = d.globalPosition - _dragStartGlobal!;
    final start = _dragStartLayout!;

    final newLeft = _clampLeft(start.left + delta.dx, start.width);
    final newTop = _clampTop(start.top + delta.dy, start.height);

    _layoutVN.value = start.copyWith(left: newLeft, top: newTop);
  }

  void _onDragEnd([DragEndDetails? _]) {
    _dragStartGlobal = null;
    _dragStartLayout = null;
    _snapToGridAndPersist();
  }

  // Resize handlers
  void _onResizeStart(DragStartDetails d) {
    _resizeStartGlobal = d.globalPosition;
    _resizeStartLayout = _layoutVN.value;
    _setInteracting(true);
  }

  void _onResizeUpdate(DragUpdateDetails d) {
    if (_resizeStartGlobal == null || _resizeStartLayout == null) return;

    final delta = d.globalPosition - _resizeStartGlobal!;
    final start = _resizeStartLayout!;

    final newWidth = _clampWidth(start.width + delta.dx);
    final newHeight = _clampHeight(start.height + delta.dy);

    final newLeft = _clampLeft(start.left, newWidth);
    final newTop = _clampTop(start.top, newHeight);

    _layoutVN.value = start.copyWith(
      left: newLeft,
      top: newTop,
      width: newWidth,
      height: newHeight,
    );
  }

  void _onResizeEnd([DragEndDetails? _]) {
    _resizeStartGlobal = null;
    _resizeStartLayout = null;
    _snapToGridAndPersist();
  }

  void _snapToGridAndPersist() {
    final l = _layoutVN.value;

    int col = (l.left / widget.cellW).round();
    int row = (l.top / widget.cellH).round();
    int colSpan = (l.width / widget.cellW).round();
    int rowSpan = (l.height / widget.cellH).round();

    colSpan = colSpan.clamp(_minSpan.toInt(), widget.gridColumns);
    rowSpan = rowSpan.clamp(_minSpan.toInt(), widget.gridRows);

    col = col.clamp(0, widget.gridColumns - colSpan);
    row = row.clamp(0, widget.gridRows - rowSpan);

    widget.item
      ..col = col
      ..row = row
      ..colSpan = colSpan
      ..rowSpan = rowSpan;

    _layoutVN.value = _LiveLayout(
      left: col * widget.cellW,
      top: row * widget.cellH,
      width: colSpan * widget.cellW,
      height: rowSpan * widget.cellH,
    );

    _setInteracting(false);
    widget.onSnap();
  }

  // Outline-only placeholder used while interacting
  Widget _buildCheapPlaceholder() {
    final borderColor = Colors.cyanAccent.withOpacity(0.55);
    final glowColor = Colors.cyanAccent.withOpacity(0.12);

    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: glowColor,
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildFullGlassCard(Widget content) {
    // Global blur is applied in WorkspaceShell; disable per-widget blur.
    return GlassContainer(
      blur: 0.0,
      opacity: widget.globalOpacity,
      tint: widget.globalTint,
      borderRadius: BorderRadius.circular(24),
      blurMode: GlassBlurMode.none,
      qualityMode: GlassQualityMode.auto,
      isInteracting: _isInteracting,
      disableShadows: false,
      padding: EdgeInsets.zero,
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _cachedContent ?? const SizedBox.shrink();

    // Only this tile rebuilds per tick; expensive inner content is cached.
    return ValueListenableBuilder<_LiveLayout>(
      valueListenable: _layoutVN,
      builder: (context, l, _) {
        return Positioned(
          left: l.left,
          top: l.top,
          width: l.width,
          height: l.height,

          // IMPORTANT: Positioned is the direct child of the Stack in DashboardGrid.
          child: RepaintBoundary(
            child: Stack(
              children: [
                // Card surface: placeholder vs full glass
                Positioned.fill(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _interactingVN,
                    builder: (context, interacting, __) {
                      if (interacting) {
                        return _buildCheapPlaceholder();
                      }
                      return _buildFullGlassCard(content);
                    },
                  ),
                ),

                // Drag overlay
                Positioned.fill(
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: _onDragStart,
                      onPanUpdate: _onDragUpdate,
                      onPanEnd: _onDragEnd,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),

                // Resize handle (bottom-right)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    child: GestureDetector(
                      onPanStart: _onResizeStart,
                      onPanUpdate: _onResizeUpdate,
                      onPanEnd: _onResizeEnd,
                      child: Container(
                        width: _handleSize,
                        height: _handleSize,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withOpacity(_isInteracting ? 0.10 : 0.14),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.open_in_full,
                          size: 12,
                          color: Colors.white.withOpacity(0.65),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
