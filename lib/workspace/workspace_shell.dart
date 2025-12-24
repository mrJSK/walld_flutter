import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/scheduler.dart';
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
  // Animation controller
  late AnimationController _animationController;
  late Animation<Offset> _outgoingSlide;
  late Animation<Offset> _incomingSlide;
  late Animation<double> _outgoingFade;
  late Animation<double> _incomingFade;
  
  // Screen indices
  int _currentIndex = 0;
  int _previousIndex = 0;
  
  // Animation state
  bool _isAnimating = false;
  bool _isForward = true;
  
  // Performance tracking
  bool _isLowEndDevice = false;
  
  // FPS Monitoring
  double _currentFPS = 60.0;
  int _frameCount = 0;
  Duration _lastFrameTime = Duration.zero;
  final List<double> _fpsHistory = [];
  bool _showFPS = true; // Toggle this to hide FPS counter

  @override
  void initState() {
    super.initState();
    
    _initWallpaperService();
    _startFPSMonitoring();
    
    // Initialize animation controller with optimal duration
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400), // Slightly faster for smoothness
      vsync: this,
    );
    
    // Setup initial animations
    _setupAnimations();
    
    // Listen to animation status
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        if (mounted) setState(() => _isAnimating = true);
      } else if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isAnimating = false;
            _previousIndex = _currentIndex;
          });
        }
      }
    });
    
    widget.workspaceController.addListener(_onWorkspaceChanged);
  }

  void _setupAnimations() {
    // Ultra-smooth curve for 60 FPS
    const curve = Curves.easeInOutCubicEmphasized;
    
    // Outgoing screen slides OUT (left if forward, right if backward)
    _outgoingSlide = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(_isForward ? -1.0 : 1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: curve,
    ));
    
    // Incoming screen slides IN (from right if forward, from left if backward)
    _incomingSlide = Tween<Offset>(
      begin: Offset(_isForward ? 1.0 : -1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: curve,
    ));
    
    // Outgoing screen fades out quickly
    _outgoingFade = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    // Incoming screen fades in gradually
    _incomingFade = Tween<double>(
      begin: 0.2,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.1, 0.8, curve: Curves.easeIn),
    ));
  }

  void _startFPSMonitoring() {
    SchedulerBinding.instance.addPostFrameCallback(_measureFPS);
  }

  void _measureFPS(Duration timestamp) {
    if (!mounted) return;
    
    if (_lastFrameTime != Duration.zero) {
      final delta = timestamp - _lastFrameTime;
      final fps = 1000000.0 / delta.inMicroseconds; // Convert to FPS
      
      _fpsHistory.add(fps);
      if (_fpsHistory.length > 30) {
        _fpsHistory.removeAt(0); // Keep last 30 frames
      }
      
      // Calculate average FPS
      final avgFPS = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
      
      // Update UI every 10 frames
      _frameCount++;
      if (_frameCount % 10 == 0 && mounted) {
        setState(() {
          _currentFPS = avgFPS;
          
          // Auto-detect low-end device
          if (avgFPS < 50 && !_isLowEndDevice) {
            _isLowEndDevice = true;
            _animationController.duration = const Duration(milliseconds: 300);
            debugPrint('🐌 Low FPS detected ($avgFPS). Enabling optimization mode.');
          }
        });
      }
    }
    
    _lastFrameTime = timestamp;
    SchedulerBinding.instance.addPostFrameCallback(_measureFPS);
  }

  Future<void> _initWallpaperService() async {
    await WallpaperService.instance.loadSettings();
    WallpaperService.instance.addListener(_onWallpaperChanged);
  }

  void _onWallpaperChanged() {
    if (mounted) setState(() {});
  }

  void _onWorkspaceChanged() {
    final newIndex = getCurrentIndex();
    
    if (newIndex != _currentIndex && !_isAnimating) {
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex = newIndex;
        _isForward = newIndex > _previousIndex;
        
        // Update animations with new direction
        _setupAnimations();
      });
      
      // Start animation immediately for instant response
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    WallpaperService.instance.removeListener(_onWallpaperChanged);
    widget.workspaceController.removeListener(_onWorkspaceChanged);
    super.dispose();
  }

  int getCurrentIndex() {
    return widget.workspaceController.current == WorkspaceIds.task ? 1 : 0;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 🎨 FIXED WALLPAPER BACKGROUND (Never moves)
          Positioned.fill(
            child: Container(
              decoration: WallpaperService.instance.backgroundDecoration,
            ),
          ),
          
          // 📱 ANIMATED SCREENS WITH ULTRA-SMOOTH SLIDING
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Stack(
                  children: [
                    // ============================================
                    // DASHBOARD PANEL (Index 0)
                    // ============================================
                    Positioned.fill(
                      child: Visibility(
                        visible: _currentIndex == 0 || _isAnimating,
                        maintainState: true,    // 🔥 KEEPS IN RAM
                        maintainAnimation: true,
                        maintainSize: false,
                        child: SlideTransition(
                          position: _currentIndex == 0 ? _incomingSlide : _outgoingSlide,
                          child: FadeTransition(
                            opacity: _currentIndex == 0 ? _incomingFade : _outgoingFade,
                            child: RepaintBoundary(
                              child: DashboardPanel(
                                key: const PageStorageKey('dashboardpanel'),
                                workspaceController: widget.workspaceController,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // ============================================
                    // TASK WORKSPACE (Index 1)
                    // ============================================
                    Positioned.fill(
                      child: Visibility(
                        visible: _currentIndex == 1 || _isAnimating,
                        maintainState: true,    // 🔥 KEEPS IN RAM
                        maintainAnimation: true,
                        maintainSize: false,
                        child: SlideTransition(
                          position: _currentIndex == 1 ? _incomingSlide : _outgoingSlide,
                          child: FadeTransition(
                            opacity: _currentIndex == 1 ? _incomingFade : _outgoingFade,
                            child: RepaintBoundary(
                              child: TaskWorkspace(
                                key: const PageStorageKey('taskworkspace'),
                                workspaceController: widget.workspaceController,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // 🔝 FIXED UNIVERSAL TOP BAR
          RepaintBoundary(
            child: UniversalTopBar(
              workspaceController: widget.workspaceController,
              onWallpaperSettings: pickWallpaperFromWindows,
              onGlassSettings: openGlobalGlassSheet,
              onSignOut: signOut,
            ),
          ),
          
          // 📊 FPS COUNTER OVERLAY
          if (_showFPS)
            Positioned(
              top: 60,
              right: 16,
              child: _FPSCounter(
                fps: _currentFPS,
                isAnimating: _isAnimating,
                isLowEnd: _isLowEndDevice,
                onToggle: () => setState(() => _showFPS = !_showFPS),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================
// FPS COUNTER WIDGET
// ============================================
class _FPSCounter extends StatelessWidget {
  final double fps;
  final bool isAnimating;
  final bool isLowEnd;
  final VoidCallback onToggle;

  const _FPSCounter({
    required this.fps,
    required this.isAnimating,
    required this.isLowEnd,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Color based on FPS
    Color fpsColor;
    String status;
    
    if (fps >= 58) {
      fpsColor = Colors.greenAccent;
      status = 'EXCELLENT';
    } else if (fps >= 50) {
      fpsColor = Colors.yellowAccent;
      status = 'GOOD';
    } else if (fps >= 40) {
      fpsColor = Colors.orangeAccent;
      status = 'FAIR';
    } else {
      fpsColor = Colors.redAccent;
      status = 'LOW';
    }

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: fpsColor.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: fpsColor.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.speed, color: fpsColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${fps.toStringAsFixed(1)} FPS',
                  style: TextStyle(
                    color: fpsColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: fpsColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  status,
                  style: TextStyle(
                    color: fpsColor.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            if (isAnimating) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'ANIMATING',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            if (isLowEnd) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune, color: Colors.orangeAccent, size: 10),
                  const SizedBox(width: 4),
                  const Text(
                    'OPTIMIZED MODE',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
