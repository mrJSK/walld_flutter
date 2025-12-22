import 'package:flutter/material.dart';
import 'widget_factory.dart';
import 'widget_manifest.dart';
import 'model/screen_grid.dart';

class DashboardPanel extends StatefulWidget {
  const DashboardPanel({Key? key}) : super(key: key);

  @override
  State<DashboardPanel> createState() => _DashboardPanelState();
}

class _DashboardPanelState extends State<DashboardPanel> {
  // Global screen grid
  final ScreenGridConfig _grid = const ScreenGridConfig(
    columns: 24,
    rows: 14,
  );

  late List<ScreenGridWidgetSpan> _items;

  @override
  void initState() {
    super.initState();

    // Initial placement in screen grid units
    _items = [
      ScreenGridWidgetSpan(
        widgetId: 'create_task',
        col: 1,
        row: 2,
        colSpan: 10,
        rowSpan: 4,
      ),
      ScreenGridWidgetSpan(
        widgetId: 'view_assigned_tasks',
        col: 13,
        row: 2,
        colSpan: 10,
        rowSpan: 4,
      ),
      ScreenGridWidgetSpan(
        widgetId: 'view_all_tasks',
        col: 1,
        row: 8,
        colSpan: 10,
        rowSpan: 4,
      ),
      ScreenGridWidgetSpan(
        widgetId: 'complete_task',
        col: 13,
        row: 8,
        colSpan: 10,
        rowSpan: 4,
      ),
    ];
  }

