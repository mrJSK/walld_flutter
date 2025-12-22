import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../Developer/DynamicForms/dynamic_forms_repository.dart';
import '../../Developer/DynamicForms/form_models.dart';

class CreateTaskWidget extends StatelessWidget {
  const CreateTaskWidget({Key? key}) : super(key: key);

  void _openFormDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => const _CreateTaskFormDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final shortest = math.min(maxW, maxH);

        final double unit = (shortest / 8.0).clamp(10.0, 48.0);
        final double radius = (unit * 0.85).clamp(12.0, 42.0);
        final double margin = (unit * 0.25).clamp(4.0, 12.0);
        final EdgeInsets padding =
            EdgeInsets.all((unit * 0.75).clamp(8.0, 28.0));
        final double titleFont = (unit * 1.05).clamp(12.0, 26.0);
        final double bodyFont = (unit * 0.70).clamp(10.0, 18.0);
        final double gap = (unit * 0.60).clamp(6.0, 18.0);

        return InkWell(
          onTap: () => _openFormDialog(context),
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            margin: EdgeInsets.all(margin),
            decoration: BoxDecoration(
              color: const Color(0x6611111C),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: const Color(0x22FFFFFF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Task',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleFont,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: gap),
                Expanded(
                  child: Text(
                    'Click to open the task creation form.',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: bodyFont,
                      height: 1.2,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    'Tap to create',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.cyanAccent.withOpacity(0.8),
                      fontSize: bodyFont * 0.9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CreateTaskFormDialog extends StatefulWidget {
  const _CreateTaskFormDialog({Key? key}) : super(key: key);

  @override
  State<_CreateTaskFormDialog> createState() => _CreateTaskFormDialogState();
}

class _CreateTaskFormDialogState extends State<_CreateTaskFormDialog> {
  static const String tenantId = 'default_tenant';

  static FormSchemaMeta? _cachedTaskCreationForm;
  static Object? _cachedLoadError;

  final DynamicFormsRepository _repo = DynamicFormsRepository();
  final GlobalKey<_DynamicFormRendererState> _rendererKey =
      GlobalKey<_DynamicFormRendererState>();

  FormSchemaMeta? _form;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (_cachedTaskCreationForm != null || _cachedLoadError != null) {
      _form = _cachedTaskCreationForm;
      _loading = false;
    } else {
      _loadFormOnce();
    }
  }

  Future<void> _loadFormOnce() async {
    try {
      final forms = await _repo.loadForms(tenantId);
      final found = forms.firstWhere(
        (f) => f.formId == 'task_creation',
        orElse: () => forms.first,
      );
      _cachedTaskCreationForm = found;
      _cachedLoadError = null;
      if (!mounted) return;
      setState(() {
        _form = found;
        _loading = false;
      });
    } catch (e) {
      _cachedLoadError = e;
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _createTaskFromPayload(Map<String, dynamic> values) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      final now = DateTime.now();
      final tasksCol = FirebaseFirestore.instance
          .collection('tenants')
          .doc(tenantId)
          .collection('tasks');

      final data = <String, dynamic>{
        'title': values['title'] ?? '',
        'description': values['description'] ?? '',
        'status': 'PENDING',
        'created_by': user.uid,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'custom_fields': values,
      };

      if (values['dueDate'] is DateTime) {
        data['due_date'] = (values['dueDate'] as DateTime).toIso8601String();
      }

      await tasksCol.add(data);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task created')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _onCreatePressed() async {
    final state = _rendererKey.currentState;
    if (state == null) return;
    final payload = await state.submitExternally();
    if (payload == null) return;
    await _createTaskFromPayload(payload);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortest = math.min(size.width, size.height);
    final double unit = (shortest / 8.0).clamp(10.0, 48.0);
    final double titleFont = (unit * 1.05).clamp(14.0, 26.0);
    final double bodyFont = (unit * 0.70).clamp(11.0, 18.0);
    final double gap = (unit * 0.60).clamp(6.0, 18.0);
    final double radius = (unit * 0.85).clamp(16.0, 32.0);

    final loadError = _cachedLoadError;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: size.width * 0.6,
          maxHeight: size.height * 0.75,
        ),
        child: Material(
          color: const Color(0xFF11111C),
          elevation: 24,
          shadowColor: Colors.black87,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_form == null)
                    ? Center(
                        child: Text(
                          loadError == null
                              ? 'Create Task form config not available.'
                              : 'Failed to load form: $loadError',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _form!.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: titleFont,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white70,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                          SizedBox(height: gap / 2),
                          Text(
                            _form!.description,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: bodyFont * 0.9,
                            ),
                          ),
                          SizedBox(height: gap),
                          Expanded(
                            child: _DynamicFormRenderer(
                              key: _rendererKey,
                              tenantId: tenantId,
                              form: _form!,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _onCreatePressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyanAccent,
                                foregroundColor: Colors.black,
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.black,
                                        ),
                                      ),
                                    )
                                  : const Text('Create Task'),
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}

class _DynamicFormRenderer extends StatefulWidget {
  final String tenantId;
  final FormSchemaMeta form;

  const _DynamicFormRenderer({
    super.key,
    required this.tenantId,
    required this.form,
  });

  @override
  State<_DynamicFormRenderer> createState() => _DynamicFormRendererState();
}

class _DynamicFormRendererState extends State<_DynamicFormRenderer> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
            field.options.isNotEmpty ? field.options.first.toString() : null;
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
    final canLoadFromFirestore = field.dataSource == 'firestore' &&
        field.collection != null &&
        field.displayField != null &&
        field.valueField != null;

    if (!canLoadFromFirestore) {
      _dropdownItems[field.id] = field.options
          .map(
            (o) => DropdownMenuItem<String>(
              value: o.toString(),
              child: Text(o.toString()),
            ),
          )
          .toList();
      if (mounted) setState(() {});
      return;
    }

    if (mounted) setState(() => _loadingDropdown[field.id] = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('tenants/${widget.tenantId}/${field.collection}')
          .get();

      final items = snap.docs.map((doc) {
        final data = doc.data();
        final value = (data[field.valueField] ?? doc.id).toString();
        final label = (data[field.displayField] ?? value).toString();
        return DropdownMenuItem<String>(
          value: value,
          child: Text(label),
        );
      }).toList();

      _dropdownItems[field.id] = items;
      if (_dropdownValues[field.id] == null && items.isNotEmpty) {
        _dropdownValues[field.id] = items.first.value;
      }
    } finally {
      if (mounted) {
        setState(() => _loadingDropdown[field.id] = false);
      }
    }
  }

  String? _runValidation(FormFieldMeta field, String value) {
    if (field.required && value.isEmpty) {
      return '${field.label} is required';
    }

    if (field.type == 'email' && value.isNotEmpty) {
      final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value);
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

  Future<Map<String, dynamic>?> submitExternally() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return null;

    for (final entry in _controllers.entries) {
      _values[entry.key] = entry.value.text.trim();
    }
    for (final entry in _checkboxValues.entries) {
      _values[entry.key] = entry.value;
    }
    for (final entry in _dropdownValues.entries) {
      _values[entry.key] = entry.value;
    }

    return Map<String, dynamic>.from(_values);
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
            validator: (v) => _runValidation(field, (v ?? '').trim()),
          ),
        );

      case 'dropdown':
        final loading = _loadingDropdown[field.id] ?? false;
        final items = _dropdownItems[field.id] ??
            field.options
                .map(
                  (o) => DropdownMenuItem<String>(
                    value: o.toString(),
                    child: Text(o.toString()),
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
        return _DynamicDateField(
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
          ...widget.form.fields.map(_buildField),
        ],
      ),
    );
  }
}

class _DynamicDateField extends StatefulWidget {
  final String label;
  final bool required;
  final ValueChanged<DateTime> onChanged;

  const _DynamicDateField({
    required this.label,
    required this.required,
    required this.onChanged,
  });

  @override
  State<_DynamicDateField> createState() => _DynamicDateFieldState();
}

class _DynamicDateFieldState extends State<_DynamicDateField> {
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
