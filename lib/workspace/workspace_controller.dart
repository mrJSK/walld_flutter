import 'package:flutter/foundation.dart';
import 'workspace_ids.dart';

class WorkspaceController extends ChangeNotifier {
  String _current = WorkspaceIds.dashboard;

  String get current => _current;

  // FIX: Added 'switchTo' to match the call in UniversalTopBar
  void switchTo(String id) {
    if (id == _current) return;
    _current = id;
    notifyListeners();
  }

  // Optional: Keep this if other files use it, or alias it
  void setWorkspace(String id) => switchTo(id);
}