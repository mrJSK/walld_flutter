import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/wallpaper_service.dart';
import '../dynamic_screen/dashboardpanel.dart';
import '../task/task_workspace.dart';
import 'universal_top_bar.dart';
import 'workspace_controller.dart';
import 'workspace_ids.dart';


class WorkspaceShell extends StatefulWidget {
  final WorkspaceController workspaceController;

  const WorkspaceShell({
    super.key,
    required this.workspaceController,
  });

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  int _currentIndex = 0;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Load wallpaper service
    _initWallpaperService();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Setup animations
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubicEmphasized,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    
    widget.workspaceController.addListener(onWorkspaceChanged);
  }

  Future<void> _initWallpaperService() async {
    await WallpaperService.instance.loadSettings();
    WallpaperService.instance.addListener(_onWallpaperChanged);
  }

  void _onWallpaperChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    WallpaperService.instance.removeListener(_onWallpaperChanged);
    widget.workspaceController.removeListener(onWorkspaceChanged);
    super.dispose();
  }

  void onWorkspaceChanged() {
    final newIndex = getCurrentIndex();
    
    if (newIndex != _currentIndex) {
      _previousIndex = _currentIndex;
      _currentIndex = newIndex;
      
      final isForward = newIndex > _previousIndex;
      
      setState(() {
        _slideAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: Offset(isForward ? -1.0 : 1.0, 0.0),
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOutCubicEmphasized,
        ));
      });
      
      _animationController.forward(from: 0.0);
    }
  }

  Future<void> pickWallpaperFromWindows() async {
    await WallpaperService.instance.pickWallpaper();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
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
                        Icon(Icons.blur_on_rounded, color: Colors.cyanAccent, size: 18),
                        SizedBox(width: 8),
                        Text('Glass settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const SizedBox(width: 70, child: Text('Opacity', style: TextStyle(color: Colors.white70, fontSize: 12))),
                        Expanded(
                          child: Slider(
                            min: 0.04,
                            max: 0.30,
                            divisions: 26,
                            value: tempOpacity.clamp(0.04, 0.30),
                            label: tempOpacity.toStringAsFixed(2),
                            onChanged: (v) => setModalState(() => tempOpacity = v),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 70, child: Text('Blur', style: TextStyle(color: Colors.white70, fontSize: 12))),
                        Expanded(
                          child: Slider(
                            min: 0,
                            max: 30,
                            divisions: 30,
                            value: tempBlur.clamp(0, 30),
                            label: tempBlur.toStringAsFixed(0),
                            onChanged: (v) => setModalState(() => tempBlur = v),
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

  int getCurrentIndex() {
    if (widget.workspaceController.current == WorkspaceIds.task) {
      return 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 🎨 FIXED WALLPAPER LAYER (Never moves/animates)
          Positioned.fill(
            child: Container(
              decoration: WallpaperService.instance.backgroundDecoration,
            ),
          ),
          
          // 📱 Animated Content Screens (Transparent backgrounds)
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Stack(
                children: [
                  // Dashboard (index 0)
                  Offstage(
                    offstage: _currentIndex != 0 && _animationController.value == 1.0,
                    child: SlideTransition(
                      position: _currentIndex == 0
                          ? Tween<Offset>(
                              begin: Offset(_previousIndex > 0 ? -1.0 : 1.0, 0.0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _animationController,
                              curve: Curves.easeInOutCubicEmphasized,
                            ))
                          : _slideAnimation,
                      child: FadeTransition(
                        opacity: _currentIndex == 0
                            ? Tween<double>(begin: 0.0, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: _animationController,
                                  curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
                                ),
                              )
                            : _fadeAnimation,
                        child: DashboardPanel(
                          key: const PageStorageKey('dashboardpanel'),
                          workspaceController: widget.workspaceController,
                        ),
                      ),
                    ),
                  ),
                  
                  // Task Workspace (index 1)
                  Offstage(
                    offstage: _currentIndex != 1 && _animationController.value == 1.0,
                    child: SlideTransition(
                      position: _currentIndex == 1
                          ? Tween<Offset>(
                              begin: Offset(_previousIndex < 1 ? 1.0 : -1.0, 0.0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _animationController,
                              curve: Curves.easeInOutCubicEmphasized,
                            ))
                          : _slideAnimation,
                      child: FadeTransition(
                        opacity: _currentIndex == 1
                            ? Tween<double>(begin: 0.0, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: _animationController,
                                  curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
                                ),
                              )
                            : _fadeAnimation,
                        child: TaskWorkspace(
                          key: const PageStorageKey('taskworkspace'),
                          workspaceController: widget.workspaceController,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // 🔝 FIXED UNIVERSAL TOP BAR
          UniversalTopBar(
            workspaceController: widget.workspaceController,
            onWallpaperSettings: pickWallpaperFromWindows,
            onGlassSettings: openGlobalGlassSheet,
            onSignOut: signOut,
          ),
        ],
      ),
    );
  }
}
