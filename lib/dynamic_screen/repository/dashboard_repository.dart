import '../model/widget.dart';
import '../widget_manifest.dart';

class DashboardRepository {
  List<WidgetModel> getWidgets() {
    return widgetManifest.map((w) => WidgetModel(id: w['id'] as String, name: w['name'] as String)).toList();
  }
}
