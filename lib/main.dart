import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:window_manager/window_manager.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    backgroundColor: Colors.black,
    titleBarStyle: TitleBarStyle.hidden, // borderless
    skipTaskbar: false,         // still shows icon in taskbar
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();

    // TRUE FULLSCREEN → no white border, taskbar hidden
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
      ),
      home: const Scaffold(
        body: ColoredBox(
          color: Colors.black,
          child: Center(
            child: Text(
              'Wall-D (True Fullscreen)',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
