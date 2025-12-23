// lib/dynamic_screen/dashboardpanel.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import '../workspace/workspace_controller.dart';
import '../workspace/workspace_switcher.dart';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'model/screen_grid.dart';
import 'widget_factory.dart';
import 'widget_manifest.dart';

class GlassContainer extends StatelessWidget {
  final double blur; // sigma
  final double opacity; // 0..1
  final Color tint;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final Widget child;

  // Visual tuning
  final double borderOpacity;
  final double borderWidth;
  final List<BoxShadow> boxShadow;

  const GlassContainer({
    super.key,
    required this.blur,
    required this.opacity,
    required this.tint,
    required this.borderRadius,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderOpacity = 0.18,
    this.borderWidth = 1,
    this.boxShadow = const [
      BoxShadow(
        color: Color(0x40000000),
        blurRadius: 18,
        offset: Offset(0, 10),
      ),
    ],
  });

  @override
  Widget build(BuildContext context) {
    final blurSigma = blur.clamp(0.0, 30.0);
    final a = opacity.clamp(0.0, 1.0);
    final fill = tint.withOpacity(a);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withOpacity(borderOpacity),
              width: borderWidth,
            ),
            boxShadow: boxShadow,
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class DashboardPanel extends StatefulWidget {
  final WorkspaceController? workspaceController;

  const DashboardPanel({super.key, this.workspaceController});

  @override
  State<DashboardPanel> createState() => _DashboardPanelState();
}

class _DashboardPanelState extends State<DashboardPanel> {
  // Persisted keys
  static const _prefsWallpaperKey = 'wallpaper_path';
  static const _prefsGlobalOpacityKey = 'global_widget_opacity';
  static const _prefsGlobalBlurKey = 'global_widget_blur';
  static const _prefsLayoutKey = 'screen_grid_layout';

  // Global screen grid
  final ScreenGridConfig _grid = const ScreenGridConfig(
    columns: 24,
    rows: 14,
  );

  late List<ScreenGridWidgetSpan> _items;

  // null => use default gradient
  String? _wallpaperPath;

  // Global "glass" settings (applied to ALL widgets + top bar)
  double _globalGlassOpacity = 0.12; // 0..1 (glass tint strength)
  double _globalGlassBlur = 16.0; // 0..30 (sigma)
  final Color _globalGlassTint =
      const Color(0xFFFFFFFF); // white tint => macOS-like

  // Auth + permissions
  User? _currentUser;
  Set<String> _allowedWidgetIds = {'login'};

  @override
  void initState() {
    super.initState();

    _items = _defaultItems(); // start with defaults
    _loadSettings();
    _loadLayout(); // load saved layout if any
    _listenAuthState();
  }

  // default layout used on first run / reset
  List<ScreenGridWidgetSpan> _defaultItems() {
    return [
      ScreenGridWidgetSpan(
        widgetId: 'login',
        col: 7,
        row: 3,
        colSpan: 10,
        rowSpan: 8,
      ),
      ScreenGridWidgetSpan(
        widgetId: 'create_task',
        col: 1,
        row: 2,
        colSpan: 10,
        rowSpan: 4,
      ),
      ScreenGridWidgetSpan(
        widgetId: 'view_assigned_tasks',
        col: 13,
        row: 2,
        colSpan: 10,
        rowSpan: 4,
      ),
      ScreenGridWidgetSpan(
        widgetId: 'view_all_tasks',
        col: 1,
        row: 8,
        colSpan: 10,
        rowSpan: 4,
      ),
      ScreenGridWidgetSpan(
        widgetId: 'complete_task',
        col: 13,
        row: 8,
        colSpan: 10,
        rowSpan: 4,
      ),
    ];
  }

