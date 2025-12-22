class GridLayoutConfig {
  final int columns;
  final double rowHeight; // logical pixels per grid row

  const GridLayoutConfig({
    this.columns = 120,
    this.rowHeight = 700,
  });
}

class WidgetGridItem {
  final String widgetId;
  int col;      // 0-based column index
  int row;      // 0-based row index
  int colSpan;  // number of columns spanned
  int rowSpan;  // number of rows spanned

  WidgetGridItem({
    required this.widgetId,
    required this.col,
    required this.row,
    required this.colSpan,
    required this.rowSpan,
  });
}
