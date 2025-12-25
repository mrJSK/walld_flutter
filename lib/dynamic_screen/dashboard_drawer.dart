import 'package:flutter/material.dart';

import 'repository/dashboard_repository.dart';

class DashboardDrawer extends StatelessWidget {
  final Set<String> allowedWidgetIds;
  final List items;
  // No toggle callback any more.

  const DashboardDrawer({
    super.key,
    required this.allowedWidgetIds,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    // If you still want to hide the drawer when only login is allowed, keep this.
    if (allowedWidgetIds.length == 1 && allowedWidgetIds.contains('login')) {
      return const SizedBox.shrink();
    }

    final repo = DashboardRepository();
    final allWidgets = repo.getWidgets();

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
                      for (final w in allWidgets)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.widgets,
                            size: 18,
                            color: Colors.cyanAccent,
                          ),
                          title: Text(
                            w.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          // No switch / tap handler; purely informational.
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
