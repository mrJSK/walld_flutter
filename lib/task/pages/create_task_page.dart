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
    // current logged-in Firebase user (assigner) [web:10][web:23]
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
          .collection('tasks'); // main tasks collection [web:17][web:19]

      // ✅ 1) Resolve assignee node → head user UID
      final renderer = _rendererKey.currentState;
      String? assignedToUserId;

      // adjust key to whatever you used in the form: assignee / assignTo / assign_to
      final assigneeNodeId =
          values['assignee'] ?? values['assignTo'] ?? values['assign_to'];

      if (assigneeNodeId != null &&
          assigneeNodeId != 'none' &&
          assigneeNodeId != 'error') {
        // Map<String, String> _nodeToHeadUserMap = { nodeId: headUserUid }
        assignedToUserId =
            renderer?._nodeToHeadUserMap[assigneeNodeId.toString()];
      }

      // ✅ 2) Build Firestore payload
      final data = <String, dynamic>{
        'title': values['title'] ?? '',
        'description': values['description'] ?? '',
        'status': 'PENDING',

        // who assigned the task (assigner) -> current user uid
        'assigned_by': user.uid,

        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),

        // keep full dynamic form payload
        'custom_fields': values,

        // assignee (target user)
        if (assignedToUserId != null) 'assigned_to': assignedToUserId,
      };

      // ✅ 3) Due date handling, unchanged
      DateTime? due = renderer?.getSelectedDueDate();
      if (due != null) {
        data['due_date'] = due.toIso8601String();
        final key = renderer?.firstDateFieldKey;
        if (key != null) {
          values[key] = due;
        }
      }

      // ✅ 4) Create document in Firestore
      final docRef = await tasksCol.add(data);

      debugPrint(
        "✅ Task created and assigned to: $assignedToUserId (docId: ${docRef.id})",
      );
      debugPrint("Final Task Payload: $data");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            assignedToUserId != null
                ? 'Task created and assigned successfully'
                : 'Task created (no assignee found)',
          ),
          backgroundColor: Colors.cyan,
        ),
      );

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
        // The renderer
        Expanded(
          child: _DynamicFormRenderer(
            key: _rendererKey,
            tenantId: tenantId,
            form: _form!,
          ),
        ),
        const SizedBox(height: 16),
        // Create button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: _submitting ? null : _onCreatePressed,
            icon: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : const Icon(Icons.add_task_rounded),
            label: Text(_submitting ? 'Creating…' : 'Create Task'),
          ),
        ),
      ],
    );
  }
}

/* ========================================================================= */
/*                         DYNAMIC FORM RENDERER                             */
/* ========================================================================= */

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

  // NEW: Store current user's level
  int? _currentUserLevel;
  Map<String, String> _nodeToHeadUserMap = {};
  DateTime? getSelectedDueDate() {
    final key = firstDateFieldKey;
    if (key == null) return null;
    final v = _values[key];
    return v is DateTime ? v : null;
  }

  String? get firstDateFieldKey {
    for (final f in widget.form.fields) {
      if (f.type == 'date') return f.id; // e.g. "duedate"
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Load current user level first
    _loadCurrentUserLevel();
    
    for (final field in widget.form.fields) {
      if (field.type == 'checkbox') {
        _checkboxValues[field.id] = false;
      } else if (field.type == 'dropdown') {
        _dropdownValues[field.id] =
            field.options.isNotEmpty ? field.options.first.toString() : null;
        _loadDropdownOptions(field);
      } else if (field.type == 'date') {
        // IMPORTANT: Do NOT create a controller for date fields.
        // Date fields use their own internal state and return values via onChanged.
        _values[field.id] = null;
      } else {
        // Only text/email/password fields should have controllers
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

  // NEW: Load current user's level
  Future<void> _loadCurrentUserLevel() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('tenants')
          .doc(widget.tenantId)
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data.containsKey('level')) {
          setState(() {
            _currentUserLevel = data['level'] as int?;
          });
          debugPrint('Current user level: $_currentUserLevel');
        }
      }
    } catch (e) {
      debugPrint('Error loading current user level: $e');
    }
  }
  // NEW: Load assignTo options - shows node names, assigns to head user
