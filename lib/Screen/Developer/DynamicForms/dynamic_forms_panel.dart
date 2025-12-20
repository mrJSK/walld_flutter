import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'dynamic_forms_repository.dart';
import 'form_models.dart';

class DynamicFormsPanel extends StatefulWidget {
  const DynamicFormsPanel({super.key});

  @override
  State<DynamicFormsPanel> createState() => _DynamicFormsPanelState();
}

class _DynamicFormsPanelState extends State<DynamicFormsPanel> {
  static const String tenantId = 'default_tenant';

  final DynamicFormsRepository _repo = DynamicFormsRepository();

  final List<FormSchemaMeta> _forms = [];
  int _selectedIndex = 0;
  bool _loading = false;
  String? _status;
  Color _statusColor = Colors.greenAccent;

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
      final list = await _repo.loadForms(tenantId);
      setState(() {
        _forms
          ..clear()
          ..addAll(list);
        _selectedIndex = 0;
      });
      _setStatus('Loaded ${_forms.length} form(s)');
    } catch (e) {
      _setStatus('Failed to load forms: $e', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedForm = _forms.isEmpty ? null : _forms[_selectedIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dynamic Forms Engine – Preview',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Runtime renderer for formSchemas metadata (system + custom forms).',
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
              // LEFT: Form list
              SizedBox(
                width: 260,
                child: Card(
                  color: const Color(0xFF111118),
                  child: _forms.isEmpty
                      ? const Center(
                          child: Text(
                            'No forms yet.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _forms.length,
                          itemBuilder: (context, index) {
                            final f = _forms[index];
                            final selected = index == _selectedIndex;
                            return ListTile(
                              selected: selected,
                              selectedTileColor: const Color(0xFF1A1A25),
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
                              onTap: () =>
                                  setState(() => _selectedIndex = index),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // RIGHT: Form preview
              Expanded(
                child: Card(
                  color: const Color(0xFF111118),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: selectedForm == null
                        ? const Center(
                            child: Text(
                              'No form selected.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : _DynamicFormRenderer(
                            tenantId: tenantId,
                            form: selectedForm,
                            onSubmit: (payload) async {
                              // hook for real backend later
                              debugPrint(
                                  'Dynamic form "${selectedForm.formId}" submitted: $payload');
                            },
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* ------------------------ Runtime form renderer ------------------------ */

class _DynamicFormRenderer extends StatefulWidget {
  final String tenantId;
  final FormSchemaMeta form;
  final Future<void> Function(Map<String, dynamic> values)? onSubmit;

  const _DynamicFormRenderer({
    required this.tenantId,
    required this.form,
    this.onSubmit,
  });

  @override
  State<_DynamicFormRenderer> createState() => _DynamicFormRendererState();
}

class _DynamicFormRendererState extends State<_DynamicFormRenderer> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _values = {};
  final Map<String, bool> _checkboxValues = {};
  final Map<String, String?> _dropdownValues = {};
  final Map<String, List<DropdownMenuItem<String>>> _dropdownItems = {};
  final Map<String, bool> _loadingDropdown = {};

  @override
  void initState() {
    super.initState();
    for (final field in widget.form.fields) {
      if (field.type == 'checkbox') {
        _checkboxValues[field.id] = false;
      } else if (field.type == 'dropdown') {
        _dropdownValues[field.id] =
            field.options.isNotEmpty ? field.options.first : null;
        _loadDropdownOptions(field);
      } else {
        _controllers[field.id] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDropdownOptions(FormFieldMeta field) async {
    if (field.dataSource != 'firestore' ||
        field.collection == null ||
        field.displayField == null ||
        field.valueField == null) {
      // static options
      _dropdownItems[field.id] = field.options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList();
      setState(() {});
      return;
    }

    setState(() => _loadingDropdown[field.id] = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('tenants/${widget.tenantId}/${field.collection}')
          .get();

      final items = snap.docs.map((doc) {
        final data = doc.data();
        final value = data[field.valueField] ?? doc.id;
        final label = data[field.displayField] ?? value.toString();
        return DropdownMenuItem<String>(
          value: value.toString(),
          child: Text(label.toString()),
        );
      }).toList();

      _dropdownItems[field.id] = items;
      if (_dropdownValues[field.id] == null && items.isNotEmpty) {
        _dropdownValues[field.id] = items.first.value;
      }
    } finally {
      setState(() => _loadingDropdown[field.id] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.form.fields.isEmpty) {
      return const Center(
        child: Text(
          'This form has no fields.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        children: [
          Text(
            widget.form.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.form.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.form.description,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          const SizedBox(height: 16),
          ...widget.form.fields.map(_buildField),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _onSubmit,
              child: const Text('Submit (debug)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(FormFieldMeta field) {
    switch (field.type) {
      case 'email':
      case 'text':
      case 'password':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextFormField(
            controller: _controllers[field.id],
            obscureText: field.type == 'password',
            decoration: InputDecoration(
              labelText: field.label,
              floatingLabelBehavior: FloatingLabelBehavior.auto,
            ),
            validator: (v) => _runValidation(field, v?.trim() ?? ''),
          ),
        );
      case 'dropdown':
        final loading = _loadingDropdown[field.id] ?? false;
        final items = _dropdownItems[field.id] ??
            field.options
                .map(
                  (o) => DropdownMenuItem(
                    value: o,
                    child: Text(o),
                  ),
                )
                .toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: DropdownButtonFormField<String>(
            value: _dropdownValues[field.id],
            decoration: InputDecoration(
              labelText: field.label,
              floatingLabelBehavior: FloatingLabelBehavior.auto,
            ),
            dropdownColor: const Color(0xFF111118),
            items: items,
            validator: (v) {
              if (field.required && (v == null || v.isEmpty)) {
                return '${field.label} is required';
              }
              return null;
            },
            onChanged: loading
                ? null
                : (v) {
                    setState(() => _dropdownValues[field.id] = v);
                  },
          ),
        );
      case 'checkbox':
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: CheckboxListTile(
            value: _checkboxValues[field.id] ?? false,
            onChanged: (v) {
              setState(() => _checkboxValues[field.id] = v ?? false);
            },
            title: Text(
              field.label,
              style: const TextStyle(color: Colors.white),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        );
      case 'date':
        return _DateField(
          label: field.label,
          required: field.required,
          onChanged: (value) => _values[field.id] = value,
        );
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Unsupported field type: ${field.type}',
            style: const TextStyle(color: Colors.redAccent),
          ),
        );
    }
  }

  String? _runValidation(FormFieldMeta field, String value) {
    if (field.required && value.isEmpty) {
      return '${field.label} is required';
    }
    if (field.type == 'email' && value.isNotEmpty) {
      final ok =
          RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value);
      if (!ok) return 'Invalid email';
    }
    if (field.validation != null && value.isNotEmpty) {
      final re = RegExp(field.validation!);
      if (!re.hasMatch(value)) {
        return 'Invalid ${field.label}';
      }
    }
    return null;
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    for (final entry in _controllers.entries) {
      _values[entry.key] = entry.value.text.trim();
    }
    for (final entry in _checkboxValues.entries) {
      _values[entry.key] = entry.value;
    }
    for (final entry in _dropdownValues.entries) {
      _values[entry.key] = entry.value;
    }

    if (widget.onSubmit != null) {
      await widget.onSubmit!(_values);
    } else {
      debugPrint(
          'Dynamic form "${widget.form.formId}" submitted: $_values');
      ScaffoldMessenger.of(_formKey.currentContext!).showSnackBar(
        const SnackBar(
          content:
              Text('Form submitted – see debug console for payload'),
        ),
      );
    }
  }
}

/* ----------------------------- Helper widgets ---------------------------- */

class _DateField extends StatefulWidget {
  final String label;
  final bool required;
  final ValueChanged<DateTime?> onChanged;

  const _DateField({
    required this.label,
    required this.required,
    required this.onChanged,
  });

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  DateTime? _value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: _pickDate,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: widget.label,
          ),
          child: Text(
            _value == null
                ? 'Select date'
                : '${_value!.year}-${_value!.month.toString().padLeft(2, '0')}-${_value!.day.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _value ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _value = picked);
      widget.onChanged(picked);
    }
  }
}
