import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;

import 'firebase_options.dart';
import 'workspace/workspace_shell.dart';
import 'workspace/workspace_controller.dart'; // <--- Added Import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (Platform.isWindows) {
    await _setupWindowsWallpaper();
  }

  runApp(const WallDApp());
}

Future<void> _setupWindowsWallpaper() async {
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
    await windowManager.setMovable(false);
    await windowManager.setResizable(false);
    await windowManager.setMinimizable(false);
    await windowManager.setClosable(false);

    try {
      await windowManager.setAlwaysOnBottom(true);
    } catch (e) {
      debugPrint('Could not set window to bottom: $e');
    }
  });
}

// Changed to StatefulWidget to hold the WorkspaceController
class WallDApp extends StatefulWidget {
  const WallDApp({super.key});

  @override
  State<WallDApp> createState() => _WallDAppState();
}

class _WallDAppState extends State<WallDApp> {
  // 1. Initialize the controller
  final WorkspaceController _workspaceController = WorkspaceController();

  @override
  void dispose() {
    _workspaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wall-D',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF05040A),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          debugPrint('[MAIN] authStateChanges -> user = ${user?.uid}');
          
          // 2. Pass the controller (removed 'const' because controller is not const)
          return WorkspaceShell(
            workspaceController: _workspaceController,
          );
        },
      ),
    );
  }
}