Future<void> _loadAssignToOptions(FormFieldMeta field) async {
  if (mounted) setState(() => _loadingDropdown[field.id] = true);
  
  try {
    // Wait for current user level to load if not available yet
    if (_currentUserLevel == null) {
      await _loadCurrentUserLevel();
    }

    if (_currentUserLevel == null) {
      debugPrint('Could not determine current user level');
      _dropdownItems[field.id] = [];
      return;
    }

    // Calculate target level: currentLevel + 1
    final targetLevel = _currentUserLevel! + 1;
    debugPrint('Filtering assignTo for level: $targetLevel');

    // Load hierarchy nodes for the target level
    final hierarchySnap = await FirebaseFirestore.instance
        .collection('tenants')
        .doc(widget.tenantId)
        .collection('organizations')
        .doc('hierarchy')
        .collection('nodes')
        .where('level', isEqualTo: targetLevel)
        .where('isActive', isEqualTo: true)
        .get();

    final List<DropdownMenuItem<String>> items = [];
    final Map<String, String> nodeToHeadUserMap = {}; // nodeId -> headUserId

    // For each node at the target level
    for (final nodeDoc in hierarchySnap.docs) {
      final nodeId = nodeDoc.id;
      final nodeData = nodeDoc.data();
      final nodeName = nodeData['name'] as String? ?? nodeId;
      final nodeType = nodeData['type'] as String? ?? 'unknown';

      // Find the HEAD user in this node
      final headUserSnap = await FirebaseFirestore.instance
          .collection('tenants')
          .doc(widget.tenantId)
          .collection('users')
          .where('nodeId', isEqualTo: nodeId)
          .where('level', isEqualTo: targetLevel)
          .where('employeeType', isEqualTo: 'head')
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (headUserSnap.docs.isNotEmpty) {
        final headUserId = headUserSnap.docs.first.id;
        nodeToHeadUserMap[nodeId] = headUserId;

        // Add dropdown item showing node name and type
        items.add(
          DropdownMenuItem<String>(
            value: nodeId, // Store nodeId as value
            child: Text(
              '$nodeName - $nodeType',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
        
        debugPrint('Added node: $nodeName ($nodeType) -> head user: $headUserId');
      } else {
        debugPrint('⚠️ No head user found for node: $nodeName ($nodeId)');
      }
    }

    if (items.isEmpty) {
      items.add(
        DropdownMenuItem<String>(
          value: 'none',
          child: Text(
            'No divisions found at level $targetLevel',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    _dropdownItems[field.id] = items;
    if (_dropdownValues[field.id] == null && items.isNotEmpty) {
      _dropdownValues[field.id] = items.first.value;
    }

    // Store the mapping for later use when creating task
    _nodeToHeadUserMap = nodeToHeadUserMap;

    debugPrint('Loaded ${items.length} assignTo options for level $targetLevel');
  } catch (e) {
    debugPrint('Error loading assignTo options: $e');
    _dropdownItems[field.id] = [
      DropdownMenuItem<String>(
        value: 'error',
        child: Text(
          'Error loading options',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    ];
  } finally {
    if (mounted) setState(() => _loadingDropdown[field.id] = false);
  }
}

  Future<void> _loadDropdownOptions(FormFieldMeta field) async {
    // Check if this is an "assignTo" field with special logic
    if (field.id.toLowerCase() == 'assignto' || 
        field.id.toLowerCase() == 'assign_to' ||
        field.label.toLowerCase().contains('assign to')) {
      await _loadAssignToOptions(field);
      return;
    }

    // Standard dropdown loading logic
    final canLoadFromFirestore = field.dataSource == 'firestore' &&
        field.collection != null &&
        field.displayField != null &&
        field.valueField != null;

    if (!canLoadFromFirestore) {
      _dropdownItems[field.id] = field.options
          .map((o) => DropdownMenuItem<String>(
                value: o.toString(),
                child: Text(
                  o.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ))
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
        final value = data[field.valueField] ?? doc.id;
        final label = data[field.displayField] ?? value.toString();
        return DropdownMenuItem<String>(
          value: value.toString(),
          child: Text(
            label.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList();

      _dropdownItems[field.id] = items;
      if (_dropdownValues[field.id] == null && items.isNotEmpty) {
        _dropdownValues[field.id] = items.first.value;
      }
    } finally {
      if (mounted) setState(() => _loadingDropdown[field.id] = false);
    }
  }

  // NEW: Load assignTo options filtered by level
  Future<void> loadAssignToOptions(FormFieldMeta field) async {
    if (mounted) setState(() => _loadingDropdown[field.id] = true);
    
    try {
      // Wait for current user level to load if not available yet
      if (_currentUserLevel == null) {
        await _loadCurrentUserLevel();
      }

      if (_currentUserLevel == null) {
        debugPrint('Could not determine current user level');
        _dropdownItems[field.id] = [];
        return;
      }

      // Calculate target level: currentLevel + 1
      final targetLevel = _currentUserLevel! + 1;
      debugPrint('Filtering assignTo for level: $targetLevel');

      // Load hierarchy nodes for the target level
      final hierarchySnap = await FirebaseFirestore.instance
          .collection('tenants')
          .doc(widget.tenantId)
          .collection('organizations')
          .doc('hierarchy')
          .collection('nodes')
          .where('level', isEqualTo: targetLevel)
          .where('isActive', isEqualTo: true)
          .get();

      final List<DropdownMenuItem<String>> items = [];

      // For each node at the target level, get users
      for (final nodeDoc in hierarchySnap.docs) {
        final nodeId = nodeDoc.id;
        final nodeName = nodeDoc.data()['name'] as String? ?? nodeId;

        // Get users assigned to this node
        final usersSnap = await FirebaseFirestore.instance
            .collection('tenants')
            .doc(widget.tenantId)
            .collection('users')
            .where('nodeId', isEqualTo: nodeId)
            .where('level', isEqualTo: targetLevel)
            .where('status', isEqualTo: 'active')
            .get();

        for (final userDoc in usersSnap.docs) {
          final userData = userDoc.data();
          final userId = userDoc.id;
          final fullName = userData['profile_data']?['fullName'] ?? 
                          userData['fullName'] ??
                          userId;
          final designation = userData['designation'] ?? 'No Designation';

          items.add(
            DropdownMenuItem<String>(
              value: userId,
              child: Text(
                '$fullName ($designation - $nodeName)',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }
      }

      if (items.isEmpty) {
        items.add(
          DropdownMenuItem<String>(
            value: 'none',
            child: Text(
              'No users found at level $targetLevel',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        );
      }

      _dropdownItems[field.id] = items;
      if (_dropdownValues[field.id] == null && items.isNotEmpty) {
        _dropdownValues[field.id] = items.first.value;
      }

      debugPrint('Loaded ${items.length} assignTo options for level $targetLevel');
    } catch (e) {
      debugPrint('Error loading assignTo options: $e');
      _dropdownItems[field.id] = [
        DropdownMenuItem<String>(
          value: 'error',
          child: Text(
            'Error loading options',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ];
    } finally {
      if (mounted) setState(() => _loadingDropdown[field.id] = false);
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

  // lib/task/pages/create_task_page.dart
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

    // 2. Ensure Date values are included in the return payload
    for (final field in widget.form.fields) {
      if (field.type == 'date') {
        // If the user picked a date, it's already in _values[field.id] via the onChanged callback.
        // We just need to make sure we don't accidentally null it out or skip it.
        if (!_values.containsKey(field.id)) {
          _values[field.id] = null;
        }
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
              // glass-like dark layer
              fillColor: Colors.white.withOpacity(0.04),
            ),
            validator: (v) => _runValidation(field, v?.trim() ?? ''),
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

/* ========================================================================= */
/*                          HELPER WIDGETS                                   */
/* ========================================================================= */

// Date/Time picker widget
class _DynamicDateField extends StatefulWidget {
  final String label;
  final bool required;
  final ValueChanged<DateTime?> onChanged;

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
        onTap: _pickDateTime,
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
            filled: true,
            fillColor: Colors.white.withOpacity(0.04),
            suffixIcon: const Icon(Icons.calendar_today, color: Colors.cyanAccent),
          ),
          child: Text(
            _value == null
                ? 'Select date & time'
                : '${_value!.year}-${_value!.month.toString().padLeft(2, '0')}-${_value!.day.toString().padLeft(2, '0')} '
                  '${_value!.hour.toString().padLeft(2, '0')}:${_value!.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initial = _value ?? now;

    // DATE
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
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
          child: _wrapGlass(context, child!, isCompact: true), // ✅
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
          child: _wrapGlass(context, child!, isCompact: true), // ✅ pass flag
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

  Widget _wrapGlass(
  BuildContext context,
  Widget child, {
  bool isCompact = false,
}) {
  if (!isCompact) {
    return GlassContainer(
      blur: 40,
      opacity: 0.22,
      tint: Colors.black,
      borderRadius: BorderRadius.circular(28),
      blurMode: GlassBlurMode.perWidget,
      child: child,
    );
  }

  const dialogWidth  = 640.0;
  const dialogHeight = 420.0;

  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: dialogWidth,
        maxWidth: dialogWidth,     // ✅ exact width
        minHeight: dialogHeight,
        maxHeight: dialogHeight,   // ✅ exact height
      ),
      child: GlassContainer(
        blur: 40,
        opacity: 0.22,
        tint: Colors.black,
        borderRadius: BorderRadius.circular(22),
        blurMode: GlassBlurMode.perWidget,
        padding: const EdgeInsets.all(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: child,
        ),
      ),
    ),
  );
}



}
