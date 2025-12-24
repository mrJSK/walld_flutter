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
    // 1. Initialize with defaults temporarily
    items = defaultItems();
    
    _initWallpaperService();
    
    // 2. Load saved layout from disk (this might overwrite items with an incomplete list!)
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
        // Load real permissions
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

          // ============================================================
          // FIX: RECONCILIATION LOGIC
          // Check if any allowed widget is MISSING from the current 'items' list
          // because it wasn't in the saved layout.
          // ============================================================
          
          // 1. What widgets do we currently have in the layout?
          final currentLayoutIds = items.map((w) => w.widgetId).toSet();
          
          // 2. Which allowed widgets are missing?
          final missingIds = ids.difference(currentLayoutIds);

          if (missingIds.isNotEmpty) {
            debugPrint('[DASH] Found missing allowed widgets: $missingIds. Restoring them now...');
            final defaults = defaultItems();
            
            for (final missingId in missingIds) {
              // Try to find the default configuration for this missing widget
              try {
                final defaultWidget = defaults.firstWhere((w) => w.widgetId == missingId);
                items.add(defaultWidget);
              } catch (e) {
                debugPrint('[DASH] Warning: No default layout definition found for widgetId: $missingId');
              }
            }
            
            // 3. Save the repaired layout immediately so they stick
            saveLayout();
          }
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
        
        // Trigger a permission check again in case layout loaded AFTER auth
        if (currentUser != null) {
           loadUserPermissions(currentUser!.uid);
        }
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

  // ---------- WIDGET VISIBILITY ----------

  void toggleWidget(String widgetId) {
    final index = items.indexWhere((w) => w.widgetId == widgetId);
    if (index != -1) {
      setState(() => items.removeAt(index));
    } else {
      // Find default to add back
      final defaults = defaultItems();
      try {
        final w = defaults.firstWhere((element) => element.widgetId == widgetId);
        setState(() {
          items.add(w);
        });
      } catch (e) {
        debugPrint("Widget ID $widgetId not found in defaults");
      }
    }
    saveLayout();
  }

  // ---------- BUILD ----------

  @override
  Widget build(BuildContext context) {
    final user = currentUser ?? FirebaseAuth.instance.currentUser;

    // Filter widgets
    final visibleItems = user == null
        ? items.where((w) => w.widgetId == 'login').toList()
        : items.where((w) => allowedWidgetIds.contains(w.widgetId)).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        
        child: SafeArea(
          child: Stack(
            children: [
              // 1. THE GRID
              DashboardGrid(
                grid: grid,
                items: visibleItems,
                onSnap: saveLayout,
              ),
              
              // 2. REMOVED: DashboardTopBar
              // It is now handled by WorkspaceShell
              
              // 3. Keep Drawer if you use it, or remove if not needed
              // const DashboardDrawer(), 
            ],
          ),
        ),
      ),
    );
  }
}