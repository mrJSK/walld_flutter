import 'package:flutter/material.dart';

import 'metadata_repository.dart';
import 'designation/designation_tab.dart';
import 'role_permission/role_permission_tab.dart';
import 'form_schema/form_schema_tab.dart';

enum MetaType { designations, rolePermissions, formSchemas }

class MetadataPanel extends StatefulWidget {
  const MetadataPanel({super.key});

  @override
  State<MetadataPanel> createState() => _MetadataPanelState();
}

class _MetadataPanelState extends State<MetadataPanel> {
  static const String tenantId = 'default_tenant';

  final MetadataRepository _repo = MetadataRepository(); // ← no const

  MetaType _selectedType = MetaType.designations;
  String? _status;
  Color _statusColor = Colors.greenAccent;

  void _setStatus(String message, {bool error = false}) {
    setState(() {
      _status = message;
      _statusColor = error ? Colors.redAccent : Colors.greenAccent;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_selectedType) {
      MetaType.designations => 'Metadata Engine – Designations',
      MetaType.rolePermissions => 'Metadata Engine – Role Permissions',
      MetaType.formSchemas => 'Metadata Engine – Form Schemas',
    };

    final subtitle = switch (_selectedType) {
      MetaType.designations =>
          'Manage designation hierarchy, permissions and screen access without editing JSON.',
      MetaType.rolePermissions => 'Map roles to permission lists used by RBAC.',
      MetaType.formSchemas =>
          'Manage system/custom forms and their JSON schemas.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey[400]),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            DropdownButton<MetaType>(
              value: _selectedType,
              dropdownColor: const Color(0xFF111118),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selectedType = v);
              },
              items: const [
                DropdownMenuItem(
                  value: MetaType.designations,
                  child: Text('Designations'),
                ),
                DropdownMenuItem(
                  value: MetaType.rolePermissions,
                  child: Text('Role Permissions'),
                ),
                DropdownMenuItem(
                  value: MetaType.formSchemas,
                  child: Text('Form Schemas'),
                ),
              ],
            ),
            const Spacer(),
            if (_status != null)
              Text(
                _status!,
                style: TextStyle(color: _statusColor, fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Card(
            color: const Color(0xFF111118),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: switch (_selectedType) {
                MetaType.designations => DesignationTab(
                    tenantId: tenantId,
                    repo: _repo,
                    setStatus: _setStatus,
                  ),
                MetaType.rolePermissions => RolePermissionTab(
                    tenantId: tenantId,
                    repo: _repo,
                    setStatus: _setStatus,
                  ),
                MetaType.formSchemas => FormSchemaTab(
                    tenantId: tenantId,
                    repo: _repo,
                    setStatus: _setStatus,
                  ),
              },
            ),
          ),
        ),
      ],
    );
  }
}
