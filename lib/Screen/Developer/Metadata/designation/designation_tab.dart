import 'package:flutter/material.dart';

import '../metadata_repository.dart';
import 'designation_model.dart';

class DesignationTab extends StatefulWidget {
  final String tenantId;
  final MetadataRepository repo;
  final void Function(String message, {bool error}) setStatus;

  const DesignationTab({
    super.key,
    required this.tenantId,
    required this.repo,
    required this.setStatus,
  });

  @override
  State<DesignationTab> createState() => _DesignationTabState();
}

class _DesignationTabState extends State<DesignationTab> {
  final List<DesignationMeta> _designations = [];
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
    debugPrint('🔄 Loading designations for tenant: ${widget.tenantId}');
    
    final list = await widget.repo.loadDesignations(widget.tenantId);
    
    debugPrint('✅ Loaded ${list.length} designations:');
    for (final d in list) {
      debugPrint('   - ${d.id}: ${d.name} (level ${d.hierarchyLevel})');
    }
    
    setState(() {
      _designations
        ..clear()
        ..addAll(list);
    });
    
    widget.setStatus('${list.length} Designations loaded', error: false);
  } catch (e, stackTrace) {
    debugPrint('❌ Error loading designations: $e');
    debugPrint('Stack trace: $stackTrace');
    widget.setStatus('Failed to load designations: $e', error: true);
  } finally {
    setState(() => _loading = false);
  }
}


  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.repo.saveDesignations(widget.tenantId, _designations);
      widget.setStatus('Designations saved');
    } catch (e) {
      widget.setStatus('Failed to save designations: $e', error: true);
    } finally {
      setState(() => _saving = false);
    }
  }

  void _openDialog({DesignationMeta? existing}) {
    final isNew = existing == null;

    final idController = TextEditingController(text: existing?.id ?? '');
    final nameController = TextEditingController(text: existing?.name ?? '');
    final levelController =
        TextEditingController(text: (existing?.hierarchyLevel ?? 1).toString());
    final reportsToController =
        TextEditingController(text: (existing?.reportsTo ?? []).join(', '));
    final permissionsController =
        TextEditingController(text: (existing?.permissions ?? []).join(', '));
    final screensController =
        TextEditingController(text: (existing?.screenAccess ?? []).join(', '));
    bool requiresApproval = existing?.requiresApproval ?? false;
    bool isRoot = existing?.isRoot ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF111118),
            title: Text(
              isNew ? 'Add Designation' : 'Edit Designation',
              style: const TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ID
                    TextField(
                      controller: idController,
                      enabled: isNew,
                      decoration: const InputDecoration(
                        labelText: 'ID (e.g. developer)',
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),

                    // Name
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),

                    // Hierarchy level
                    TextField(
                      controller: levelController,
                      decoration: const InputDecoration(
                        labelText: 'Hierarchy Level',
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),

                    // Reports to
                    TextField(
                      controller: reportsToController,
                      decoration: const InputDecoration(
                        labelText: 'Reports To (comma-separated IDs)',
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),

                    // Permissions
                    TextField(
                      controller: permissionsController,
                      decoration: const InputDecoration(
                        labelText: 'Permissions (comma-separated)',
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),

                    // Screen access
                    TextField(
                      controller: screensController,
                      decoration: const InputDecoration(
                        labelText:
                            'Screen Access (comma-separated, e.g. developer, admin)',
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),

                    // Switches
                    SwitchListTile(
                      value: requiresApproval,
                      onChanged: (v) =>
                          setDialogState(() => requiresApproval = v),
                      title: const Text(
                        'Requires Approval',
                        style: TextStyle(color: Colors.white),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      value: isRoot,
                      onChanged: (v) => setDialogState(() => isRoot = v),
                      title: const Text(
                        'Root Access (Full System Control)',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Root designations can manage all tenants, metadata and workflows.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      contentPadding: EdgeInsets.zero,
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

                  final designation = DesignationMeta(
                    id: id,
                    name: nameController.text.trim(),
                    hierarchyLevel:
                        int.tryParse(levelController.text.trim()) ?? 1,
                    reportsTo: _splitCsv(reportsToController.text),
                    permissions: _splitCsv(permissionsController.text),
                    screenAccess: _splitCsv(screensController.text),
                    requiresApproval: requiresApproval,
                    isRoot: isRoot,
                  );

                  setState(() {
                    if (isNew) {
                      _designations.add(designation);
                    } else {
                      final index =
                          _designations.indexWhere((element) => element.id == id);
                      if (index != -1) {
                        _designations[index] = designation;
                      }
                    }
                  });

                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
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
              label: const Text('Add Designation'),
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
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Level')),
                DataColumn(label: Text('Screens')),
                DataColumn(label: Text('Root')),
                DataColumn(label: Text('Requires Approval')),
                DataColumn(label: Text('Actions')),
              ],
              rows: _designations.map((d) {
                return DataRow(
                  cells: [
                    DataCell(Text(d.id)),
                    DataCell(Text(d.name)),
                    DataCell(Text(d.hierarchyLevel.toString())),
                    DataCell(Text(d.screenAccess.join(', '))),
                    DataCell(
                      Icon(
                        d.isRoot
                            ? Icons.stars
                            : Icons.remove_circle_outline,
                        color:
                            d.isRoot ? Colors.purpleAccent : Colors.grey,
                        size: 18,
                      ),
                    ),
                    DataCell(
                      Icon(
                        d.requiresApproval
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: d.requiresApproval
                            ? Colors.orange
                            : Colors.grey,
                        size: 18,
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                size: 18, color: Colors.cyan),
                            onPressed: () => _openDialog(existing: d),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                size: 18, color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                _designations
                                    .removeWhere((x) => x.id == d.id);
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
