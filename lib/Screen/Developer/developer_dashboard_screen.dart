import 'package:flutter/material.dart';
import './Metadata/metadata_panel.dart';
import './Hierarchy/hierarchy_panel.dart';
import './DynamicForms/dynamic_forms_panel.dart';
import './UserDatabase/userdatabasepanel.dart'; // NEW IMPORT

class DeveloperDashboardScreen extends StatefulWidget {
  const DeveloperDashboardScreen({super.key});

  @override
  State<DeveloperDashboardScreen> createState() =>
      _DeveloperDashboardScreenState();  // ADD () here
}

class _DeveloperDashboardScreenState extends State<DeveloperDashboardScreen> {
  // 0: User Database, 1: Metadata, 2: Hierarchy, 3: Dynamic Forms
  int selectedIndex = 0; // Starts at User Database

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
                
                // NAVIGATION ITEMS
                navItem(0, Icons.dns_rounded, 'User Database'), // CHANGED ICON
                navItem(1, Icons.storage_rounded, 'Metadata'),
                navItem(2, Icons.account_tree_rounded, 'Hierarchy'),
                navItem(3, Icons.dynamic_form_rounded, 'Dynamic Forms'),
                
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Tenant: default_tenant • Synced',
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
              child: buildSelectedPanel(),
            ),
          ),
        ],
      ),
    );
  }

  // PANEL BUILDER
  Widget buildSelectedPanel() {
    switch (selectedIndex) {
      case 0:
        return const UserDatabasePanel();
      case 1:
        return const MetadataPanel();
      case 2:
        return const HierarchyPanel();
      case 3:
        return const DynamicFormsPanel();
      default:
        return const UserDatabasePanel();
    }
  }

  // NAVIGATION ITEM
  Widget navItem(int index, IconData icon, String label) {
    final selected = selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? Colors.cyan : Colors.grey,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.cyan : Colors.grey.shade300,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedTileColor: const Color(0xFF1A1A25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
    );
  }
}
