import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:window_manager/window_manager.dart';
import 'Screen/Admin/admin_desktop_screen.dart';
import 'Screen/Developer/developer_dashboard_screen.dart';
import 'firebase_options.dart';
import 'Screen/Auth_screen.dart'; // ← Add this import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    backgroundColor: Colors.black,
    titleBarStyle: TitleBarStyle.hidden,
    skipTaskbar: false,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.maximize();
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setMovable(false);
    await windowManager.setResizable(false);
    await windowManager.setMinimizable(false);
    await windowManager.setClosable(false);
  });

  runApp(const WallDApp());
}

class WallDApp extends StatelessWidget {
  const WallDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wall-D',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[800]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.cyan[400]!, width: 2),
          ),
        ),
      ),
      //home: const AuthScreen(), // ← Now imports from Screen/developer_dashboard_screen.dart
      //home: const DeveloperDashboardScreen(), // ← Now imports from Screen/developer_dashboard_screen.dart
      home: const AdminDesktopScreen(), // ← Now imports from Screen/developer_dashboard_screen.dart
    );
  }
}
