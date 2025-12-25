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
  static const _prefsGlobalOpacityKey = 'global_widget_opacity';
  static const _prefsGlobalBlurKey = 'global_widget_blur';

  String? wallpaperPath;
  double globalGlassOpacity = 0.12;
  double globalGlassBlur = 16.0;

  bool _isLoaded = false;

  // Cached wallpaper (avoid sync decode on first frames)
  ui.Image? _cachedDecodedImage;
  ImageProvider? _cachedImageProvider;

  // Notify throttling (prevents rebuild storms on sliders)
  DateTime _lastNotify = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> loadSettings() async {
    if (_isLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    wallpaperPath = prefs.getString(_prefsWallpaperKey);
    globalGlassOpacity = prefs.getDouble(_prefsGlobalOpacityKey) ?? 0.12;
    globalGlassBlur = prefs.getDouble(_prefsGlobalBlurKey) ?? 16.0;

    if (wallpaperPath != null && File(wallpaperPath!).existsSync()) {
      await _precacheWallpaper();
    } else {
      wallpaperPath = null;
    }

    _isLoaded = true;
    _notifyNow();
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (wallpaperPath != null) {
      await prefs.setString(_prefsWallpaperKey, wallpaperPath!);
    } else {
      await prefs.remove(_prefsWallpaperKey);
    }

    await prefs.setDouble(_prefsGlobalOpacityKey, globalGlassOpacity);
    await prefs.setDouble(_prefsGlobalBlurKey, globalGlassBlur);

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
    _cachedImageProvider = null;
    _cachedDecodedImage = null;
    await saveSettings();
  }

  void setGlassBlur(double blur) {
    globalGlassBlur = blur.clamp(0.0, 40.0);
    _throttledNotify();
  }

  void setGlassOpacity(double opacity) {
    globalGlassOpacity = opacity.clamp(0.02, 0.40);
    _throttledNotify();
  }

  void _throttledNotify() {
    final now = DateTime.now();
    if (now.difference(_lastNotify).inMilliseconds < 16) return; // ~60fps cap
    _lastNotify = now;
    notifyListeners();
  }

  void _notifyNow() {
    _lastNotify = DateTime.now();
    notifyListeners();
  }

  /// IMPORTANT: Keep wallpaper decode async and cached.
  Future<void> _precacheWallpaper() async {
    final path = wallpaperPath;
    if (path == null) return;

    final file = File(path);
    if (!file.existsSync()) {
      wallpaperPath = null;
      _cachedImageProvider = null;
      _cachedDecodedImage = null;
      return;
    }

    try {
      _cachedImageProvider = FileImage(file);

      final imageStream =
          _cachedImageProvider!.resolve(const ImageConfiguration());
      final completer = Completer<void>();

      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo info, bool _) {
          _cachedDecodedImage = info.image;
          imageStream.removeListener(listener);
          completer.complete();
        },
        onError: (error, stack) {
          imageStream.removeListener(listener);
          _cachedImageProvider = null;
          _cachedDecodedImage = null;
          completer.complete();
        },
      );

      imageStream.addListener(listener);
      await completer.future;
    } catch (_) {
      _cachedImageProvider = null;
      _cachedDecodedImage = null;
    }
  }

  /// Fixes “wallpaper problems” on desktop by normalizing huge images:
  /// - Downscales to a max dimension (default 2560px)
  /// - Re-encodes to PNG (fast decode and predictable)
  Future<String> _copyAndNormalizeWallpaper(
    String pickedPath, {
    int maxDimension = 2560,
  }) async {
    final appDir = await getApplicationSupportDirectory();
    final wpDir = Directory(p.join(appDir.path, 'wallpapers'));
    if (!await wpDir.exists()) {
      await wpDir.create(recursive: true);
    }

    // Always store as .png after normalization
    final cachedPath = p.join(wpDir.path, 'current_wallpaper.png');

    final srcBytes = await File(pickedPath).readAsBytes();

    try {
      final codec = await ui.instantiateImageCodec(srcBytes);
      final frame = await codec.getNextFrame();
      final img = frame.image;

      final srcW = img.width;
      final srcH = img.height;

      // Compute target size while preserving aspect ratio
      final scale =
          math.min(1.0, maxDimension / math.max(srcW.toDouble(), srcH.toDouble()));
      final targetW = (srcW * scale).round();
      final targetH = (srcH * scale).round();

      ui.Image outImage = img;

      // If downscaling is needed, decode again with target sizes
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

      final byteData =
          await outImage.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes == null) {
        // fallback: raw copy
        await File(pickedPath).copy(cachedPath);
        return cachedPath;
      }

      await File(cachedPath).writeAsBytes(pngBytes, flush: true);

      // Best-effort dispose
      try {
        outImage.dispose();
      } catch (_) {}

      return cachedPath;
    } catch (_) {
      // If anything fails, fallback to a normal copy
      final ext = p.extension(pickedPath).isNotEmpty ? p.extension(pickedPath) : '.jpg';
      final fallbackPath = p.join(wpDir.path, 'current_wallpaper$ext');
      await File(pickedPath).copy(fallbackPath);
      return fallbackPath;
    }
  }

  BoxDecoration get backgroundDecoration {
    if (_cachedImageProvider != null && _cachedDecodedImage != null) {
      return BoxDecoration(
        image: DecorationImage(
          image: _cachedImageProvider!,
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
  
Future<void> updateGlass({
  required double blur,
  required double opacity,
}) async {
  globalGlassBlur = blur.clamp(0.0, 30.0);
  globalGlassOpacity = opacity.clamp(0.0, 1.0);

  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble(_prefsGlobalBlurKey, globalGlassBlur);
  await prefs.setDouble(_prefsGlobalOpacityKey, globalGlassOpacity);

  notifyListeners();
}
}
