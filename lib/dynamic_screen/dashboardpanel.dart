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
        colSpan: 10, // uses 10 out of 24 columns
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
                          border:
                              Border.all(color: const Color(0x33FFFFFF)),
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
                        separatorBuilder: (_, __) =>
                            SizedBox(width: 6 * scale),
                        itemBuilder: (context, index) {
                          final w = widgetManifest[index];
                          final id = w['id'] as String;
                          final name = w['name'] as String;
                          final selected =
                              _items.any((i) => i.widgetId == id);

                          return ChoiceChip(
                            label: Text(name),
                            selected: selected,
                            onSelected: (_) => toggleWidget(id),
                            selectedColor: Colors.cyan.withOpacity(0.15),
                            labelStyle: TextStyle(
                              color: selected
                                  ? Colors.cyanAccent
                                  : Colors.white70,
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

                    // MAIN AREA: screen grid driven layout
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final maxW = constraints.maxWidth;
                          final maxH = constraints.maxHeight;

                          final cellW = maxW / _grid.columns;
                          final cellH = maxH / _grid.rows;

                          return Stack(
                            children: _items
                                .map((item) => _buildGridWidget(
                                      item,
                                      cellW,
                                      cellH,
                                      maxW,
                                      maxH,
                                    ))
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

  Widget _buildGridWidget(
    ScreenGridWidgetSpan item,
    double cellW,
    double cellH,
    double maxW,
    double maxH,
  ) {
    // Convert screen-grid coordinates to pixels
    final left = (item.col * cellW)
        .clamp(0.0, maxW - cellW); // simple clamping to keep on screen
    final top = (item.row * cellH)
        .clamp(0.0, maxH - cellH);

    final widthPx = (item.colSpan * cellW)
        .clamp(cellW * 2, maxW); // at least 2 cols
    final heightPx = (item.rowSpan * cellH)
        .clamp(cellH * 2, maxH); // at least 2 rows

    return Positioned(
      left: left,
      top: top,
      width: widthPx,
      height: heightPx,
      child: _draggableResizableGridItem(
        item,
        cellW,
        cellH,
        maxW,
        maxH,
      ),
    );
  }

  Widget _draggableResizableGridItem(
    ScreenGridWidgetSpan item,
    double cellW,
    double cellH,
    double maxW,
    double maxH,
  ) {
    Offset? dragStart;
    int startCol = item.col;
    int startRow = item.row;

    Offset? resizeStart;
    int startColSpan = item.colSpan;
    int startRowSpan = item.rowSpan;

    final child = WidgetFactory.createWidget(item.widgetId);

    return GestureDetector(
      // DRAG by grid cells
      onPanStart: (details) {
        final local = details.localPosition;
        const handleSize = 20.0;
        if (local.dx > cellW * item.colSpan - handleSize &&
            local.dy > cellH * item.rowSpan - handleSize) {
          // resizing, not dragging
          resizeStart = details.globalPosition;
          startColSpan = item.colSpan;
          startRowSpan = item.rowSpan;
        } else {
          dragStart = details.globalPosition;
          startCol = item.col;
          startRow = item.row;
        }
      },
      onPanUpdate: (details) {
        if (resizeStart != null) {
          // resize in grid units
          final delta = details.globalPosition - resizeStart!;
          final dCols = (delta.dx / cellW).round();
          final dRows = (delta.dy / cellH).round();

          setState(() {
            item.colSpan = (startColSpan + dCols)
                .clamp(2, _grid.columns - item.col);
            item.rowSpan =
                (startRowSpan + dRows).clamp(2, _grid.rows - item.row);
          });
        } else if (dragStart != null) {
          // drag in grid units
          final delta = details.globalPosition - dragStart!;
          final dCols = (delta.dx / cellW).round();
          final dRows = (delta.dy / cellH).round();

          setState(() {
            item.col = (startCol + dCols)
                .clamp(0, _grid.columns - item.colSpan);
            item.row =
                (startRow + dRows).clamp(0, _grid.rows - item.rowSpan);
          });
        }
      },
      onPanEnd: (_) {
        dragStart = null;
        resizeStart = null;
      },
      child: Stack(
        children: [
          Positioned.fill(child: child),
          // Resize handle
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
    );
  }
}