  Future<void> _loadLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsLayoutKey);
    if (jsonString == null) {
      debugPrint('[LAYOUT] No saved layout, using defaults');
      return;
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      final loaded = decoded.map((e) {
        final m = e as Map<String, dynamic>;
        return ScreenGridWidgetSpan(
          widgetId: m['id'] as String,
          col: m['col'] as int,
          row: m['row'] as int,
          colSpan: m['colSpan'] as int,
          rowSpan: m['rowSpan'] as int,
        );
      }).toList();

      setState(() {
        _items = loaded;
      });
      debugPrint('[LAYOUT] Loaded ${loaded.length} items');
    } catch (e) {
      debugPrint('[LAYOUT] Failed to parse layout: $e');
    }
  }

  Future<void> _saveLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _items.map((w) {
      return {
        'id': w.widgetId,
        'col': w.col,
        'row': w.row,
        'colSpan': w.colSpan,
        'rowSpan': w.rowSpan,
      };
    }).toList();

    await prefs.setString(_prefsLayoutKey, jsonEncode(data));
    debugPrint('[LAYOUT] Saved layout with ${_items.length} items');
  }

  void _listenAuthState() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      debugPrint('[AUTH] authStateChanges -> ${user?.uid}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (user == null) {
          debugPrint('[AUTH] User is null → show login only');
          setState(() {
            _currentUser = null;
            _allowedWidgetIds = {'login'};
          });
        } else {
          debugPrint('[AUTH] User logged in → load permissions');
          setState(() {
            _currentUser = user;
          });
          _loadUserPermissions(user.uid);
        }
      });
    });
  }

  Future<void> _loadUserPermissions(String userId) async {
    const tenantId = 'default_tenant';
    debugPrint('[PERM] Loading permissions for user=$userId');

    try {
      // 1) Load user doc
      final userDoc = await FirebaseFirestore.instance
          .collection('tenants')
          .doc(tenantId)
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        debugPrint('[PERM] user doc missing → signOut');
        await FirebaseAuth.instance.signOut();
        return;
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final designation = data['designation'] as String?;
      debugPrint('[PERM] designation = $designation');

      if (designation == null) {
        debugPrint('[PERM] designation null → signOut + login only');
        await FirebaseAuth.instance.signOut();
        setState(() => _allowedWidgetIds = {'login'});
        return;
      }

      // 2) Load designation metadata
      final metaDoc = await FirebaseFirestore.instance
          .collection('tenants')
          .doc(tenantId)
          .collection('metadata')
          .doc('designations')
          .get();

      if (!metaDoc.exists) {
        debugPrint('[PERM] designations missing → login only');
        setState(() => _allowedWidgetIds = {'login'});
        return;
      }

      final meta = metaDoc.data() as Map<String, dynamic>;
      final allDesignations =
          meta['designations'] as Map<String, dynamic>?;

      final designationData =
          allDesignations != null ? allDesignations[designation] : null;
      debugPrint('[PERM] designationData = $designationData');

      final List<dynamic> permissionsRaw =
          (designationData?['permissions'] as List<dynamic>?) ?? [];

      final permissions =
          permissionsRaw.map((e) => e.toString()).toSet();
      debugPrint('[PERM] permissions = $permissions');

      // 3) Map permissions → widget ids used in DashboardPanel
      final allowed = <String>{};

      if (permissions.contains('create_task')) {
        allowed.add('create_task');
      }
      if (permissions.contains('view_assigned_tasks')) {
        allowed.add('view_assigned_tasks');
      }
      if (permissions.contains('view_all_tasks')) {
        allowed.add('view_all_tasks');
      }
      if (permissions.contains('complete_task')) {
        allowed.add('complete_task');
      }

      debugPrint('[PERM] allowed widget ids = $allowed');

      // 4) Logged-in view: DO NOT include 'login'
      setState(() => _allowedWidgetIds = allowed);
    } catch (e) {
      debugPrint('[PERM] Permission load error: $e');
      setState(() => _allowedWidgetIds = {'login'});
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _wallpaperPath = prefs.getString(_prefsWallpaperKey);
    _globalGlassOpacity = prefs.getDouble(_prefsGlobalOpacityKey) ?? 0.12;
    _globalGlassBlur = prefs.getDouble(_prefsGlobalBlurKey) ?? 16.0;
    debugPrint(
        'LOADED wallpaper=$_wallpaperPath blur=$_globalGlassBlur opacity=$_globalGlassOpacity');

    if (mounted) setState(() {});
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (_wallpaperPath != null) {
      await prefs.setString(_prefsWallpaperKey, _wallpaperPath!);
    } else {
      await prefs.remove(_prefsWallpaperKey);
    }

    await prefs.setDouble(_prefsGlobalOpacityKey, _globalGlassOpacity);
    await prefs.setDouble(_prefsGlobalBlurKey, _globalGlassBlur);
    debugPrint(
        'SAVED wallpaper=$_wallpaperPath blur=$_globalGlassBlur opacity=$_globalGlassOpacity');
  }

  void toggleWidget(String widgetId) {
    final index = _items.indexWhere((w) => w.widgetId == widgetId);
    if (index != -1) {
      setState(() => _items.removeAt(index));
    } else {
      setState(() {
        _items.add(
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
    _saveLayout();
  }

  Future<void> _pickWallpaperFromWindows() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    final pickedPath = result?.files.single.path;
    if (pickedPath == null) return;

    final appDir = await getApplicationSupportDirectory();
    final wpDir = Directory(p.join(appDir.path, 'wallpapers'));
    if (!await wpDir.exists()) {
      await wpDir.create(recursive: true);
    }

    final ext =
        p.extension(pickedPath).isNotEmpty ? p.extension(pickedPath) : '.jpg';
    final cachedPath = p.join(wpDir.path, 'current_wallpaper$ext');

    await File(pickedPath).copy(cachedPath);

    setState(() => _wallpaperPath = cachedPath);
    await _saveSettings();
  }

  Future<void> _resetWallpaper() async {
    setState(() => _wallpaperPath = null);
    await _saveSettings();
  }

  BoxDecoration _backgroundDecoration() {
    final path = _wallpaperPath;
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        return BoxDecoration(
          image: DecorationImage(
            image: FileImage(file),
            fit: BoxFit.cover,
          ),
        );
      }
    }

    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF05040A), Color(0xFF151827)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  Future<void> _openGlobalGlassSheet() async {
    double tempOpacity = _globalGlassOpacity;
    double tempBlur = _globalGlassBlur;

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
                    Row(
                      children: const [
                        Icon(Icons.blur_on_rounded,
                            color: Colors.cyanAccent, size: 18),
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
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            min: 0.04,
                            max: 0.30,
                            divisions: 26,
                            value: tempOpacity.clamp(0.04, 0.30),
                            label: tempOpacity.toStringAsFixed(2),
                            onChanged: (v) =>
                                setModalState(() => tempOpacity = v),
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
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            min: 0,
                            max: 30,
                            divisions: 30,
                            value: tempBlur.clamp(0, 30),
                            label: tempBlur.toStringAsFixed(0),
                            onChanged: (v) =>
                                setModalState(() => tempBlur = v),
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
      setState(() {
        _globalGlassOpacity = tempOpacity;
        _globalGlassBlur = tempBlur;
      });
      await _saveSettings();
    }
  }

  @override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, root) {
      final width = root.maxWidth;
      final height = root.maxHeight;
      final shortest = width < height ? width : height;

      final double scale =
          shortest < 700 ? 0.7 : (shortest < 1100 ? 0.9 : 1.1);

      final horizontalPadding = 24.0 * scale;
      final verticalPadding = 12.0 * scale;
      final mainSpacing = 12.0 * scale;
      final topBarHeight = 40.0;
      final chipHeight = 32.0 * scale;

      final visibleItems = _items
          .where((item) => _allowedWidgetIds.contains(item.widgetId))
          .toList();

      debugPrint(
        '[UI] currentUser=${_currentUser?.uid} '
        'allowed=$_allowedWidgetIds '
        'visible=${visibleItems.map((e) => e.widgetId).toList()}',
      );

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: _backgroundDecoration(),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                children: [
                  // TOP BAR (fixed height + centered WorkspaceSwitcher)
                  SizedBox(
                    height: topBarHeight,
                    child: GlassContainer(
                      blur: _globalGlassBlur,
                      opacity: _globalGlassOpacity,
                      tint: _globalGlassTint,
                      borderRadius: BorderRadius.circular(topBarHeight / 2),
                      padding: EdgeInsets.symmetric(horizontal: 14.0 * scale),
                      borderOpacity: 0.16,
                      borderWidth: 1,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x2A000000),
                          blurRadius: 14,
                          offset: Offset(0, 8),
                        ),
                      ],
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // LEFT: title
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.blur_on_rounded,
                                  size: 14 * scale,
                                  color: Colors.cyan,
                                ),
                                SizedBox(width: 6 * scale),
                                Text(
                                  'Wall-D · Dynamic Screen',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12 * scale,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // CENTER: workspace tabs (Dashboard / Task)
                          if (widget.workspaceController != null)
                            Align(
                              alignment: Alignment.center,
                              child: WorkspaceSwitcher(
                                controller: widget.workspaceController!,
                              ),
                            ),

                          // RIGHT: actions
                          Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_currentUser != null)
                                  IconButton(
                                    tooltip: 'Sign out',
                                    icon: Icon(
                                      Icons.logout,
                                      size: 16 * scale,
                                      color: Colors.white70,
                                    ),
                                    onPressed: _signOut,
                                  ),
                                Icon(
                                  Icons.cloud_done,
                                  size: 13 * scale,
                                  color: Colors.greenAccent,
                                ),
                                SizedBox(width: 4 * scale),
                                Text(
                                  'default_tenant',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11 * scale,
                                  ),
                                ),
                                SizedBox(width: 6 * scale),
                                PopupMenuButton<_SettingsAction>(
                                  tooltip: 'Settings',
                                  padding: EdgeInsets.zero,
                                  offset: Offset(0, topBarHeight + 8),
                                  color: const Color(0xFF0B0B12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                      color: Color(0x33FFFFFF),
                                    ),
                                  ),
                                  onSelected: (action) async {
                                    switch (action) {
                                      case _SettingsAction.pickWallpaper:
                                        await _pickWallpaperFromWindows();
                                        break;
                                      case _SettingsAction.resetWallpaper:
                                        await _resetWallpaper();
                                        break;
                                      case _SettingsAction.glassSettings:
                                        await _openGlobalGlassSheet();
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: _SettingsAction.pickWallpaper,
                                      child: _MenuRow(
                                        icon: Icons.wallpaper,
                                        text: 'Change wallpaper…',
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: _SettingsAction.resetWallpaper,
                                      child: _MenuRow(
                                        icon: Icons.refresh_rounded,
                                        text: 'Reset wallpaper',
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: _SettingsAction.glassSettings,
                                      child: _MenuRow(
                                        icon: Icons.blur_on_rounded,
                                        text: 'Glass settings…',
                                      ),
                                    ),
                                  ],
                                  child: Padding(
                                    padding: EdgeInsets.all(4 * scale),
                                    child: Icon(
                                      Icons.settings_rounded,
                                      size: 16 * scale,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: mainSpacing),

                  // STATIC CHIPS (disabled)
                  // if (false) ...[ ... ],

                  // MAIN AREA (grid widgets)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxW = constraints.maxWidth;
                        final maxH = constraints.maxHeight;

                        final cellW = maxW / _grid.columns;
                        final cellH = maxH / _grid.rows;

                        return Stack(
                          children: visibleItems
                              .map(
                                (item) => _buildGridWidget(
                                  item: item,
                                  cellW: cellW,
                                  cellH: cellH,
                                  maxW: maxW,
                                  maxH: maxH,
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

  Widget _buildGridWidget({
    required ScreenGridWidgetSpan item,
    required double cellW,
    required double cellH,
    required double maxW,
    required double maxH,
  }) {
    final left = (item.col * cellW).clamp(0.0, maxW - cellW);
    final top = (item.row * cellH).clamp(0.0, maxH - cellH);

    final widthPx = (item.colSpan * cellW).clamp(cellW * 2, maxW);
    final heightPx = (item.rowSpan * cellH).clamp(cellH * 2, maxH);

    return _FreeDragResizeItem(
      key: ValueKey(item.widgetId),
      item: item,
      gridColumns: _grid.columns,
      gridRows: _grid.rows,
      cellW: cellW,
      cellH: cellH,
      maxW: maxW,
      maxH: maxH,
      initialLeft: left,
      initialTop: top,
      initialWidthPx: widthPx,
      initialHeightPx: heightPx,
      globalBlur: _globalGlassBlur,
      globalOpacity: _globalGlassOpacity,
      globalTint: _globalGlassTint,
      onSnap: _saveLayout,
    );
  }
}

enum _SettingsAction { pickWallpaper, resetWallpaper, glassSettings }

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MenuRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.cyanAccent),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

class _FreeDragResizeItem extends StatefulWidget {
  final ScreenGridWidgetSpan item;

  final int gridColumns;
  final int gridRows;

  final double cellW;
  final double cellH;

  final double maxW;
  final double maxH;

  final double initialLeft;
  final double initialTop;
  final double initialWidthPx;
  final double initialHeightPx;

  final double globalBlur;
  final double globalOpacity;
  final Color globalTint;

  final VoidCallback onSnap;

  const _FreeDragResizeItem({
    super.key,
    required this.item,
    required this.gridColumns,
    required this.gridRows,
    required this.cellW,
    required this.cellH,
    required this.maxW,
    required this.maxH,
    required this.initialLeft,
    required this.initialTop,
    required this.initialWidthPx,
    required this.initialHeightPx,
    required this.globalBlur,
    required this.globalOpacity,
    required this.globalTint,
    required this.onSnap,
  });

  @override
  State<_FreeDragResizeItem> createState() => _FreeDragResizeItemState();
}

class _FreeDragResizeItemState extends State<_FreeDragResizeItem> {
  late double left;
  late double top;
  late double widthPx;
  late double heightPx;

  Offset? dragLastGlobal;
  Offset? resizeLastGlobal;

  bool get isInteracting => dragLastGlobal != null || resizeLastGlobal != null;

  @override
  void initState() {
    super.initState();
    left = widget.initialLeft;
    top = widget.initialTop;
    widthPx = widget.initialWidthPx;
    heightPx = widget.initialHeightPx;
  }

  @override
  void didUpdateWidget(covariant _FreeDragResizeItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!isInteracting) {
      left = (widget.item.col * widget.cellW)
          .clamp(0.0, widget.maxW - widget.cellW);
      top = (widget.item.row * widget.cellH)
          .clamp(0.0, widget.maxH - widget.cellH);

      widthPx = (widget.item.colSpan * widget.cellW)
          .clamp(widget.cellW * 2, widget.maxW);
      heightPx = (widget.item.rowSpan * widget.cellH)
          .clamp(widget.cellH * 2, widget.maxH);
    }
  }

  void _snapToGridAndPersist() {
    int col = (left / widget.cellW).round();
    int row = (top / widget.cellH).round();
    int colSpan = (widthPx / widget.cellW).round();
    int rowSpan = (heightPx / widget.cellH).round();

    colSpan = colSpan.clamp(2, widget.gridColumns) as int;
    rowSpan = rowSpan.clamp(2, widget.gridRows) as int;

    col = col.clamp(0, widget.gridColumns - colSpan) as int;
    row = row.clamp(0, widget.gridRows - rowSpan) as int;

    widget.item
      ..col = col
      ..row = row
      ..colSpan = colSpan
      ..rowSpan = rowSpan;

    setState(() {
      left = col * widget.cellW;
      top = row * widget.cellH;
      widthPx = colSpan * widget.cellW;
      heightPx = rowSpan * widget.cellH;
    });

    widget.onSnap(); // persist layout in parent
  }

  @override
  Widget build(BuildContext context) {
    final content = WidgetFactory.createWidget(widget.item.widgetId);

    final glassCard = GlassContainer(
      blur: widget.globalBlur,
      opacity: widget.globalOpacity,
      tint: widget.globalTint,
      borderRadius: BorderRadius.circular(24),
      child: content,
    );

    const hitHandleSize = 24.0;

    return Positioned(
      left: left.clamp(0.0, widget.maxW - widthPx),
      top: top.clamp(0.0, widget.maxH - heightPx),
      width: widthPx.clamp(widget.cellW * 2, widget.maxW),
      height: heightPx.clamp(widget.cellH * 2, widget.maxH),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          final local = details.localPosition;
          final isResize =
              local.dx > (widthPx - hitHandleSize) &&
              local.dy > (heightPx - hitHandleSize);

          if (isResize) {
            resizeLastGlobal = details.globalPosition;
          } else {
            dragLastGlobal = details.globalPosition;
          }
        },
        onPanUpdate: (details) {
          setState(() {
            if (resizeLastGlobal != null) {
              final delta = details.globalPosition - resizeLastGlobal!;
              widthPx = (widthPx + delta.dx)
                  .clamp(widget.cellW * 2, widget.maxW - left);
              heightPx = (heightPx + delta.dy)
                  .clamp(widget.cellH * 2, widget.maxH - top);
              resizeLastGlobal = details.globalPosition;
            } else if (dragLastGlobal != null) {
              final delta = details.globalPosition - dragLastGlobal!;
              left = (left + delta.dx)
                  .clamp(0.0, widget.maxW - widthPx);
              top = (top + delta.dy)
                  .clamp(0.0, widget.maxH - heightPx);
              dragLastGlobal = details.globalPosition;
            }
          });
        },
        onPanEnd: (_) {
          dragLastGlobal = null;
          resizeLastGlobal = null;
          _snapToGridAndPersist();
        },
        onPanCancel: () {
          dragLastGlobal = null;
          resizeLastGlobal = null;
          _snapToGridAndPersist();
        },
        child: Stack(
          children: [
            Positioned.fill(child: glassCard),

            // RESIZE HANDLE WITH RESIZE CURSOR
            Positioned(
              right: 4,
              bottom: 4,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeDownRight,
                child: Container(
                  width: hitHandleSize,
                  height: hitHandleSize,
                  alignment: Alignment.bottomRight,
                  color: Colors.transparent, // keeps hit-test area
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      // color: Colors.cyanAccent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
