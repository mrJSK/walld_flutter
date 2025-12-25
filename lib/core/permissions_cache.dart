import 'package:flutter/material.dart';

class PermissionsCache extends ChangeNotifier {
  static final PermissionsCache instance = PermissionsCache._();
  PermissionsCache._();

  Set<String>? _cachedWidgetIds;
  String? _cachedUserId;
  DateTime? _cacheTime;

  static const _cacheValidDuration = Duration(minutes: 5);

  bool get hasCache => _cachedWidgetIds != null && _isValid;

  bool get _isValid {
    if (_cacheTime == null) return false;
    return DateTime.now().difference(_cacheTime!) < _cacheValidDuration;
  }

  /// Return cached permissions for [userId] if they are still valid,
  /// otherwise null.
  Set<String>? getCachedPermissions(String userId) {
    if (_cachedUserId != userId) return null;
    if (!_isValid) return null;
    return _cachedWidgetIds;
  }

  /// Store permissions for [userId] in memory cache for a short duration.
  void setCachedPermissions(String userId, Set<String> widgetIds) {
    _cachedUserId = userId;
    _cachedWidgetIds = widgetIds;
    _cacheTime = DateTime.now();

    debugPrint(
      '[PermissionsCache] ✅ Cached ${widgetIds.length} permissions for user $userId',
    );
    notifyListeners();
  }

  void clearCache() {
    _cachedWidgetIds = null;
    _cachedUserId = null;
    _cacheTime = null;
    debugPrint('[PermissionsCache] 🗑️ Cache cleared');
    notifyListeners();
  }
}
