import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class TeamMemberSelector extends StatefulWidget {
  final String tenantId;
  final String currentNodeId;
  final int currentLevel;
  final List<String> selectedUserIds;
  final ValueChanged<List<String>> onSelectionChanged;

  const TeamMemberSelector({
    super.key,
    required this.tenantId,
    required this.currentNodeId,
    required this.currentLevel,
    required this.selectedUserIds,
    required this.onSelectionChanged,
  });

  @override
  State<TeamMemberSelector> createState() => _TeamMemberSelectorState();
}

class _TeamMemberSelectorState extends State<TeamMemberSelector> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTeamMembers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamMembers() async {
  debugPrint('TEAM_SELECTOR: _loadTeamMembers START '
      'tenant=${widget.tenantId}, node=${widget.currentNodeId}, level=${widget.currentLevel}');
  setState(() => _loading = true);

  try {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('TEAM_SELECTOR: currentUserId=$currentUserId');

    final usersSnap = await FirebaseFirestore.instance
        .collection('tenants')
        .doc(widget.tenantId)
        .collection('users')
        .get();

    debugPrint('TEAM_SELECTOR: raw user docs count=${usersSnap.docs.length}');

    _allUsers = usersSnap.docs.where((doc) {
      final data = doc.data();
      final nodeId = data['nodeId'];
      final level = data['level'];
      final status = data['status'];

      final include = doc.id != currentUserId &&
          nodeId == widget.currentNodeId &&
          level == widget.currentLevel &&
          status == 'active';

      if (include) {
        debugPrint(
            'TEAM_SELECTOR: include uid=${doc.id}, nodeId=$nodeId, level=$level, status=$status');
      }

      return include;
    }).map((doc) {
      final data = doc.data();
      final uid = doc.id;
      final fullName =
          data['profiledata']?['fullName'] ?? data['fullName'] ?? uid;
      final designation = data['designation'] ?? 'No Designation';

      return {
        'uid': uid,
        'name': fullName,
        'designation': designation,
      };
    }).toList();

    _filteredUsers = List.from(_allUsers);
    debugPrint('TEAM_SELECTOR: filtered users count=${_allUsers.length}');
  } catch (e, st) {
    debugPrint('TEAM_SELECTOR: EXCEPTION $e');
    debugPrint('TEAM_SELECTOR: STACKTRACE $st');
  } finally {
    if (mounted) {
      setState(() => _loading = false);
      debugPrint('TEAM_SELECTOR: _loadTeamMembers FINISHED');
    }
  }
}



  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_allUsers);
      } else {
        _filteredUsers = _allUsers.where((user) {
          final name = (user['name'] as String).toLowerCase();
          final designation = (user['designation'] as String).toLowerCase();
          return name.contains(query) || designation.contains(query);
        }).toList();
      }
    });
  }

  void _toggleUser(String uid) {
    final newSelection = List<String>.from(widget.selectedUserIds);
    if (newSelection.contains(uid)) {
      newSelection.remove(uid);
    } else {
      newSelection.add(uid);
    }
    widget.onSelectionChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field
        TextFormField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Search Team Members',
            labelStyle: const TextStyle(color: Colors.white70),
            floatingLabelStyle: const TextStyle(color: Colors.cyanAccent),
            prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
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
          ),
        ),
        const SizedBox(height: 12),

        // Selected count
        if (widget.selectedUserIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${widget.selectedUserIds.length} member(s) selected',
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        // User list
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.cyanAccent),
              ),
            ),
          )
        else if (_filteredUsers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'No team members found',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                final uid = user['uid'] as String;
                final isSelected = widget.selectedUserIds.contains(uid);

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (_) => _toggleUser(uid),
                  title: Text(
                    user['name'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    user['designation'] as String,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  activeColor: Colors.cyanAccent,
                  checkColor: Colors.black,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
          ),
      ],
    );
  }
}
