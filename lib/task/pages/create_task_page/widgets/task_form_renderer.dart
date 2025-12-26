import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../Developer/DynamicForms/form_models.dart';
import '../../../../core/glass_container.dart';
import '../mixins/user_data_loader_mixin.dart';
import '../models/assignment_data.dart';
import 'assignment_type_selector.dart';
import 'dynamic_date_field.dart';
import 'team_member_selector.dart';

class TaskFormRenderer extends StatefulWidget {
  final String tenantId;
  final FormSchemaMeta form;

  const TaskFormRenderer({
    super.key,
    required this.tenantId,
    required this.form,
  });

  @override
  State<TaskFormRenderer> createState() => TaskFormRendererState();
}

class TaskFormRendererState extends State<TaskFormRenderer>
    with UserDataLoaderMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _values = {};
  final Map<String, bool> _checkboxValues = {};
  final Map<String, String?> _dropdownValues = {};
  final Map<String, List<DropdownMenuItem<String>>> _dropdownItems = {};
  final Map<String, bool> _loadingDropdown = {};

  // Assignment tracking
  String? _assignmentType;
  String? _selectedNodeId;
  List<String> _selectedUserIds = [];
  String? _groupName;
  String? _leadMemberId; // NEW: selected lead member UID
  Map<String, String> _nodeToHeadUserMap = {};

  DateTime? getSelectedDueDate() {
    final key = firstDateFieldKey;
    if (key == null) return null;
    final v = _values[key];
    return v is DateTime ? v : null;
  }

  String? get firstDateFieldKey {
    for (final f in widget.form.fields) {
      if (f.type == 'date') return f.id;
    }
    return null;
  }

  AssignmentData? getAssignmentData() {
    return AssignmentData(
      assignmentType: _assignmentType ?? '',
      selectedNodeId: _selectedNodeId,
      selectedUserIds: _selectedUserIds,
      groupName: _groupName,
      leadMemberId: _leadMemberId, // NEW
      nodeToHeadUserMap: _nodeToHeadUserMap,
    );
  }

  @override
  void initState() {
    super.initState();
    loadCurrentUserData(widget.tenantId);

    for (final field in widget.form.fields) {
      if (field.type == 'checkbox') {
        _checkboxValues[field.id] = false;
      } else if (field.type == 'dropdown') {
        _dropdownValues[field.id] =
            field.options.isNotEmpty ? field.options.first.toString() : null;
        _loadDropdownOptions(field);
      } else if (field.type == 'date') {
        _values[field.id] = null;
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
    _assignmentType = null;
    _selectedNodeId = null;
    _selectedUserIds.clear();
    _groupName = null;
    _leadMemberId = null; // NEW
    _values.clear();
    setState(() {});
  }

  Future<void> _loadDropdownOptions(FormFieldMeta field) async {
    // Skip assignTo - custom assignment section handles it
    if (field.id.toLowerCase() == 'assignto' ||
        field.id.toLowerCase() == 'assign_to' ||
        field.label.toLowerCase().contains('assign to')) {
      return;
    }

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

  Future<void> _loadSubordinateUnits() async {
    if (currentUserLevel == null || currentUserNodeId == null) {
      await loadCurrentUserData(widget.tenantId);
    }

    if (currentUserLevel == null || currentUserNodeId == null) {
      debugPrint('Cannot load subordinate units: user data not available');
      return;
    }

    final targetLevel = currentUserLevel! + 1;

    try {
      final hierarchySnap = await FirebaseFirestore.instance
          .collection('tenants')
          .doc(widget.tenantId)
          .collection('organizations')
          .doc('hierarchy')
          .collection('nodes')
          .where('level', isEqualTo: targetLevel)
          .where('isActive', isEqualTo: true)
          .where('parentId', isEqualTo: currentUserNodeId)
          .get();

      final Map<String, String> nodeToHead = {};
      final List<DropdownMenuItem<String>> items = [];

      for (final nodeDoc in hierarchySnap.docs) {
        final nodeId = nodeDoc.id;
        final nodeData = nodeDoc.data();
        final nodeName = nodeData['name'] as String? ?? nodeId;
        final nodeType = nodeData['type'] as String? ?? 'unit';

        final headSnap = await FirebaseFirestore.instance
            .collection('tenants')
            .doc(widget.tenantId)
            .collection('users')
            .where('nodeId', isEqualTo: nodeId)
            .where('level', isEqualTo: targetLevel)
            .where('employeeType', isEqualTo: 'head')
            .where('status', isEqualTo: 'active')
            .limit(1)
            .get();

        if (headSnap.docs.isNotEmpty) {
          final headUserId = headSnap.docs.first.id;
          nodeToHead[nodeId] = headUserId;

          items.add(
            DropdownMenuItem<String>(
              value: nodeId,
              child: Text(
                '$nodeName - $nodeType',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }
      }

      if (items.isEmpty) {
        items.add(
          const DropdownMenuItem<String>(
            value: 'none',
            child: Text(
              'No subordinate units found',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        );
      }

      setState(() {
        _nodeToHeadUserMap = nodeToHead;
        _dropdownItems['subordinate_unit_selector'] = items;
        if (_selectedNodeId == null && items.isNotEmpty) {
          _selectedNodeId = items.first.value;
        }
      });
    } catch (e) {
      debugPrint('Error loading subordinate units: $e');
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

    final assignmentData = getAssignmentData();
    if (assignmentData == null || !assignmentData.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete assignment selection'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return null;
    }

    for (final entry in _controllers.entries) {
      _values[entry.key] = entry.value.text.trim();
    }
    for (final entry in _checkboxValues.entries) {
      _values[entry.key] = entry.value;
    }
    for (final entry in _dropdownValues.entries) {
      _values[entry.key] = entry.value;
    }

    for (final field in widget.form.fields) {
      if (field.type == 'date') {
        if (!_values.containsKey(field.id)) {
          _values[field.id] = null;
        }
      }
    }

    return Map.from(_values);
  }

  Widget _buildField(FormFieldMeta field) {
    if (field.id.toLowerCase() == 'assignto' ||
        field.id.toLowerCase() == 'assign_to' ||
        field.label.toLowerCase().contains('assign to')) {
      return const SizedBox.shrink();
    }

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

        if (loading) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.cyanAccent),
              ),
            ),
          );
        }

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
                  borderSide:
                      const BorderSide(color: Colors.cyanAccent, width: 2),
                  borderRadius: BorderRadius.circular(18),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                suffixIcon:
                    const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
        return DynamicDateField(
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

  // helper to get label for selected subordinate node
  String _labelForSelectedNode(List<DropdownMenuItem<String>> items) {
    if (_selectedNodeId == null || _selectedNodeId == 'none') {
      return 'Select Subordinate Unit';
    }

    final item = items.firstWhere(
      (i) => i.value == _selectedNodeId,
      orElse: () => items.first,
    );

    if (item.child is Text) {
      return (item.child as Text).data ?? 'Select Subordinate Unit';
    }
    return 'Select Subordinate Unit';
  }

  Widget _buildSubordinateUnitDropdown() {
    final items = _dropdownItems['subordinate_unit_selector'] ?? [];

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.cyanAccent),
          ),
        ),
      );
    }

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
            labelText: 'Assign To (Subordinate Unit)',
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
            suffixIcon:
                const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
          ),
          child: Text(
            _labelForSelectedNode(items),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        itemBuilder: (context) => items
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SizedBox(
                    width: 250,
                    child: item.child,
                  ),
                ),
              ),
            )
            .toList(),
        onSelected: (v) {
          setState(() => _selectedNodeId = v);
        },
      ),
    );
  }

  Widget _buildAssignmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Task Assignment',
          style: TextStyle(
            color: Colors.cyanAccent,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        AssignmentTypeSelector(
          selectedType: _assignmentType,
          onChanged: (type) {
            setState(() {
              _assignmentType = type;
              _selectedNodeId = null;
              _selectedUserIds.clear();
              _groupName = null;
              _leadMemberId = null; // reset lead
            });

            if (type == 'subordinate_unit') {
              _loadSubordinateUnits();
            }
          },
        ),

        if (_assignmentType == 'subordinate_unit') ...[
          _buildSubordinateUnitDropdown(),
        ] else if (_assignmentType == 'team_member') ...[
          if (currentUserNodeId != null && currentUserLevel != null) ...[
            TeamMemberSelector(
              tenantId: widget.tenantId,
              currentNodeId: currentUserNodeId!,
              currentLevel: currentUserLevel!,
              selectedUserIds: _selectedUserIds,
              onSelectionChanged: (userIds) {
                setState(() {
                  _selectedUserIds = userIds;
                  if (_leadMemberId != null &&
                      !userIds.contains(_leadMemberId)) {
                    _leadMemberId = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            if (_selectedUserIds.length > 1) ...[
              TextFormField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Group Name *',
                  labelStyle: const TextStyle(color: Colors.white70),
                  floatingLabelStyle:
                      const TextStyle(color: Colors.cyanAccent),
                  hintText: 'Enter a name for this task group',
                  hintStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Colors.cyanAccent, width: 2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.04),
                ),
                validator: (v) {
                  if (_selectedUserIds.length > 1 &&
                      (v == null || v.trim().isEmpty)) {
                    return 'Group name is required for multi-user tasks';
                  }
                  return null;
                },
                onChanged: (value) {
                  _groupName = value.trim();
                },
              ),
              const SizedBox(height: 16),

              _buildLeadMemberDropdown(),

              const SizedBox(height: 8),
              const Text(
                'This task will be assigned to the selected team members as a group. The lead member will coordinate the task.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ] else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Loading user data...',
                style: TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ],
    );
  }

  // Lead member dropdown built from selected users
  Widget _buildLeadMemberDropdown() {
    return FutureBuilder<List<Map<String, String>>>(
      future: _loadSelectedUserNames(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.cyanAccent),
              ),
            ),
          );
        }

        final userOptions = snapshot.data ?? [];
        if (userOptions.isEmpty) {
          return const SizedBox.shrink();
        }

        return PopupMenuButton<String>(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          offset: const Offset(0, 8),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Select Lead Member *',
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
              fillColor: Colors.white.withOpacity(0.04),
              suffixIcon:
                  const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
            ),
            child: Text(
              _leadMemberId != null
                  ? userOptions
                          .firstWhere(
                            (u) => u['uid'] == _leadMemberId,
                            orElse: () => {'name': 'Select Lead Member'},
                          )['name'] ??
                      'Select Lead Member'
                  : 'Select Lead Member',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          itemBuilder: (context) => userOptions
              .map(
                (user) => PopupMenuItem<String>(
                  value: user['uid'],
                  padding: EdgeInsets.zero,
                  child: GlassContainer(
                    blur: 28,
                    opacity: 0.3,
                    tint: Colors.black,
                    blurMode: GlassBlurMode.perWidget,
                    borderRadius: BorderRadius.circular(10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: SizedBox(
                      width: 250,
                      child: Row(
                        children: [
                          const Icon(Icons.star,
                              size: 16, color: Colors.amberAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              user['name'] ?? '',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
          onSelected: (uid) {
            setState(() => _leadMemberId = uid);
          },
        );
      },
    );
  }

  
Future<List<Map<String, String>>> _loadSelectedUserNames() async {
  if (_selectedUserIds.isEmpty) return [];

  try {
    final userDocs = await Future.wait(
      _selectedUserIds.map(
        (uid) => FirebaseFirestore.instance
            .collection('tenants')
            .doc(widget.tenantId)
            .collection('users')
            .doc(uid)
            .get(),
      ),
    );

    return userDocs.map((doc) {
      if (!doc.exists) {
        // fallback to UID if doc missing
        return {'uid': doc.id, 'name': doc.id};
      }

      final data = doc.data();
      final fullName = data?['profiledata']?['fullName'] ??
          data?['fullName'] ??
          doc.id;

      return {
        'uid': doc.id,
        'name': fullName.toString(), // ✅ actual name used in UI
      };
    }).toList();
  } catch (e) {
    debugPrint('Error loading user names: $e');
    return [];
  }
}

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          ...widget.form.fields.map(_buildField),
          const SizedBox(height: 16),
          _buildAssignmentSection(),
        ],
      ),
    );
  }
}
