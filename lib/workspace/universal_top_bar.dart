import 'package:flutter/material.dart';

import '../core/glass_container.dart';
import '../workspace/workspace_switcher.dart';
import 'workspace_controller.dart';
import '../core/wallpaper_service.dart';

class UniversalTopBar extends StatelessWidget {
  final WorkspaceController workspaceController;
  final VoidCallback onWallpaperSettings;
  final VoidCallback onGlassSettings;
  final VoidCallback onSignOut;

  const UniversalTopBar({
    super.key,
    required this.workspaceController,
    required this.onWallpaperSettings,
    required this.onGlassSettings,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: WallpaperService.instance,
      builder: (context, _) {
        final ws = WallpaperService.instance;
        final double glassBlur = ws.globalGlassBlur;
        final double glassOpacity = ws.globalGlassOpacity;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: SizedBox(
              height: 40,
              child: GlassContainer(
                blur: glassBlur,  // NOW REACTIVE
                opacity: glassOpacity,  // NOW REACTIVE
                tint: Colors.white,
                borderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                blurMode: GlassBlurMode.perWidget,  // FORCE BLUR (top bar is tiny)
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // LEFT: Branding
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.blur_on_rounded,
                            color: Colors.cyan,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Wall-D Workspace',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // CENTER: Workspace Switcher
                    Align(
                      alignment: Alignment.center,
                      child: WorkspaceSwitcher(
                        controller: workspaceController,
                      ),
                    ),

                    // RIGHT: Settings & Actions
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.wallpaper_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                            tooltip: 'Wallpaper settings',
                            onPressed: onWallpaperSettings,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.tune_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                            tooltip: 'Glass settings',
                            onPressed: onGlassSettings,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.logout_rounded,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            tooltip: 'Sign out',
                            onPressed: onSignOut,
                          ),
                        ],
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
}
