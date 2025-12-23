import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

/// Singleton service for managing app-wide wallpaper and glass settings
class WallpaperService extends ChangeNotifier {
  static final WallpaperService instance = WallpaperService._();
  WallpaperService._();

  // Keys for SharedPreferences
  static const _prefsWallpaperKey = 'wallpaper_path';
  static const _prefsGlobalOpacityKey = 'global_widget_opacity';
  static const _prefsGlobalBlurKey = 'global_widget_blur';

  // State
  String? wallpaperPath;
  double globalGlassOpacity = 0.12;
  double globalGlassBlur = 16.0;

  bool _isLoaded = false;

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    if (_isLoaded) return; // Load only once
    
    final prefs = await SharedPreferences.getInstance();
    wallpaperPath = prefs.getString(_prefsWallpaperKey);
    globalGlassOpacity = prefs.getDouble(_prefsGlobalOpacityKey) ?? 0.12;
    globalGlassBlur = prefs.getDouble(_prefsGlobalBlurKey) ?? 16.0;
    
    _isLoaded = true;
    debugPrint('[WallpaperService] LOADED: wallpaper=$wallpaperPath blur=$globalGlassBlur opacity=$globalGlassOpacity');
    notifyListeners();
  }

  /// Save current settings to SharedPreferences
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (wallpaperPath != null) {
      await prefs.setString(_prefsWallpaperKey, wallpaperPath!);
    } else {
      await prefs.remove(_prefsWallpaperKey);
    }
    
    await prefs.setDouble(_prefsGlobalOpacityKey, globalGlassOpacity);
    await prefs.setDouble(_prefsGlobalBlurKey, globalGlassBlur);
    
    debugPrint('[WallpaperService] SAVED: wallpaper=$wallpaperPath blur=$globalGlassBlur opacity=$globalGlassOpacity');
    notifyListeners();
  }

  /// Pick wallpaper from file system (Windows/Desktop)
  Future<void> pickWallpaper() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    final pickedPath = result?.files.single.path;
    if (pickedPath == null) return;

    // Copy to app support directory
    final appDir = await getApplicationSupportDirectory();
    final wpDir = Directory(p.join(appDir.path, 'wallpapers'));
    if (!await wpDir.exists()) {
      await wpDir.create(recursive: true);
    }

    final ext = p.extension(pickedPath).isNotEmpty 
        ? p.extension(pickedPath) 
        : '.jpg';
    final cachedPath = p.join(wpDir.path, 'current_wallpaper$ext');

    await File(pickedPath).copy(cachedPath);

    wallpaperPath = cachedPath;
    await saveSettings();
  }

  /// Reset wallpaper to default gradient
  Future<void> resetWallpaper() async {
    wallpaperPath = null;
    await saveSettings();
  }

  /// Update glass blur
  void setGlassBlur(double blur) {
    globalGlassBlur = blur.clamp(0.0, 40.0);
    notifyListeners();
  }

  /// Update glass opacity
  void setGlassOpacity(double opacity) {
    globalGlassOpacity = opacity.clamp(0.02, 0.40);
    notifyListeners();
  }

  /// Get background decoration (wallpaper or gradient)
  BoxDecoration get backgroundDecoration {
    final path = wallpaperPath;
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        return BoxDecoration(
          image: DecorationImage(
            image: FileImage(file),
            fit: BoxFit.cover,
          ),
        );
      }
    }

    // Default gradient
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF050716),
          Color(0xFF020308),
        ],
      ),
    );
  }
}
