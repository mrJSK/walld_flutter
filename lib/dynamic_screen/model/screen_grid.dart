class ScreenGridConfig {
  final int columns;
  final int rows;

  const ScreenGridConfig({
    this.columns = 240,
    this.rows = 140,
  });
}

class ScreenGridWidgetSpan {
  final String widgetId;
  int col;      // 0-based column index
  int row;      // 0-based row index
  int colSpan;  // how many screen columns this widget uses
  int rowSpan;  // how many screen rows this widget uses

  ScreenGridWidgetSpan({
    required this.widgetId,
    required this.col,
    required this.row,
    required this.colSpan,
    required this.rowSpan,
  });
}
