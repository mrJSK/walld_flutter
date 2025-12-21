// lib/dynamic_screen/model/floating_widget.dart
class FloatingWidgetItem {
  final String widgetId;
  double x;      // left position in pixels
  double y;      // top position in pixels
  double width;  // widget width in pixels
  double height; // widget height in pixels

  FloatingWidgetItem({
    required this.widgetId,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}
