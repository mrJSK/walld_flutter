import 'package:flutter/material.dart';

import 'hierarchy_repository.dart';
import 'org_node_model.dart';

class HierarchyPanel extends StatefulWidget {
  const HierarchyPanel({super.key});

  @override
  State<HierarchyPanel> createState() => _HierarchyPanelState();
}

class _HierarchyPanelState extends State<HierarchyPanel> {
  static const String tenantId = 'default_tenant';

  final HierarchyRepository _repo = HierarchyRepository();
  final List<OrgNodeMeta> _nodes = [];

  bool _loading = false;
  bool _saving = false;
  String? _status;
  Color _statusColor = Colors.greenAccent;

  String? _selectedNodeId;

  OrgNodeMeta? get _selectedNode {
    try {
      return _nodes.firstWhere((n) => n.id == _selectedNodeId);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _setStatus(String msg, {bool error = false}) {
    setState(() {
      _status = msg;
      _statusColor = error ? Colors.redAccent : Colors.greenAccent;
    });
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.loadHierarchy(tenantId);
      setState(() {
        _nodes
          ..clear()
          ..addAll(list);
        _selectedNodeId = _nodes.isEmpty ? null : _nodes.first.id;
      });
      _setStatus('Hierarchy loaded (${_nodes.length} nodes)');
    } catch (e) {
      _setStatus('Failed to load hierarchy: $e', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _repo.saveHierarchy(tenantId, _nodes);
      _setStatus('Hierarchy saved');
    } catch (e) {
      _setStatus('Failed to save hierarchy: $e', error: true);
    } finally {
      setState(() => _saving = false);
    }
  }

  List<String> _splitCsv(String input) {
    return input
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _addNode({String? parentId}) {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final designationsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111118),
        title: const Text(
          'Add Node',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'Node ID (e.g. delhi_hq)',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name (e.g. Delhi HQ)',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: designationsController,
                decoration: const InputDecoration(
                  labelText: 'Allowed Designations (comma-separated IDs)',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
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

              OrgNodeMeta? parent;
              if (parentId != null) {
                try {
                  parent = _nodes.firstWhere((n) => n.id == parentId);
                } catch (_) {
                  parent = null;
                }
              }
              final level = parent == null ? 0 : parent.level + 1;

              final node = OrgNodeMeta(
                id: id,
                name: nameController.text.trim().isEmpty
                    ? id
                    : nameController.text.trim(),
                parentId: parentId,
                level: level,
                designationIds: _splitCsv(designationsController.text),
                isActive: true,
              );

              setState(() {
                _nodes.add(node);
                _selectedNodeId = id;
              });

              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editSelectedNode() {
    final node = _selectedNode;
    if (node == null) return;

    final nameController = TextEditingController(text: node.name);
    final designationsController =
        TextEditingController(text: node.designationIds.join(', '));
    bool isActive = node.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF111118),
            title: const Text(
              'Edit Node',
              style: TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: designationsController,
                    decoration: const InputDecoration(
                      labelText: 'Allowed Designations (comma-separated)',
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: isActive,
                    onChanged: (v) =>
                        setDialogState(() => isActive = v),
                    title: const Text(
                      'Active',
                      style: TextStyle(color: Colors.white),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  setState(() {
                    node.name = nameController.text.trim().isEmpty
                        ? node.id
                        : nameController.text.trim();
                    node.designationIds =
                        _splitCsv(designationsController.text);
                    node.isActive = isActive;
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

  void _deleteSelectedNode() {
    final node = _selectedNode;
    if (node == null) return;

    final roots = _nodes.where((n) => n.parentId == null).toList();
    if (roots.length == 1 && node.parentId == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF111118),
          title: const Text(
            'Cannot Delete Last Root Node',
            style: TextStyle(color: Colors.redAccent),
          ),
          content: const Text(
            'The hierarchy must have at least one root node. '
            'Please add another root node before deleting this one.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111118),
        title: const Text(
          'Delete Node?',
          style: TextStyle(color: Colors.orange),
        ),
        content: Text(
          'Delete "${node.name}" and all its children? '
          'This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () {
              Navigator.pop(context);
              _performDelete(node);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _performDelete(OrgNodeMeta node) {
    final toRemove = <String>{node.id};
    bool changed;

    do {
      changed = false;
      for (final n in _nodes.toList()) {
        if (n.parentId != null && toRemove.contains(n.parentId)) {
          if (toRemove.add(n.id)) changed = true;
        }
      }
    } while (changed);

    setState(() {
      _nodes.removeWhere((n) => toRemove.contains(n.id));

      if (_nodes.isEmpty || toRemove.contains(_selectedNodeId)) {
        _selectedNodeId = _nodes.isEmpty ? null : _nodes.first.id;
      }
    });

    _setStatus('Deleted ${toRemove.length} node(s)');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Organization Hierarchy Builder',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Define org tree used for approvals, reporting, and dynamic queries.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        const SizedBox(height: 16),
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
          child: Row(
            children: [
              SizedBox(
                width: 280,
                child: Card(
                  color: const Color(0xFF111118),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildTreeView(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  color: const Color(0xFF111118),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildDetails(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTreeView() {
    if (_nodes.isEmpty) {
      return Column(
        children: [
          OutlinedButton.icon(
            onPressed: () => _addNode(parentId: null),
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Add Root'),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'No nodes yet.\nCreate a root node.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    final roots = _nodes.where((n) => n.parentId == null).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    List<Widget> buildChildren(String parentId, int indent) {
      final children =
          _nodes.where((n) => n.parentId == parentId).toList()
            ..sort((a, b) => a.name.compareTo(b.name));

      return children
          .map(
            (child) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _treeTile(child, indent.toDouble()),
                ...buildChildren(child.id, indent + 16),
              ],
            ),
          )
          .toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: () => _addNode(parentId: null),
          icon: const Icon(Icons.add_box_outlined),
          label: const Text('Add Root'),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: roots
                  .map(
                    (root) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _treeTile(root, 0),
                        ...buildChildren(root.id, 16),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _treeTile(OrgNodeMeta node, double indent) {
    final selected = node.id == _selectedNodeId;
    return GestureDetector(
      onTap: () => setState(() => _selectedNodeId = node.id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding:
            EdgeInsets.only(left: indent, right: 8, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A1A25) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              node.parentId == null
                  ? Icons.account_tree_rounded
                  : Icons.subdirectory_arrow_right_rounded,
              size: 18,
              color: node.isActive ? Colors.cyan : Colors.grey,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                node.name,
                style: TextStyle(
                  color: node.isActive ? Colors.white : Colors.grey,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails() {
    final node = _selectedNode;

    if (node == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              'Select a node to view or edit details.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final nameController = TextEditingController(text: node.name);
    final designationsController =
        TextEditingController(text: node.designationIds.join(', '));
    bool isActive = node.isActive;

    return StatefulBuilder(
      builder: (context, setDetailsState) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Node Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.cyan),
                    onPressed: _editSelectedNode,
                    tooltip: 'Edit Node',
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: _deleteSelectedNode,
                    tooltip: 'Delete Node',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Node Name',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                ),
                onChanged: (val) {
                  setState(() {
                    node.name = val.trim().isEmpty ? node.id : val.trim();
                  });
                  setDetailsState(() {});
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: designationsController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Allowed Designation IDs (comma-separated)',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                ),
                onChanged: (val) {
                  setState(() {
                    node.designationIds = _splitCsv(val);
                  });
                  setDetailsState(() {});
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: isActive,
                onChanged: (val) {
                  setDetailsState(() => isActive = val);
                  setState(() {
                    node.isActive = val;
                  });
                },
                title: const Text(
                  'Active',
                  style: TextStyle(color: Colors.white),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              Text(
                'Node ID: ${node.id}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                'Level: ${node.level}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              if (node.parentId != null)
                Text(
                  'Parent ID: ${node.parentId}',
                  style:
                      TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              const SizedBox(height: 16),
              const Text(
                'Add Child Node',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _addNode(parentId: node.id),
                icon: const Icon(Icons.add),
                label: const Text('Add Child'),
              ),
            ],
          ),
        );
      },
    );
  }
}
