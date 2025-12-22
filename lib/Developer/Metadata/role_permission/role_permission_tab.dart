import 'package:flutter/material.dart';

import '../metadata_repository.dart';
import 'role_permission_model.dart';

class RolePermissionTab extends StatefulWidget {
  final String tenantId;
  final MetadataRepository repo;
  final void Function(String message, {bool error}) setStatus;

  const RolePermissionTab({
    super.key,
    required this.tenantId,
    required this.repo,
    required this.setStatus,
  });

  @override
  State<RolePermissionTab> createState() => _RolePermissionTabState();
}

class _RolePermissionTabState extends State<RolePermissionTab> {
  final List<RolePermissionMeta> _roles = [];
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final list = await widget.repo.loadRolePermissions(widget.tenantId);
      setState(() {
        _roles
          ..clear()
          ..addAll(list);
      });
      widget.setStatus('Role permissions loaded');
    } catch (e) {
      widget.setStatus('Failed to load role permissions: $e', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.repo.saveRolePermissions(widget.tenantId, _roles);
      widget.setStatus('Role permissions saved');
    } catch (e) {
      widget.setStatus('Failed to save role permissions: $e', error: true);
    } finally {
      setState(() => _saving = false);
    }
  }

  void _openDialog({RolePermissionMeta? existing}) {
    final isNew = existing == null;

    final idController = TextEditingController(text: existing?.roleId ?? '');
    final permsController =
        TextEditingController(text: (existing?.permissions ?? []).join(', '));
    final descController =
        TextEditingController(text: existing?.description ?? '');

    // Pre-fill description for well-known roles if creating new.[file:2]
    void seedDefaultDescription(String roleId) {
      if (existing != null) return;
      switch (roleId) {
        case 'developer':
        case 'developer_root':
          descController.text =
              'Can manage all metadata, organizations, workflows; root access.';
          break;
        case 'admin':
          descController.text =
              'Can manage users, forms, workflows inside assigned org.';
          break;
        case 'manager':
          descController.text =
              'Can create/assign tasks, approve within hierarchy, view team.';
          break;
        case 'employee':
          descController.text =
              'Can view and complete assigned tasks, request approvals.';
          break;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111118),
        title: Text(
          isNew ? 'Add Role' : 'Edit Role',
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: idController,
                  enabled: isNew,
                  decoration: const InputDecoration(
                    labelText: 'Role ID (e.g. developer, admin)',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => seedDefaultDescription(v.trim()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: permsController,
                  decoration: const InputDecoration(
                    labelText: 'Permissions (comma-separated)',
                    hintText:
                        'create_org, manage_metadata, approve_tasks, view_reports',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (what this role can do)',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final id = idController.text.trim();
              if (id.isEmpty) return;

              final meta = RolePermissionMeta(
                roleId: id,
                permissions: _splitCsv(permsController.text),
                description: descController.text.trim(),
              );

              setState(() {
                if (isNew) {
                  _roles.add(meta);
                } else {
                  final idx =
                      _roles.indexWhere((element) => element.roleId == id);
                  if (idx != -1) _roles[idx] = meta;
                }
              });

              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  List<String> _splitCsv(String input) {
    return input
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            FilledButton.icon(
              onPressed: _loading ? null : _reload,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Reload'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _openDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Role'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              dataTextStyle: const TextStyle(color: Colors.white),
              columns: const [
                DataColumn(label: Text('Role ID')),
                DataColumn(label: Text('Permissions')),
                DataColumn(label: Text('Description')),
                DataColumn(label: Text('Actions')),
              ],
              rows: _roles.map((r) {
                return DataRow(
                  cells: [
                    DataCell(Text(r.roleId)),
                    DataCell(Text(r.permissions.join(', '))),
                    DataCell(
                      Tooltip(
                        message: r.description,
                        child: Text(
                          r.description.isEmpty
                              ? '—'
                              : (r.description.length > 40
                                  ? '${r.description.substring(0, 40)}…'
                                  : r.description),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                size: 18, color: Colors.cyan),
                            onPressed: () => _openDialog(existing: r),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                size: 18, color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                _roles.removeWhere(
                                    (x) => x.roleId == r.roleId);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
