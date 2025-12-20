import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DynamicFormsPanel extends StatefulWidget {
  const DynamicFormsPanel({super.key});

  @override
  State<DynamicFormsPanel> createState() => _DynamicFormsPanelState();
}

class _DynamicFormsPanelState extends State<DynamicFormsPanel> {
  static const String tenantId = 'default_tenant';

  bool _loading = false;
  String? _status;
  Color _statusColor = Colors.greenAccent;

  // formId -> raw schema map
  final Map<String, Map<String, dynamic>> _schemas = {};
  String? _selectedFormId;

  @override
  void initState() {
    super.initState();
    _loadSchemas();
  }

  Future<void> _loadSchemas() async {
    setState(() {
      _loading = true;
      _status = null;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('tenants/$tenantId/metadata')
          .doc('formSchemas')
          .get();

      _schemas.clear();

      if (snap.exists && snap.data() != null) {
        final data = snap.data() as Map<String, dynamic>;
        final forms =
            (data['forms'] ?? <String, dynamic>{}) as Map<String, dynamic>;

        for (final entry in forms.entries) {
          final m = entry.value as Map<String, dynamic>;
          final schema = m['schema'] as Map<String, dynamic>? ?? {};
          _schemas[entry.key] = schema;
        }
      }

      if (_schemas.isEmpty) {
        // Fallback demo form
        _schemas['demo_login'] = {
          'formId': 'demo_login',
          'name': 'Demo Login Form',
          'fields': [
            {'id': 'email', 'type': 'email', 'label': 'Email'},
            {'id': 'password', 'type': 'password', 'label': 'Password'},
          ],
        };
      }

      _selectedFormId ??= _schemas.keys.first;

      setState(() {
        _status = 'Loaded ${_schemas.length} form schema(s)';
        _statusColor = Colors.greenAccent;
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to load form schemas: $e';
        _statusColor = Colors.redAccent;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schema = _selectedFormId != null
        ? _schemas[_selectedFormId] ?? {}
        : <String, dynamic>{};

    final fields = (schema['fields'] ?? []) as List<dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dynamic Forms Engine (Preview)',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Renders forms from metadata → good to quickly test your formSchemas JSON.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            DropdownButton<String>(
              value: _selectedFormId,
              dropdownColor: const Color(0xFF111118),
              hint: const Text('Select form'),
              items: _schemas.keys
                  .map(
                    (id) => DropdownMenuItem(
                      value: id,
                      child: Text(id),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedFormId = v),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: _loading ? null : _loadSchemas,
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
              label: const Text('Reload Schemas'),
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
              padding: const EdgeInsets.all(24.0),
              child: _selectedFormId == null
                  ? const Center(
                      child: Text(
                        'No form selected.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : _DynamicFormRenderer(fields: fields),
            ),
          ),
        ),
      ],
    );
  }
}

/* ------------------------ Simple runtime renderer ------------------------- */

class _DynamicFormRenderer extends StatefulWidget {
  final List<dynamic> fields;

  const _DynamicFormRenderer({required this.fields});

  @override
  State<_DynamicFormRenderer> createState() => _DynamicFormRendererState();
}

class _DynamicFormRendererState extends State<_DynamicFormRenderer> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _values = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      final id = (f['id'] ?? '') as String;
      if (id.isEmpty) continue;
      _controllers[id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fields.isEmpty) {
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
          ...widget.fields.map((f) => _buildField(f as Map<String, dynamic>)),
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

  Widget _buildField(Map<String, dynamic> field) {
    final id = (field['id'] ?? '') as String;
    final type = (field['type'] ?? 'text') as String;
    final label = (field['label'] ?? id) as String;
    final required = field['required'] == true;

    switch (type) {
      case 'email':
      case 'text':
      case 'password':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextFormField(
            controller: _controllers[id],
            obscureText: type == 'password',
            decoration: InputDecoration(
              labelText: label,
            ),
            validator: (v) {
              if (required && (v == null || v.trim().isEmpty)) {
                return '$label required';
              }
              if (type == 'email' &&
                  v != null &&
                  v.isNotEmpty &&
                  !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(v)) {
                return 'Invalid email';
              }
              return null;
            },
          ),
        );
      case 'dropdown':
        final options = List<String>.from(field['options'] ?? const []);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _DynamicDropdownField(
            id: id,
            label: label,
            options: options,
            required: required,
            onChanged: (val) => _values[id] = val,
          ),
        );
      case 'checkbox':
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _DynamicCheckboxField(
            id: id,
            label: label,
            required: required,
            onChanged: (val) => _values[id] = val,
          ),
        );
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Unsupported field type: $type',
            style: const TextStyle(color: Colors.redAccent),
          ),
        );
    }
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    for (final entry in _controllers.entries) {
      _values[entry.key] = entry.value.text.trim();
    }

    // For now just print. Later: send to backend / Firestore.
    debugPrint('Dynamic form values: ${jsonEncode(_values)}');

    ScaffoldMessenger.of(_formKey.currentContext!).showSnackBar(
      const SnackBar(
        content: Text('Submitted – see debug console for values'),
      ),
    );
  }
}

class _DynamicDropdownField extends StatefulWidget {
  final String id;
  final String label;
  final List<String> options;
  final bool required;
  final ValueChanged<String?> onChanged;

  const _DynamicDropdownField({
    required this.id,
    required this.label,
    required this.options,
    required this.required,
    required this.onChanged,
  });

  @override
  State<_DynamicDropdownField> createState() => _DynamicDropdownFieldState();
}

class _DynamicDropdownFieldState extends State<_DynamicDropdownField> {
  String? _value;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _value,
      decoration: InputDecoration(labelText: widget.label),
      items: widget.options
          .map(
            (o) => DropdownMenuItem(
              value: o,
              child: Text(o),
            ),
          )
          .toList(),
      validator: (v) {
        if (widget.required && (v == null || v.isEmpty)) {
          return '${widget.label} required';
        }
        return null;
      },
      onChanged: (v) {
        setState(() => _value = v);
        widget.onChanged(v);
      },
    );
  }
}

class _DynamicCheckboxField extends StatefulWidget {
  final String id;
  final String label;
  final bool required;
  final ValueChanged<bool> onChanged;

  const _DynamicCheckboxField({
    required this.id,
    required this.label,
    required this.required,
    required this.onChanged,
  });

  @override
  State<_DynamicCheckboxField> createState() => _DynamicCheckboxFieldState();
}

class _DynamicCheckboxFieldState extends State<_DynamicCheckboxField> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: _value,
      onChanged: (v) {
        final val = v ?? false;
        setState(() => _value = val);
        widget.onChanged(val);
      },
      title: Text(widget.label, style: const TextStyle(color: Colors.white)),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
