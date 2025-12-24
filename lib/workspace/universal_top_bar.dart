import 'package:flutter/material.dart';
import '../core/glass_container.dart';
import '../workspace/workspace_switcher.dart'; // Imported to match TaskWorkspace layout
import 'workspace_controller.dart';

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
    // Hardcoded values to match the TaskWorkspace defaults
    const double glassBlur = 18.0;
    const double glassOpacity = 0.16;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
        child: SizedBox(
          height: 40,
          child: GlassContainer(
            blur: glassBlur,
            opacity: glassOpacity,
            tint: Colors.white,
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
                        'Wall-D Workspace', // Adjusted title for universal context
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
                      // Wallpaper Settings
                      IconButton(
                        icon: const Icon(
                          Icons.wallpaper_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                        tooltip: 'Wallpaper settings',
                        onPressed: onWallpaperSettings,
                      ),
                      // Glass Settings
                      IconButton(
                        icon: const Icon(
                          Icons.tune_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                        tooltip: 'Glass settings',
                        onPressed: onGlassSettings,
                      ),
                      // Sign Out (Added to maintain functionality in new design)
                      IconButton(
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.redAccent, // Distinct color for destructive action
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
  }
}