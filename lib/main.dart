import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'Screen/Admin/admin_desktop_screen.dart';
import 'Screen/Auth_screen.dart';
import 'Screen/Developer/developer_dashboard_screen.dart';
import 'firebase_options.dart';

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

  // Get screen dimensions (excluding taskbar)
  const windowOptions = WindowOptions(
    backgroundColor: Colors.black,
    titleBarStyle: TitleBarStyle.hidden,
    skipTaskbar: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    
    // Make it fullscreen but preserve taskbar
    await windowManager.setFullScreen(false); // Not true fullscreen
    await windowManager.maximize(); // Maximize respects taskbar
    
    // Lock it
    await windowManager.setMovable(false);
    await windowManager.setResizable(false);
    await windowManager.setMinimizable(false);
    await windowManager.setClosable(false);
    
    // Set as background (wallpaper level)
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
      home: const DeveloperDashboardScreen(),
      //home: const AuthScreen(),
      //home: const AdminDesktopScreen(),

    );
  }
}
