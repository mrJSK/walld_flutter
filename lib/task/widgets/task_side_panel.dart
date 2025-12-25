import 'package:flutter/material.dart';
import '../../core/glass_container.dart';
import '../../core/wallpaper_service.dart';
import '../task_tabs_manifest.dart';

class TaskSidePanel extends StatelessWidget {
  final String selectedTabId;
  final ValueChanged<String> onSelect;

  const TaskSidePanel({
    super.key,
    required this.selectedTabId,
    required this.onSelect,
  });
  @override
  Widget build(BuildContext context) {
    final wallpaper = WallpaperService.instance;
    return GlassContainer(
      blur: wallpaper.globalGlassBlur,
      opacity: wallpaper.globalGlassOpacity * 0.7,
      tint: Colors.white,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          const SizedBox(height: 6),
          const Text('TASK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                for (final t in taskTabs)
                  _item(
                    selected: selectedTabId == t.id,
                    icon: t.icon,
                    title: t.title,
                    onTap: () => onSelect(t.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item({
    required bool selected,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final fg = selected ? Colors.cyanAccent : Colors.white70;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.cyan.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.cyanAccent.withOpacity(0.5) : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: fg, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
