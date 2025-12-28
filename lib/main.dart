import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:walld_flutter/Developer/developer_dashboard_screen.dart';
import 'package:walld_flutter/core/wallpaper_service.dart';
import 'package:walld_flutter/firebase_options.dart';
import 'package:walld_flutter/workspace/loading_screen.dart';
import 'package:walld_flutter/workspace/workspace_controller.dart';
import 'package:walld_flutter/workspace/workspace_shell.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;


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
      skipTaskbar: true,  // CHANGED: Hide from taskbar
    );
    
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      // REMOVED: await windowManager.show()  // Don't show the window
      await windowManager.hide();  // ADDED: Explicitly hide the window
      await windowManager.setFullScreen(false);
      // REMOVED: await windowManager.maximize()  // Don't maximize hidden window
      await windowManager.setResizable(false);
      await windowManager.setMinimizable(false);
      await windowManager.setClosable(false);
      
      try {
        await windowManager.setAlwaysOnBottom(true);
      } catch (e) {
        debugPrint("Could not set window to bottom: $e");
      }
    });
    
    debugPrint("Desktop window configured (hidden, background mode)");
  } catch (e) {
    debugPrint("Desktop window setup failed: $e");
  }
}

class WallDApp extends StatefulWidget {
  const WallDApp({super.key});

  @override
  State<WallDApp> createState() => WallDAppState();
}

class WallDAppState extends State<WallDApp> {
  final WorkspaceController workspaceController = WorkspaceController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint('WallDApp - initState');
  }

  @override
  void dispose() {
    debugPrint('WallDApp - dispose');
    workspaceController.dispose();
    super.dispose();
  }

  void onLoadingComplete() {
    debugPrint('WallDApp - onLoadingComplete called');
    debugPrint('Loading complete - transitioning to workspace');
    if (mounted) {
      setState(() {
        isLoading = false;
      });
      debugPrint('WallDApp - isLoading set to false - showing WorkspaceShell');
    } else {
      debugPrint('WallDApp - Widget not mounted, skipping setState');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('WallDApp - build - isLoading:$isLoading');
    return MaterialApp(
      title: 'Wall-D',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF05040A),
      ),
      home: isLoading 
        ? LoadingScreen(onLoadingComplete: onLoadingComplete)
        : WorkspaceShell(workspaceController: workspaceController),
      //home: const DeveloperDashboardScreen(),
    );
  }
}


