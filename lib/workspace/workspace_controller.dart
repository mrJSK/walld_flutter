import 'package:flutter/foundation.dart';
import 'workspace_ids.dart';

class WorkspaceController extends ChangeNotifier {
  String _current = WorkspaceIds.dashboard;

  String get current => _current;

  void setWorkspace(String id) {
    if (id == _current) return;
    _current = id;
    notifyListeners();
  }
}
