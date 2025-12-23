import 'package:flutter/material.dart';
import '../core/glass_container.dart';
import 'workspace_controller.dart';
import 'workspace_ids.dart';

class WorkspaceSwitcher extends StatelessWidget {
  final WorkspaceController controller;

  const WorkspaceSwitcher({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final current = controller.current;

        return GlassContainer(
          blur: 16,
          opacity: 0.10,
          tint: Colors.white,
          borderRadius: BorderRadius.circular(999),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pillIcon(
                selected: current == WorkspaceIds.dashboard,
                icon: Icons.dashboard_customize_rounded,
                tooltip: 'Dashboard',
                onTap: () => controller.setWorkspace(WorkspaceIds.dashboard),
              ),
              const SizedBox(width: 6),
              _pillIcon(
                selected: current == WorkspaceIds.task,
                icon: Icons.task_alt_rounded,
                tooltip: 'Task',
                onTap: () => controller.setWorkspace(WorkspaceIds.task),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pillIcon({
    required bool selected,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final fg = selected ? Colors.cyanAccent : Colors.white70;
    final bg = selected ? Colors.cyan.withOpacity(0.16) : Colors.transparent;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.cyanAccent.withOpacity(0.6) : Colors.white24,
              width: 1,
            ),
          ),
          child: Icon(icon, size: 18, color: fg),
        ),
      ),
    );
  }
}
