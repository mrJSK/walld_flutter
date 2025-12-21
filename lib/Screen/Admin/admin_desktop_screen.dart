import 'package:flutter/material.dart';
import 'Dashboard/dashboard_panel.dart';
import 'TaskManagement/task_management_panel.dart';
import 'UserManagement/user_management_panel.dart';

class AdminDesktopScreen extends StatefulWidget {
  final String tenantId;

  const AdminDesktopScreen({
    super.key,
    this.tenantId = 'default_tenant',
  });

  @override
  State<AdminDesktopScreen> createState() => _AdminDesktopScreenState();
}

class _AdminDesktopScreenState extends State<AdminDesktopScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05040A), // ADDED: Background color
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
                  leading: Icon(Icons.admin_panel_settings, color: Colors.cyan),
                  title: Text(
                    'Admin Console',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16, // ADDED: Explicit size
                    ),
                  ),
                ),
                const Divider(color: Colors.white24),
                _navItem(0, Icons.dashboard_rounded, 'Dashboard'),
                _navItem(1, Icons.task_alt, 'Task Management'),
                _navItem(2, Icons.people_rounded, 'User Management'),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tenant: ${widget.tenantId}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.cloud_done, size: 12, color: Colors.greenAccent),
                          SizedBox(width: 4),
                          Text(
                            'Synced',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // MAIN CONTENT - FIXED
          Expanded(
            child: Container(
              color: const Color(0xFF05040A), // Dark background
              child: _buildSelectedPanel(), // CHANGED: Direct widget builder
            ),
          ),
        ],
      ),
    );
  }

  // ADDED: Direct panel builder instead of IndexedStack
  Widget _buildSelectedPanel() {
    switch (_selectedIndex) {
      case 0:
        return DashboardPanel(tenantId: widget.tenantId);
      case 1:
        return TaskManagementPanel(tenantId: widget.tenantId);
      case 2:
        return UserManagementPanel(tenantId: widget.tenantId);
      default:
        return DashboardPanel(tenantId: widget.tenantId);
    }
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
          color: selected ? Colors.cyan : Colors.grey.shade300,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedTileColor: const Color(0xFF1A1A25), // ADDED: Selected highlight
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () {
        setState(() => _selectedIndex = index);
      },
    );
  }
}
