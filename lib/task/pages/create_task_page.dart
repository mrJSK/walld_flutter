import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../Developer/DynamicForms/dynamic_forms_repository.dart';
import '../../Developer/DynamicForms/form_models.dart';
import '../../core/glass_container.dart';

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({super.key});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
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
  if (user == null) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You must be logged in to create a task'),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

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

    // Use the dynamic form's first date field as canonical due date
    final renderer = _rendererKey.currentState;
    DateTime? due = renderer?.getSelectedDueDate();

    if (due != null) {
      // Store normalized due date at top level
      data['due_date'] = due.toIso8601String();

      // Mirror back into payload under the schema field id (e.g. "due_date")
      final key = renderer?.firstDateFieldKey;
      if (key != null) {
        values[key] = due;
      }
    }

    await tasksCol.add(data);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task created successfully'),
        backgroundColor: Colors.cyan,
      ),
    );

    // Reset form
    _rendererKey.currentState?.resetForm();
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to create task: $e'),
        backgroundColor: Colors.redAccent,
      ),
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
    final loadError = _cachedLoadError;

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
        ),
      );
    }

    if (_form == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              loadError == null
                  ? 'Create Task form config not available.'
                  : 'Failed to load form',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (loadError != null) ...[
              const SizedBox(height: 8),
              Text(
                loadError.toString(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Form description
        if (_form!.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _form!.description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),

        // Form fields
        Expanded(
          child: _DynamicFormRenderer(
            key: _rendererKey,
            tenantId: tenantId,
            form: _form!,
          ),
        ),

        const SizedBox(height: 16),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: _submitting
                  ? null
                  : () {
                      _rendererKey.currentState?.resetForm();
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Reset'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _submitting ? null : _onCreatePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Text(
                      'Create Task',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ],
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
  DateTime? getSelectedDueDate() {
    final key = firstDateFieldKey;
    if (key == null) return null;
    final v = _values[key];
    return v is DateTime ? v : null;
  }
  String? get firstDateFieldKey {
  for (final f in widget.form.fields) {
    if (f.type == 'date') return f.id; // e.g. "due_date"
  }
  return null;
}
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

  void resetForm() {
    _formKey.currentState?.reset();
    for (final c in _controllers.values) {
      c.clear();
    }
    for (final key in _checkboxValues.keys) {
      _checkboxValues[key] = false;
    }
    for (final field in widget.form.fields) {
      if (field.type == 'dropdown' && field.options.isNotEmpty) {
        _dropdownValues[field.id] = field.options.first.toString();
      }
    }
    _values.clear();
    setState(() {});
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
              child: Text(
                o.toString(),
                style: const TextStyle(color: Colors.white),
              ),
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
          child: Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
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

  // 1. Capture controllers/checkboxes/dropdowns
  for (final entry in _controllers.entries) {
    _values[entry.key] = entry.value.text.trim();
  }
  for (final entry in _checkboxValues.entries) {
    _values[entry.key] = entry.value;
  }
  for (final entry in _dropdownValues.entries) {
    _values[entry.key] = entry.value;
  }

  // 2. PRESERVE date values (don't overwrite!)
  for (final field in widget.form.fields) {
    if (field.type == 'date') {
      // Keep existing DateTime from onChanged, or null if none
      final existing = _values[field.id];
      if (existing == null) {
        _values[field.id] = null;
      }
      // DateTime values stay intact!
    }
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
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: field.label,
            labelStyle: const TextStyle(color: Colors.white70),
            floatingLabelStyle: const TextStyle(color: Colors.cyanAccent),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.circular(18),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide:
                  const BorderSide(color: Colors.cyanAccent, width: 2),
              borderRadius: BorderRadius.circular(18),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.redAccent),
              borderRadius: BorderRadius.circular(18),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 2),
              borderRadius: BorderRadius.circular(18),
            ),
            filled: true,
            // glass‑like dark layer
            fillColor: Colors.white.withOpacity(0.04),
          ),
          validator: (v) => _runValidation(field, (v ?? '').trim()),
        ),
      );

    case 'dropdown':
  final loading = _loadingDropdown[field.id] ?? false;
  final options = _dropdownItems[field.id] ??
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
    child: PopupMenuButton<String>(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      offset: const Offset(0, 8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: field.label,
          labelStyle: const TextStyle(color: Colors.white70),
          floatingLabelStyle: const TextStyle(color: Colors.cyanAccent),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white24),
            borderRadius: BorderRadius.circular(18),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
            borderRadius: BorderRadius.circular(18),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.04),
          suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
        ),
        child: Text(
          _dropdownValues[field.id] ?? 'Select ${field.label}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      itemBuilder: (context) => options
          .map(
            (item) => PopupMenuItem<String>(
              value: item.value,
              padding: EdgeInsets.zero,
              child: GlassContainer(
                blur: 28,
                opacity: 0.3,
                tint: Colors.black,
                blurMode: GlassBlurMode.perWidget,
                borderRadius: BorderRadius.circular(10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                  width: 200,
                  child: item.child,
                ),
              ),
            ),
          )
          .toList(),
      onSelected: (v) {
        setState(() => _dropdownValues[field.id] = v);
      },
    ),
  );


      case 'checkbox':
        return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: CheckboxListTile(
            value: _checkboxValues[field.id] ?? false,
            onChanged: (v) {
              setState(() => _checkboxValues[field.id] = v ?? false);
            },
            title: Text(
              field.label,
              style: const TextStyle(color: Colors.white),
            ),
            activeColor: Colors.cyanAccent,
            checkColor: Colors.black,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
      );

    case 'date':
      // UPDATED DUE DATE FIELD: no past date, includes time
      return _DynamicDateField(
        label: field.label,
        required: field.required,
        onChanged: (value) => _values[field.id] = value,
      );

    default:
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent),
          ),
          child: Text(
            'Unsupported field type: ${field.type}',
            style: const TextStyle(color: Colors.redAccent),
          ),
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
    final display = _value == null
        ? 'Select date & time'
        : '${_value!.year}-${_value!.month.toString().padLeft(2, '0')}-${_value!.day.toString().padLeft(2, '0')} '
          '${_value!.hour.toString().padLeft(2, '0')}:${_value!.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: _pickDateTime,
        borderRadius: BorderRadius.circular(18),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: const TextStyle(color: Colors.white70),
            floatingLabelStyle: const TextStyle(color: Colors.cyanAccent),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.circular(18),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
              borderRadius: BorderRadius.circular(18),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.redAccent),
              borderRadius: BorderRadius.circular(18),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
              borderRadius: BorderRadius.circular(18),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.04),
            suffixIcon: const Icon(Icons.calendar_today,
                color: Colors.cyanAccent),
          ),
          child: Text(
            display,
            style: TextStyle(
              color: _value == null ? Colors.white38 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
  final now = DateTime.now();
  final initial = _value ?? now;

  const double dialogBlur = 30;
  const double dialogOpacity = 0.32;

  Widget wrapGlass(BuildContext context, Widget dialogChild) {
    return Stack(
      children: [
        // full‑screen blurred dark sheet
        Positioned.fill(
          child: GlassContainer(
            blur: dialogBlur,
            opacity: dialogOpacity,
            tint: Colors.black,
            blurMode: GlassBlurMode.perWidget,
            borderRadius: BorderRadius.zero,
            padding: EdgeInsets.zero,
            child: const SizedBox.expand(),
          ),
        ),
        // dialog itself
        Center(
          child: dialogChild,
        ),
      ],
    );
  }

  // DATE (no past)
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: initial.isBefore(now) ? now : initial,
    firstDate: DateTime(now.year, now.month, now.day),
    lastDate: DateTime(now.year + 5),
    builder: (context, child) {
      return Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.cyanAccent,
            onPrimary: Colors.black,
            surface: Colors.transparent,
            onSurface: Colors.white,
          ),
          dialogBackgroundColor: Colors.transparent,
        ),
        child: wrapGlass(context, child!),
      );
    },
  );
  if (pickedDate == null) return;

  // TIME
  final pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
    builder: (context, child) {
      return Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.cyanAccent,
            onPrimary: Colors.black,
            surface: Colors.transparent,
            onSurface: Colors.white,
          ),
          dialogBackgroundColor: Colors.transparent,
        ),
        child: wrapGlass(context, child!),
      );
    },
  );
  if (pickedTime == null) return;

  final combined = DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    pickedTime.hour,
    pickedTime.minute,
  );

  final clamped = combined.isBefore(now) ? now : combined;

  setState(() => _value = clamped);
  widget.onChanged(clamped);
  
}


}


