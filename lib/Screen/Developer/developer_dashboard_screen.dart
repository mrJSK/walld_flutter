import 'package:flutter/material.dart';

import 'Metadata/metadata_panel.dart';
import './Hierarchy/hierarchy_panel.dart';
import './DynamicForms/dynamic_forms_panel.dart';

class DeveloperDashboardScreen extends StatefulWidget {
  const DeveloperDashboardScreen({super.key});

  @override
  State<DeveloperDashboardScreen> createState() =>
      _DeveloperDashboardScreenState();
}

class _DeveloperDashboardScreenState
    extends State<DeveloperDashboardScreen> {
  // 0 = Metadata, 1 = Hierarchy, 2 = Dynamic Forms
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // LEFT NAVIGATION
          Container(
            width: 260,
            color: const Color(0xFF0B0B10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                const ListTile(
                  leading: Icon(Icons.code, color: Colors.cyan),
                  title: Text(
                    'Developer Console',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: Colors.white24),
                _navItem(0, Icons.storage_rounded, 'Metadata'),
                _navItem(1, Icons.account_tree_rounded, 'Hierarchy'),
                _navItem(2, Icons.dynamic_form_rounded, 'Dynamic Forms'),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Tenant: default_tenant\nStatus: Synced',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // MAIN CONTENT
          Expanded(
            child: Container(
              color: const Color(0xFF050509),
              padding: const EdgeInsets.all(24),
              child: IndexedStack(
                index: _selectedIndex,
                children: const [
                  MetadataPanel(),       // Metadata main tab
                  HierarchyPanel(),      // Org hierarchy (placeholder for now)
                  DynamicFormsPanel(),   // Dynamic forms preview
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? Colors.cyan : Colors.grey,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.cyan : Colors.grey[300],
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      onTap: () => setState(() => _selectedIndex = index),
    );
  }
}
