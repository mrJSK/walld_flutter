import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
    setState(() => _loading = true);

    try {
      final usersSnap = await FirebaseFirestore.instance
          .collection('tenants')
          .doc(widget.tenantId)
          .collection('users')
          .where('nodeId', isEqualTo: widget.currentNodeId)
          .where('level', isEqualTo: widget.currentLevel)
          .where('status', isEqualTo: 'active')
          .get();

      _allUsers = usersSnap.docs.map((doc) {
        final data = doc.data();
        final uid = doc.id;

        // ✅ Use profile_data.fullName → fallback to fullName → fallback to uid
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
      debugPrint('Loaded ${_allUsers.length} team members');
    } catch (e) {
      debugPrint('Error loading team members: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
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
                    user['name'] as String, // ✅ shows fullName, not UID
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    user['designation'] as String, // e.g. "team_lead"
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
