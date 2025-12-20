import 'package:flutter/material.dart';

import '../metadata_repository.dart';
import 'form_schema_model.dart';

class FormSchemaTab extends StatefulWidget {
  final String tenantId;
  final MetadataRepository repo;
  final void Function(String message, {bool error}) setStatus;

  const FormSchemaTab({
    super.key,
    required this.tenantId,
    required this.repo,
    required this.setStatus,
  });

  @override
  State<FormSchemaTab> createState() => _FormSchemaTabState();
}

class _FormSchemaTabState extends State<FormSchemaTab> {
  final List<FormSchemaMeta> _forms = [];
  int _selectedIndex = 0;
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
      final list = await widget.repo.loadFormSchemas(widget.tenantId);
      setState(() {
        _forms
          ..clear()
          ..addAll(list);
        _selectedIndex = _forms.isEmpty ? 0 : 0;
      });
      widget.setStatus('Form schemas loaded');
    } catch (e) {
      widget.setStatus('Failed to load form schemas: $e', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.repo.saveFormSchemas(widget.tenantId, _forms);
      widget.setStatus('Form schemas saved');
    } catch (e) {
      widget.setStatus('Failed to save form schemas: $e', error: true);
    } finally {
      setState(() => _saving = false);
    }
  }

  void _createForm() {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111118),
        title: const Text(
          'Create New Form',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'Form ID'),
                style: const TextStyle(color: Colors.white),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                style: const TextStyle(color: Colors.white),
              ),
              TextField(
                controller: descController,
                decoration:
                    const InputDecoration(labelText: 'Description'),
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

              setState(() {
                _forms.add(
                  FormSchemaMeta(
                    formId: id,
                    name: nameController.text.trim().isEmpty
                        ? id
                        : nameController.text.trim(),
                    description: descController.text.trim(),
                    rawJsonSchema: FormSchemaMeta
                        .defaultUserRegistrationSchema(), // minimal template
                  ),
                );
                _selectedIndex = _forms.length - 1;
              });

              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasForms = _forms.isNotEmpty;
    final current =
        hasForms ? _forms[_selectedIndex] : null;

    final nameController =
        TextEditingController(text: current?.name ?? '');
    final descController =
        TextEditingController(text: current?.description ?? '');
    final schemaController =
        TextEditingController(text: current?.rawJsonSchema ?? '');

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
              onPressed: _createForm,
              icon: const Icon(Icons.add),
              label: const Text('Create Form'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: hasForms
              ? Row(
                  children: [
                    SizedBox(
                      width: 260,
                      child: ListView.builder(
                        itemCount: _forms.length,
                        itemBuilder: (context, index) {
                          final f = _forms[index];
                          final selected = index == _selectedIndex;
                          return ListTile(
                            selected: selected,
                            selectedTileColor:
                                const Color(0xFF1A1A25),
                            title: Text(
                              f.formId,
                              style: TextStyle(
                                color: selected
                                    ? Colors.cyan
                                    : Colors.white,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              f.name,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete,
                                  size: 18,
                                  color: Colors.redAccent),
                              onPressed: () {
                                setState(() {
                                  _forms.removeAt(index);
                                  if (_selectedIndex >=
                                      _forms.length) {
                                    _selectedIndex =
                                        (_forms.length - 1)
                                            .clamp(0, 999);
                                  }
                                });
                              },
                            ),
                            onTap: () =>
                                setState(() => _selectedIndex = index),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatefulBuilder(
                        builder: (context, setLocal) {
                          if (current == null) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Editing form: ${current.formId}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                    labelText: 'Name'),
                                style: const TextStyle(
                                    color: Colors.white),
                                onChanged: (v) =>
                                    current.name = v,
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: descController,
                                decoration: const InputDecoration(
                                    labelText: 'Description'),
                                style: const TextStyle(
                                    color: Colors.white),
                                onChanged: (v) =>
                                    current.description = v,
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.white10),
                                  ),
                                  child: TextField(
                                    controller: schemaController,
                                    expands: true,
                                    maxLines: null,
                                    minLines: null,
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                    ),
                                    decoration:
                                        const InputDecoration(
                                      contentPadding:
                                          EdgeInsets.all(8),
                                      border: InputBorder.none,
                                      hintText:
                                          '{  // form schema JSON }',
                                      hintStyle: TextStyle(
                                          color: Colors.grey),
                                    ),
                                    onChanged: (v) =>
                                        current.rawJsonSchema = v,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Text(
                    'No forms defined yet.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
        ),
      ],
    );
  }
}
