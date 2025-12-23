import 'package:flutter/material.dart';

import 'model/screen_grid.dart';

class DashboardDrawer extends StatelessWidget {
  final Set<String> allowedWidgetIds;
  final List<ScreenGridWidgetSpan> items;
  final void Function(String widgetId) onToggleWidget;

  const DashboardDrawer({
    super.key,
    required this.allowedWidgetIds,
    required this.items,
    required this.onToggleWidget,
  });

  bool _isVisible(String id) {
    return items.any((w) => w.widgetId == id);
  }

  @override
  Widget build(BuildContext context) {
    // If only login is allowed, drawer can stay hidden
    if (allowedWidgetIds.length == 1 && allowedWidgetIds.contains('login')) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 16,
      top: 64,
      bottom: 16,
      child: MouseRegion(
        opaque: false,
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            width: 220,
            decoration: BoxDecoration(
              color: const Color(0xCC05040A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Widgets',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      if (allowedWidgetIds.contains('createtask'))
                        _item(
                          id: 'createtask',
                          label: 'Create Task',
                          icon: Icons.add_task_rounded,
                        ),
                      if (allowedWidgetIds.contains('viewassignedtasks'))
                        _item(
                          id: 'viewassignedtasks',
                          label: 'Assigned Tasks',
                          icon: Icons.assignment_ind_rounded,
                        ),
                      if (allowedWidgetIds.contains('viewalltasks'))
                        _item(
                          id: 'viewalltasks',
                          label: 'All Tasks',
                          icon: Icons.view_list_rounded,
                        ),
                      if (allowedWidgetIds.contains('completetask'))
                        _item(
                          id: 'completetask',
                          label: 'Complete Task',
                          icon: Icons.check_circle_rounded,
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

  Widget _item({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final visible = _isVisible(id);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        size: 18,
        color: visible ? Colors.cyanAccent : Colors.white70,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: visible ? Colors.cyanAccent : Colors.white70,
          fontSize: 13,
        ),
      ),
      trailing: Switch(
        value: visible,
        activeColor: Colors.cyanAccent,
        onChanged: (_) => onToggleWidget(id),
      ),
      onTap: () => onToggleWidget(id),
    );
  }
}
