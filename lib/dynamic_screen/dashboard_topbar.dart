import 'package:flutter/material.dart';

import '../workspace/workspace_controller.dart';
import '../workspace/workspace_switcher.dart';

class DashboardTopBar extends StatelessWidget {
  final WorkspaceController? workspaceController;
  final VoidCallback onGlassSettings;
  final VoidCallback onWallpaperSettings;
  final VoidCallback onResetWallpaper;
  final Future<void> Function() onSignOut;

  const DashboardTopBar({
    super.key,
    required this.workspaceController,
    required this.onGlassSettings,
    required this.onWallpaperSettings,
    required this.onResetWallpaper,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      top: 12,
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            // Left: App title
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.blur_on_rounded, color: Colors.cyan, size: 18),
                SizedBox(width: 8),
                Text(
                  'Wall-D Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Center: Workspace switcher
            if (workspaceController != null)
              WorkspaceSwitcher(controller: workspaceController!),
            const Spacer(),
            // Right: actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.wallpaper_rounded,
                      color: Colors.white70, size: 18),
                  tooltip: 'Change wallpaper',
                  onPressed: onWallpaperSettings,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: Colors.white70, size: 18),
                  tooltip: 'Reset wallpaper',
                  onPressed: onResetWallpaper,
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded,
                      color: Colors.white70, size: 18),
                  tooltip: 'Glass settings',
                  onPressed: onGlassSettings,
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      color: Colors.white70, size: 18),
                  tooltip: 'Sign out',
                  onPressed: () => onSignOut(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
