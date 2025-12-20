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
                    fields: [
                      // start with one text field as template
                      FormFieldMeta(
                        id: 'field1',
                        type: 'text',
                        label: 'Field 1',
                        required: false,
                      ),
                    ],
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

  void _openFieldDialog(FormSchemaMeta form, {FormFieldMeta? existing}) {
    final isNew = existing == null;

    final idController = TextEditingController(text: existing?.id ?? '');
    final labelController = TextEditingController(text: existing?.label ?? '');
    String type = existing?.type ?? 'text';
    bool required = existing?.required ?? false;
    final optionsController =
        TextEditingController(text: (existing?.options ?? []).join(', '));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF111118),
            title: Text(
              isNew ? 'Add Field' : 'Edit Field',
              style: const TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: idController,
                    enabled: isNew,
                    decoration: const InputDecoration(
                      labelText: 'Field ID (e.g. fullName)',
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Label',
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: type,
                    dropdownColor: const Color(0xFF111118),
                    decoration: const InputDecoration(
                      labelText: 'Field Type',
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'text',
                        child: Text('Text'),
                      ),
                      DropdownMenuItem(
                        value: 'email',
                        child: Text('Email'),
                      ),
                      DropdownMenuItem(
                        value: 'password',
                        child: Text('Password'),
                      ),
                      DropdownMenuItem(
                        value: 'dropdown',
                        child: Text('Dropdown (static)'),
                      ),
                      DropdownMenuItem(
                        value: 'checkbox',
                        child: Text('Checkbox'),
                      ),
                      DropdownMenuItem(
                        value: 'date',
                        child: Text('Date'),
                      ),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => type = v ?? 'text'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: required,
                    onChanged: (v) =>
                        setDialogState(() => required = v),
                    title: const Text(
                      'Required',
                      style: TextStyle(color: Colors.white),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (type == 'dropdown') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: optionsController,
                      decoration: const InputDecoration(
                        labelText:
                            'Options (comma-separated, for dropdown)',
                        floatingLabelBehavior:
                            FloatingLabelBehavior.auto,
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
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

                  final field = FormFieldMeta(
                    id: id,
                    type: type,
                    label: labelController.text.trim().isEmpty
                        ? id
                        : labelController.text.trim(),
                    required: required,
                    options: _splitCsv(optionsController.text),
                  );

                  setState(() {
                    if (isNew) {
                      form.fields.add(field);
                    } else {
                      final idx = form.fields
                          .indexWhere((element) => element.id == id);
                      if (idx != -1) form.fields[idx] = field;
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
    final hasForms = _forms.isNotEmpty;

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
                    // LEFT: form list
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

                    // RIGHT: form editor (name + description + fields table)
                    Expanded(
                      child: _buildFormEditor(_forms[_selectedIndex]),
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

  Widget _buildFormEditor(FormSchemaMeta form) {
    final nameController = TextEditingController(text: form.name);
    final descController =
        TextEditingController(text: form.description);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Editing form: ${form.formId}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Name'),
          style: const TextStyle(color: Colors.white),
          onChanged: (v) => form.name = v,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: descController,
          decoration: const InputDecoration(labelText: 'Description'),
          style: const TextStyle(color: Colors.white),
          onChanged: (v) => form.description = v,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text(
              'Fields',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => _openFieldDialog(form),
              icon: const Icon(Icons.add),
              label: const Text('Add Field'),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
                DataColumn(label: Text('Label')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Required')),
                DataColumn(label: Text('Options')),
                DataColumn(label: Text('Actions')),
              ],
              rows: form.fields.map((f) {
                return DataRow(
                  cells: [
                    DataCell(Text(f.id)),
                    DataCell(Text(f.label)),
                    DataCell(Text(f.type)),
                    DataCell(
                      Icon(
                        f.required
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: f.required
                            ? Colors.orange
                            : Colors.grey,
                        size: 18,
                      ),
                    ),
                    DataCell(
                      Text(
                        f.options.isEmpty
                            ? '—'
                            : f.options.join(', '),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                size: 18, color: Colors.cyan),
                            onPressed: () =>
                                _openFieldDialog(form, existing: f),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                size: 18, color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                form.fields
                                    .removeWhere((x) => x.id == f.id);
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
