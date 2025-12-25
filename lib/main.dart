import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;

import 'firebase_options.dart';
import 'workspace/workspace_shell.dart';
import 'workspace/workspace_controller.dart';
import 'workspace/loading_screen.dart';
import 'core/wallpaper_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // STEP 1: Defer first frame until heavy init is done
  final binding = WidgetsBinding.instance;
  binding.deferFirstFrame();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // STEP 2: Pre-load wallpaper service
    await WallpaperService.instance.loadSettings();
    debugPrint('✅ WallpaperService loaded before first frame');

    // STEP 3: Setup desktop window properties
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await _setupDesktopWindow();
    }
  } catch (e) {
    debugPrint('❌ Error during pre-initialization: $e');
  }

  // STEP 4: Allow first frame and run app
  binding.allowFirstFrame();
  runApp(const WallDApp());
}

/// Setup desktop window properties (Windows/macOS/Linux)
Future<void> _setupDesktopWindow() async {
  try {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      backgroundColor: Colors.black,
      titleBarStyle: TitleBarStyle.hidden,
      skipTaskbar: false,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.setFullScreen(false);
      await windowManager.maximize();

      // Removed: setMovable (not supported)
      await windowManager.setResizable(false);
      await windowManager.setMinimizable(false);
      await windowManager.setClosable(false);

      try {
        await windowManager.setAlwaysOnBottom(true);
      } catch (e) {
        debugPrint('⚠️ Could not set window to bottom: $e');
      }
    });

    debugPrint('✅ Desktop window configured');
  } catch (e) {
    debugPrint('❌ Desktop window setup failed: $e');
  }
}

class WallDApp extends StatefulWidget {
  const WallDApp({super.key});

  @override
  State<WallDApp> createState() => _WallDAppState();
}

class _WallDAppState extends State<WallDApp> {
  final WorkspaceController _workspaceController = WorkspaceController();
  bool _isLoading = true;

  @override
  void dispose() {
    _workspaceController.dispose();
    super.dispose();
  }

  void _onLoadingComplete() {
    debugPrint('🎉 Loading complete - transitioning to workspace');
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wall-D',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF05040A),
      ),
      home: _isLoading
          ? LoadingScreen(
              // FIX: only pass onLoadingComplete,
              // because LoadingScreen(onLoadingComplete: ...) is the signature
              onLoadingComplete: _onLoadingComplete,
            )
          : WorkspaceShell(
              workspaceController: _workspaceController,
            ),
    );
  }
}
