import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WallpaperService extends ChangeNotifier {
  static final WallpaperService instance = WallpaperService._();
  WallpaperService._();

  static const _prefsWallpaperKey = 'wallpaper_path';
  static const prefsGlobalOpacityKey = 'global_widget_opacity';
  static const prefsGlobalBlurKey = 'global_widget_blur';

  String? wallpaperPath;
  double globalGlassOpacity = 0.12;
  double globalGlassBlur = 16.0;
  bool isLoaded = false;

  ui.Image? _cachedDecodedImage;
  ImageProvider? cachedImageProvider;
  DateTime _lastNotify = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> loadSettings() async {
    if (isLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    wallpaperPath = prefs.getString(_prefsWallpaperKey);
    globalGlassOpacity = prefs.getDouble(prefsGlobalOpacityKey) ?? 0.12;
    globalGlassBlur = prefs.getDouble(prefsGlobalBlurKey) ?? 16.0;

    debugPrint('✅ [GLASS] Loaded from cache: blur=$globalGlassBlur, opacity=$globalGlassOpacity');

    if (wallpaperPath != null && File(wallpaperPath!).existsSync()) {
      await _precacheWallpaper();
    } else {
      wallpaperPath = null;
    }

    isLoaded = true;
    _notifyNow();
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (wallpaperPath != null) {
      await prefs.setString(_prefsWallpaperKey, wallpaperPath!);
    } else {
      await prefs.remove(_prefsWallpaperKey);
    }
    await prefs.setDouble(prefsGlobalOpacityKey, globalGlassOpacity);
    await prefs.setDouble(prefsGlobalBlurKey, globalGlassBlur);
    debugPrint('💾 [GLASS] Full settings saved: blur=$globalGlassBlur, opacity=$globalGlassOpacity');
    _notifyNow();
  }

  Future<void> pickWallpaper() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );

    final pickedPath = result?.files.single.path;
    if (pickedPath == null) return;

    final normalizedPath = await _copyAndNormalizeWallpaper(pickedPath);
    wallpaperPath = normalizedPath;
    await _precacheWallpaper();
    await saveSettings();
  }

  Future<void> resetWallpaper() async {
    wallpaperPath = null;
    cachedImageProvider = null;
    _cachedDecodedImage = null;
    await saveSettings();
  }

  // In lib/core/wallpaper_service.dart - Replace the setters:

void setGlassBlur(double blur) {
  final oldBlur = globalGlassBlur;
  final clampedBlur = blur.clamp(0.0, 40.0);
  
  // 🛡️ BLOCK performance overrides that reset to 0.0
  if (clampedBlur == 0.0 && oldBlur > 5.0) {
    debugPrint('🛡️ [GLASS PROTECTED] Blocked blur=0.0 → keeping $oldBlur');
    _throttledNotify();
    return; // BLOCK IT!
  }
  
  globalGlassBlur = clampedBlur;
  debugPrint('🔵 [GLASS] Blur → $globalGlassBlur');
  _throttledNotify();
  unawaited(_saveGlassSettingsOnly());
}

