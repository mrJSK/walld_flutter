// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'Developer/developer_dashboard_screen.dart';
import 'dynamic_screen/dashboardpanel.dart';
import 'workspace/workspace_shell.dart';

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

class WallDApp extends StatelessWidget {
  const WallDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wall-D',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF05040A),
      ),
      //home: const DashboardPanel(),
      home: const WorkspaceShell(),
      //home: const DeveloperDashboardScreen(),
    );
  }
}
