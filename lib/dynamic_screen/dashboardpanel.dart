import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/wallpaper_service.dart';
import '../workspace/workspace_controller.dart';
import '../workspace/workspace_switcher.dart';

import 'dashboard_layout_persistence.dart';
import 'dashboard_permissions.dart';
import 'model/screen_grid.dart';
import 'model/floating_widget.dart';
import 'dashboard_grid.dart';
import 'dashboard_topbar.dart';
import 'dashboard_drawer.dart';

class DashboardPanel extends StatefulWidget {
  final WorkspaceController? workspaceController;

  const DashboardPanel({super.key, this.workspaceController});

  @override
  State<DashboardPanel> createState() => DashboardPanelState();
}

class DashboardPanelState extends State<DashboardPanel> {
  // Layout
  final ScreenGridConfig grid = const ScreenGridConfig(columns: 24, rows: 14);
  late List<ScreenGridWidgetSpan> items;

  // Auth / permissions
  User? currentUser;
  Set<String> allowedWidgetIds = {'login'};

  // Layout persistence key
  static const String prefsLayoutKey = 'screen_grid_layout';

  @override
  void initState() {
    super.initState();
    items = defaultItems();
    _initWallpaperService();
    loadLayout();
    debugPrint('[DASH] initState -> attaching auth listener');
    listenAuthState();
  }

  Future<void> _initWallpaperService() async {
    await WallpaperService.instance.loadSettings();
    WallpaperService.instance.addListener(_onWallpaperChanged);
    if (mounted) setState(() {});
  }

  void _onWallpaperChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    WallpaperService.instance.removeListener(_onWallpaperChanged);
    super.dispose();
  }

  // ---------- AUTH & PERMISSIONS ----------

  void listenAuthState() {
  FirebaseAuth.instance.authStateChanges().listen((user) {
    debugPrint('[DASH] authStateChanges user = ${user?.uid}');
    currentUser = user;
    if (!mounted) return;

    if (user == null) {
      debugPrint('[DASH] user == null -> login only');
      setState(() {
        allowedWidgetIds = {'login'};
      });
    } else {
      debugPrint('[DASH] user logged in, loading permissions');
      setState(() {
        allowedWidgetIds = {
          'createtask',
          'viewassignedtasks',
          'viewalltasks',
          'completetask',
        };
      });
      loadUserPermissions(user.uid);
    }
  });
}



  Future<void> loadUserPermissions(String userId) async {
    await DashboardPermissions.loadUserPermissions(
      context: context,
      userId: userId,
      onAllowedWidgetIds: (ids) {
        if (!mounted) return;
        setState(() {
          allowedWidgetIds = ids;
        });
      },
    );
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // ---------- LAYOUT PERSISTENCE ----------

  Future<void> loadLayout() async {
    await DashboardLayoutPersistence.loadLayout(
      prefsKey: prefsLayoutKey,
      onLoaded: (loaded) {
        if (!mounted) return;
        setState(() => items = loaded);
      },
      defaultItemsBuilder: defaultItems,
    );
  }

  Future<void> saveLayout() async {
    await DashboardLayoutPersistence.saveLayout(
      prefsKey: prefsLayoutKey,
      items: items,
    );
  }

  List<ScreenGridWidgetSpan> defaultItems() {
    return [
      ScreenGridWidgetSpan(
        widgetId: 'login',
        col: 7,
        row: 3,
        colSpan: 10,
        rowSpan: 8,
      ),
      ScreenGridWidgetSpan(
        widgetId: 'createtask',
        col: 1,
        row: 2,
        colSpan: 10,
        rowSpan: 4,
      ),
      ScreenGridWidgetSpan(
        widgetId: 'viewassignedtasks',
        col: 13,
        row: 2,
        colSpan: 10,
        rowSpan: 4,
      ),
      ScreenGridWidgetSpan(
        widgetId: 'viewalltasks',
        col: 1,
        row: 8,
        colSpan: 10,
        rowSpan: 4,
      ),
      ScreenGridWidgetSpan(
        widgetId: 'completetask',
        col: 13,
        row: 8,
        colSpan: 10,
        rowSpan: 4,
      ),
    ];
  }

  // ---------- WALLPAPER & GLASS ----------

  Future<void> pickWallpaperFromWindows() async {
    await WallpaperService.instance.pickWallpaper();
  }

  Future<void> resetWallpaper() async {
    await WallpaperService.instance.resetWallpaper();
  }

  BoxDecoration get backgroundDecoration {
    return WallpaperService.instance.backgroundDecoration;
  }

  Future<void> openGlobalGlassSheet() async {
    final service = WallpaperService.instance;
    double tempOpacity = service.globalGlassOpacity;
    double tempBlur = service.globalGlassBlur;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF05040A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const Row(
                      children: [
                        Icon(
                          Icons.blur_on_rounded,
                          color: Colors.cyanAccent,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Glass settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const SizedBox(
                          width: 70,
                          child: Text(
                            'Opacity',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            min: 0.04,
                            max: 0.30,
                            divisions: 26,
                            value: tempOpacity.clamp(0.04, 0.30),
                            label: tempOpacity.toStringAsFixed(2),
                            onChanged: (v) {
                              setModalState(() {
                                tempOpacity = v;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const SizedBox(
                          width: 70,
                          child: Text(
                            'Blur',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            min: 0,
                            max: 30,
                            divisions: 30,
                            value: tempBlur.clamp(0, 30),
                            label: tempBlur.toStringAsFixed(0),
                            onChanged: (v) {
                              setModalState(() {
                                tempBlur = v;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => Navigator.pop(context, true),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (applied == true) {
      service.setGlassOpacity(tempOpacity);
      service.setGlassBlur(tempBlur);
      await service.saveSettings();
    }
  }

  // ---------- WIDGET VISIBILITY ----------

  void toggleWidget(String widgetId) {
    final index = items.indexWhere((w) => w.widgetId == widgetId);
    if (index != -1) {
      setState(() => items.removeAt(index));
    } else {
      setState(() {
        items.add(
          ScreenGridWidgetSpan(
            widgetId: widgetId,
            col: 1,
            row: 2,
            colSpan: 8,
            rowSpan: 4,
          ),
        );
      });
    }
    saveLayout();
  }

  // ---------- BUILD ----------

  @override
  Widget build(BuildContext context) {
    // Show all widgets regardless of permissions
    final user = currentUser ?? FirebaseAuth.instance.currentUser;
    debugPrint('[DASH] build user = ${user?.uid}');

    final visibleItems = user == null
      ? items.where((w) => w.widgetId == 'login').toList()
      : items;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: backgroundDecoration,
        child: SafeArea(
          child: Stack(
            children: [
              DashboardGrid(
                grid: grid,
                items: visibleItems,
                onSnap: saveLayout,
              ),
              DashboardTopBar(
                workspaceController: widget.workspaceController,
                onGlassSettings: openGlobalGlassSheet,
                onWallpaperSettings: pickWallpaperFromWindows,
                onResetWallpaper: resetWallpaper,
                onSignOut: signOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