  void toggleWidget(String widgetId) {
    final index = _items.indexWhere((w) => w.widgetId == widgetId);
    if (index != -1) {
      setState(() => _items.removeAt(index));
    } else {
      // default placement for newly enabled widget
      setState(() {
        _items.add(
          ScreenGridWidgetSpan(
            widgetId: widgetId,
            col: 1,
            row: 2,
            colSpan: 8,
            rowSpan: 4,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, root) {
        final width = root.maxWidth;
        final height = root.maxHeight;
        final shortest = width < height ? width : height;

        final double scale =
            shortest < 700 ? 0.7 : (shortest < 1100 ? 0.9 : 1.1);

        final horizontalPadding = 24.0 * scale;
        final verticalPadding = 12.0 * scale;
        final mainSpacing = 12.0 * scale;
        final topBarHeight = 32.0 * scale;
        final chipHeight = 32.0 * scale;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF05040A), Color(0xFF151827)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  children: [
                    // TOP BAR
                    SizedBox(
                      height: topBarHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0x660A0A12),
                          borderRadius:
                              BorderRadius.circular(topBarHeight / 2),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 14.0 * scale),
                        child: Row(
                          children: [
                            Icon(Icons.blur_on_rounded,
                                size: 14 * scale, color: Colors.cyan),
                            SizedBox(width: 6 * scale),
                            Text(
                              'Wall‑D • Dynamic Screen',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12 * scale,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.cloud_done,
                                size: 13 * scale,
                                color: Colors.greenAccent),
                            SizedBox(width: 4 * scale),
                            Text(
                              'default_tenant',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11 * scale,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: mainSpacing),

                    // TOGGLE CHIPS
                    SizedBox(
                      height: chipHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widgetManifest.length,
                        separatorBuilder: (_, __) => SizedBox(width: 6 * scale),
                        itemBuilder: (context, index) {
                          final w = widgetManifest[index];
                          final id = w['id'] as String;
                          final name = w['name'] as String;
                          final selected = _items.any((i) => i.widgetId == id);

                          return ChoiceChip(
                            label: Text(name),
                            selected: selected,
                            onSelected: (_) => toggleWidget(id),
                            selectedColor: Colors.cyan.withOpacity(0.15),
                            labelStyle: TextStyle(
                              color:
                                  selected ? Colors.cyanAccent : Colors.white70,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontSize: 11 * scale,
                            ),
                            shape: StadiumBorder(
                              side: BorderSide(
                                color: selected
                                    ? Colors.cyanAccent.withOpacity(0.6)
                                    : Colors.white24,
                              ),
                            ),
                            backgroundColor: const Color(0xFF11111C),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: mainSpacing),

                    // MAIN AREA
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final maxW = constraints.maxWidth;
                          final maxH = constraints.maxHeight;

                          final cellW = maxW / _grid.columns;
                          final cellH = maxH / _grid.rows;

                          return Stack(
                            children: _items
                                .map(
                                  (item) => _buildGridWidget(
                                    item: item,
                                    cellW: cellW,
                                    cellH: cellH,
                                    maxW: maxW,
                                    maxH: maxH,
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridWidget({
    required ScreenGridWidgetSpan item,
    required double cellW,
    required double cellH,
    required double maxW,
    required double maxH,
  }) {
    final left = (item.col * cellW).clamp(0.0, maxW - cellW);
    final top = (item.row * cellH).clamp(0.0, maxH - cellH);

    final widthPx = (item.colSpan * cellW).clamp(cellW * 2, maxW);
    final heightPx = (item.rowSpan * cellH).clamp(cellH * 2, maxH);

    return _FreeDragResizeItem(
      key: ValueKey(item.widgetId),
      item: item,
      gridColumns: _grid.columns,
      gridRows: _grid.rows,
      cellW: cellW,
      cellH: cellH,
      maxW: maxW,
      maxH: maxH,
      initialLeft: left,
      initialTop: top,
      initialWidthPx: widthPx,
      initialHeightPx: heightPx,
    );
  }
}

class _FreeDragResizeItem extends StatefulWidget {
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

  const _FreeDragResizeItem({
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
  });

  @override
  State<_FreeDragResizeItem> createState() => _FreeDragResizeItemState();
}

class _FreeDragResizeItemState extends State<_FreeDragResizeItem> {
  // live (pixel) rect during interaction
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
  void didUpdateWidget(covariant _FreeDragResizeItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If parent updates the grid model (e.g., external load), sync pixels
    // (but don't fight while user is dragging/resizing).
    if (!isInteracting) {
      final newLeft = (widget.item.col * widget.cellW)
          .clamp(0.0, widget.maxW - widget.cellW);
      final newTop = (widget.item.row * widget.cellH)
          .clamp(0.0, widget.maxH - widget.cellH);

      final newW =
          (widget.item.colSpan * widget.cellW).clamp(widget.cellW * 2, widget.maxW);
      final newH =
          (widget.item.rowSpan * widget.cellH).clamp(widget.cellH * 2, widget.maxH);

      left = newLeft;
      top = newTop;
      widthPx = newW;
      heightPx = newH;
    }
  }

  void _snapToGridAndPersist() {
    // snap pixels -> grid units
    int col = (left / widget.cellW).round();
    int row = (top / widget.cellH).round();
    int colSpan = (widthPx / widget.cellW).round();
    int rowSpan = (heightPx / widget.cellH).round();

    // enforce minimum size
    colSpan = colSpan.clamp(2, widget.gridColumns) as int;
    rowSpan = rowSpan.clamp(2, widget.gridRows) as int;

    // keep inside grid bounds
    col = col.clamp(0, widget.gridColumns - colSpan) as int;
    row = row.clamp(0, widget.gridRows - rowSpan) as int;

    // persist into the original model
    widget.item
      ..col = col
      ..row = row
      ..colSpan = colSpan
      ..rowSpan = rowSpan;

    // snap pixels exactly to grid
    setState(() {
      left = col * widget.cellW;
      top = row * widget.cellH;
      widthPx = colSpan * widget.cellW;
      heightPx = rowSpan * widget.cellH;
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = WidgetFactory.createWidget(widget.item.widgetId);

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
              local.dx > (widthPx - hitHandleSize) &&
              local.dy > (heightPx - hitHandleSize);

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

              // resize freely in pixels
              widthPx = (widthPx + delta.dx)
                  .clamp(widget.cellW * 2, widget.maxW - left);
              heightPx = (heightPx + delta.dy)
                  .clamp(widget.cellH * 2, widget.maxH - top);

              resizeLastGlobal = details.globalPosition;
              return;
            }

            if (dragLastGlobal != null) {
              final delta = details.globalPosition - dragLastGlobal!;

              // drag freely in pixels
              left = (left + delta.dx).clamp(0.0, widget.maxW - widthPx);
              top = (top + delta.dy).clamp(0.0, widget.maxH - heightPx);

              dragLastGlobal = details.globalPosition;
              return;
            }
          });
        },
        onPanEnd: (_) {
          dragLastGlobal = null;
          resizeLastGlobal = null;
          _snapToGridAndPersist();
        },
        onPanCancel: () {
          dragLastGlobal = null;
          resizeLastGlobal = null;
          _snapToGridAndPersist();
        },
        child: Stack(
          children: [
            Positioned.fill(child: child),

            // resize handle (visual)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.cyanAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
