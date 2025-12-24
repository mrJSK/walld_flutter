import 'package:flutter/material.dart';
import '../core/glass_container.dart'; // Make sure this path is correct
import 'workspace_controller.dart';
import 'workspace_ids.dart';

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
    // This rebuilds the widget when the controller changes (to update active tabs)
    return ListenableBuilder(
      listenable: workspaceController,
      builder: (context, child) {
        // The top bar is an Align to keep it at the top-center
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Padding from screen edges
            
            // The main container for the top bar
            child: GlassContainer(
              // --- EXACT UI from TaskWorkspace ---
              blur: 15,
              opacity: 0.1,
              tint: Colors.white,
              borderOpacity: 0.1,
              borderRadius: BorderRadius.circular(16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              // -----------------------------------

              child: Row(
                children: [
                  // --- 1. Navigation Tabs (Left) ---
                  _buildTabButton('Dashboard', WorkspaceIds.dashboard),
                  const SizedBox(width: 16),
                  _buildTabButton('Tasks', WorkspaceIds.task),

                  const Spacer(), // Pushes actions to the right

                  // --- 2. Action Buttons (Right) ---
                  _buildActionButton(
                    Icons.wallpaper_outlined,
                    'Wallpaper',
                    onWallpaperSettings,
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    Icons.blur_on_outlined,
                    'Glass',
                    onGlassSettings,
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    Icons.logout_outlined,
                    'Sign Out',
                    onSignOut,
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // A simple text button for navigation tabs
  Widget _buildTabButton(String label, String id) {
    final bool isActive = workspaceController.current == id;

    return InkWell(
      onTap: () => workspaceController.switchTo(id),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white60,
            fontSize: 16,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // A text+icon button for actions like settings and logout
  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.redAccent : Colors.white70;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}