void setGlassOpacity(double opacity) {
  final oldOpacity = globalGlassOpacity;
  final clampedOpacity = opacity.clamp(0.02, 0.40);
  
  // 🛡️ BLOCK performance overrides that reset to 0.04
  if (clampedOpacity <= 0.05 && oldOpacity > 0.10) {
    debugPrint('🛡️ [GLASS PROTECTED] Blocked opacity=$clampedOpacity → keeping $oldOpacity');
    _throttledNotify();
    return; // BLOCK IT!
  }
  
  globalGlassOpacity = clampedOpacity;
  debugPrint('🔵 [GLASS] Opacity → $globalGlassOpacity');
  _throttledNotify();
  unawaited(_saveGlassSettingsOnly());
}



  // ✅ NEW: Fast save (only glass settings, not wallpaper)
  Future<void> _saveGlassSettingsOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(prefsGlobalOpacityKey, globalGlassOpacity);
      await prefs.setDouble(prefsGlobalBlurKey, globalGlassBlur);
      debugPrint('✅ [GLASS] Saved to cache: blur=$globalGlassBlur, opacity=$globalGlassOpacity');
    } catch (e) {
      debugPrint('❌ [GLASS] Save failed: $e');
    }
  }

  void _throttledNotify() {
    final now = DateTime.now();
    if (now.difference(_lastNotify).inMilliseconds < 16) return;
    _lastNotify = now;
    notifyListeners();
  }

  void _notifyNow() {
    _lastNotify = DateTime.now();
    notifyListeners();
  }

  Future<void> _precacheWallpaper() async {
    final path = wallpaperPath;
    if (path == null) return;

    final file = File(path);
    if (!file.existsSync()) {
      wallpaperPath = null;
      cachedImageProvider = null;
      _cachedDecodedImage = null;
      return;
    }

    try {
      cachedImageProvider = FileImage(file);
      final imageStream = cachedImageProvider!.resolve(const ImageConfiguration());
      final completer = Completer<void>();
      late final ImageStreamListener listener;

      listener = ImageStreamListener(
        (ImageInfo info, bool _) {
          _cachedDecodedImage = info.image;
          imageStream.removeListener(listener);
          completer.complete();
        },
        onError: (_, __) {
          imageStream.removeListener(listener);
          cachedImageProvider = null;
          _cachedDecodedImage = null;
          completer.complete();
        },
      );

      imageStream.addListener(listener);
      await completer.future;
    } catch (_) {
      cachedImageProvider = null;
      _cachedDecodedImage = null;
    }
  }

  Future<String> _copyAndNormalizeWallpaper(
    String pickedPath, [
    int maxDimension = 2560,
  ]) async {
    final appDir = await getApplicationSupportDirectory();
    final wpDir = Directory(p.join(appDir.path, 'wallpapers'));
    if (!await wpDir.exists()) {
      await wpDir.create(recursive: true);
    }

    final cachedPath = p.join(wpDir.path, 'current_wallpaper.png');
    final srcBytes = await File(pickedPath).readAsBytes();

    try {
      final codec = await ui.instantiateImageCodec(srcBytes);
      final frame = await codec.getNextFrame();
      final img = frame.image;

      final srcW = img.width;
      final srcH = img.height;

      final scale = math.min(
        1.0,
        maxDimension / math.max(srcW.toDouble(), srcH.toDouble()),
      );
      final targetW = (srcW * scale).round();
      final targetH = (srcH * scale).round();

      ui.Image outImage = img;

      if (scale < 1.0) {
        codec.dispose();
        final codec2 = await ui.instantiateImageCodec(
          srcBytes,
          targetWidth: targetW,
          targetHeight: targetH,
        );
        final frame2 = await codec2.getNextFrame();
        outImage = frame2.image;
        codec2.dispose();
      } else {
        codec.dispose();
      }

      final byteData = await outImage.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes == null) {
        await File(pickedPath).copy(cachedPath);
        return cachedPath;
      }

      await File(cachedPath).writeAsBytes(pngBytes, flush: true);

      try {
        outImage.dispose();
      } catch (_) {}

      return cachedPath;
    } catch (_) {
      final ext = p.extension(pickedPath).isNotEmpty ? p.extension(pickedPath) : '.jpg';
      final fallbackPath = p.join(wpDir.path, 'current_wallpaper$ext');
      await File(pickedPath).copy(fallbackPath);
      return fallbackPath;
    }
  }

  BoxDecoration get backgroundDecoration {
    if (cachedImageProvider != null && _cachedDecodedImage != null) {
      return BoxDecoration(
        image: DecorationImage(
          image: cachedImageProvider!,
          fit: BoxFit.cover,
        ),
      );
    }

    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF050716), Color(0xFF020308)],
      ),
    );
  }

  // Legacy method (kept for backward compatibility)
  Future<void> updateGlass({
    required double blur,
    required double opacity,
  }) async {
    globalGlassBlur = blur.clamp(0.0, 30.0);
    globalGlassOpacity = opacity.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(prefsGlobalBlurKey, globalGlassBlur);
    await prefs.setDouble(prefsGlobalOpacityKey, globalGlassOpacity);
    debugPrint('💾 [GLASS] Legacy updateGlass() saved: blur=$globalGlassBlur, opacity=$globalGlassOpacity');
    notifyListeners();
  }
}
