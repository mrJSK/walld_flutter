// lib/Screen/Developer/UserDatabase/userdatabasepanel.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'userdatabaserepository.dart';
import 'userdatabasemodel.dart';

class UserDatabasePanel extends StatefulWidget {
  const UserDatabasePanel({super.key});

  @override
  State<UserDatabasePanel> createState() => _UserDatabasePanelState();
}

class _UserDatabasePanelState extends State<UserDatabasePanel> {
  // Ensure this matches your Firestore structure exactly
  static const String tenantId = 'default_tenant'; 
  final UserDatabaseRepository repo = UserDatabaseRepository();

  List<Map<String, dynamic>> hierarchyNodes = [];
  String? selectedNodeId;
  List<Map<String, dynamic>> nodeUsers = [];
  bool loading = false;
  String? status;
  Color statusColor = Colors.greenAccent;

  @override
  void initState() {
    super.initState();
    print("--- UI DEBUG: Init State - Loading Hierarchy for $tenantId ---");
    loadHierarchy();
  }

  Future<void> loadHierarchy() async {
    setState(() => loading = true);
    try {
      final nodes = await repo.loadHierarchyWithUserCounts(tenantId);
      print("--- UI DEBUG: Hierarchy Loaded - ${nodes.length} nodes found ---");
      setState(() {
        hierarchyNodes = nodes;
        status = 'Loaded ${nodes.length} nodes';
        statusColor = Colors.greenAccent;
      });
    } catch (e) {
      print("--- UI DEBUG: Hierarchy Error: $e ---");
      setState(() {
        status = 'Error: $e';
        statusColor = Colors.redAccent;
      });
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> loadNodeUsers(String nodeId) async {
    print("--- UI DEBUG: Loading Users for Node ID: $nodeId ---");
    setState(() => loading = true);
    try {
      final users = await repo.loadUsersByNode(tenantId, nodeId);
      print("--- UI DEBUG: Node Users Loaded - ${users.length} users found ---");
      setState(() {
        selectedNodeId = nodeId;
        nodeUsers = users;
        status = 'Loaded ${users.length} users';
        statusColor = Colors.greenAccent;
      });
    } catch (e) {
      print("--- UI DEBUG: Node User Error: $e ---");
      setState(() {
        status = 'Error: $e';
        statusColor = Colors.redAccent;
      });
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> pickAndUploadCSV() async {
    try {
      print("--- UI DEBUG: STARTING CSV PICK ---");
      
      // Pick CSV file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        print("--- UI DEBUG: File Picker Cancelled ---");
        return;
      }

      final csvData = result.files.first.bytes;
      if (csvData == null) {
        print("--- UI DEBUG: Failed to read bytes from file ---");
        showError('Failed to read file');
        return;
      }

      // Parse CSV
      final csvString = String.fromCharCodes(csvData);
      print("--- UI DEBUG: CSV Raw String Length: ${csvString.length} ---");
      
      final List<List<dynamic>> csvTable =
          const CsvToListConverter().convert(csvString);

      print("--- UI DEBUG: CSV Parsed Rows: ${csvTable.length} ---");

      if (csvTable.isEmpty || csvTable.length < 2) {
        showError('CSV file is empty or has no data rows');
        return;
      }

      // Skip header row and parse
      final List<CSVUserData> users = [];
      for (int i = 1; i < csvTable.length; i++) {
        try {
          final row = csvTable[i].map((e) => e.toString()).toList();
          if (row.every((e) => e.trim().isEmpty)) continue; // Skip empty lines
          users.add(CSVUserData.fromCSVRow(row));
        } catch (e) {
          print("--- UI DEBUG: Error parsing row ${i + 1}: $e ---");
          showError('Error parsing row ${i + 1}: $e');
          return;
        }
      }

      print("--- UI DEBUG: Successfully parsed ${users.length} User Objects ---");
      if (users.isNotEmpty) {
        print("--- UI DEBUG: Sample User 1 Email: ${users.first.email} ---");
        print("--- UI DEBUG: Sample User 1 Node: ${users.first.nodeId} ---");
      }

      if (users.isEmpty) {
        showError('No valid users found in CSV');
        return;
      }

      // Validate CSV data
      setState(() {
        loading = true;
        status = 'Validating ${users.length} users...';
      });

      print("--- UI DEBUG: Calling Repo validateCSVData ---");
      final validation = await repo.validateCSVData(tenantId, users);

      print("--- UI DEBUG: VALIDATION RETURNED ---");
      print("   > IsValid: ${validation.isValid}");
      print("   > New Users: ${validation.newUsers.length}");
      print("   > Updates: ${validation.usersToUpdate.length}");
      print("   > Diffs Found: ${validation.diffs.length}");
      print("   > Errors: ${validation.errors.length}");

      setState(() => loading = false);

      if (!validation.isValid) {
        showValidationErrorDialog(validation);
        return;
      }

      // Show the Diff Review Dialog instead of simple confirmation
      showDiffReviewDialog(validation);

    } catch (e) {
      print("--- UI DEBUG: FATAL EXCEPTION IN PICKER: $e ---");
      showError('Failed to process CSV: $e');
    }
  }

  void showValidationErrorDialog(ValidationResult validation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111118),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent),
            SizedBox(width: 12),
            Text('CSV Validation Failed', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Found ${validation.errors.length} errors:',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...validation.errors.map(
                  (error) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.red)),
                        Expanded(
                          child: Text(
                            error,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (validation.warnings.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    '${validation.warnings.length} warnings:',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...validation.warnings.take(5).map(
                    (warning) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⚠ ',
                              style: TextStyle(color: Colors.orange)),
                          Expanded(
                            child: Text(
                              warning,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (validation.warnings.length > 5)
                     Padding(
                       padding: const EdgeInsets.only(left: 20),
                       child: Text(
                         '...and ${validation.warnings.length - 5} more warnings',
                         style: const TextStyle(color: Colors.white30, fontStyle: FontStyle.italic),
                       ),
                     )
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.cyan)),
          ),
        ],
      ),
    );
  }

  void showDiffReviewDialog(ValidationResult validation) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DiffReviewDialog(
        validation: validation,
        onConfirm: () {
          Navigator.pop(context);
          // Only import NEW and UPDATES. Skip Conflicts.
          importUsers([...validation.newUsers, ...validation.usersToUpdate]);
        },
      ),
    );
  }

  Future<void> importUsers(List<CSVUserData> users) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ImportProgressDialog(
        tenantId: tenantId,
        users: users,
        repo: repo,
        onComplete: () {
          print("--- UI DEBUG: Import Completed, Refreshing Data ---");
          loadHierarchy();
          if (selectedNodeId != null) {
            loadNodeUsers(selectedNodeId!);
          }
        },
      ),
    );
  }

  void showError(String message) {
    setState(() {
      status = message;
      statusColor = Colors.redAccent;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Database',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Import users (New or Update) via CSV',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Upload button on top right
            FilledButton.icon(
              onPressed: loading ? null : pickAndUploadCSV,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload CSV'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Status bar
        if (status != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: statusColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status!,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() => status = null),
                  color: statusColor,
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Main content
        Expanded(
          child: Row(
            children: [
              // Left: Hierarchy tree
              SizedBox(
                width: 320,
                child: Card(
                  color: const Color(0xFF111118),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Text(
                              'Organization Hierarchy',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 18),
                              onPressed: loading ? null : loadHierarchy,
                              color: Colors.cyan,
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white12, height: 1),
                      Expanded(
                        child: loading && hierarchyNodes.isEmpty
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.cyan,
                                ),
                              )
                            : hierarchyNodes.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No nodes found',
                                      style:
                                          TextStyle(color: Colors.white70),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: hierarchyNodes.length,
                                    itemBuilder: (context, index) {
                                      final node = hierarchyNodes[index];
                                      final isSelected =
                                          selectedNodeId == node['id'];
                                      return ListTile(
                                        selected: isSelected,
                                        selectedTileColor:
                                            const Color(0xFF1A1A25),
                                        leading: Icon(
                                          Icons.account_tree_rounded,
                                          color: isSelected
                                              ? Colors.cyan
                                              : Colors.grey,
                                          size: 20,
                                        ),
                                        title: Text(
                                          node['name'] ?? 'Unknown',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.cyan
                                                : Colors.white,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Level ${node['level']} • ${node['userCount'] ?? 0} users',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11,
                                          ),
                                        ),
                                        onTap: () =>
                                            loadNodeUsers(node['id']),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Right: Node users
              Expanded(
                child: Card(
                  color: const Color(0xFF111118),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          selectedNodeId == null
                              ? 'Select a node to view users'
                              : 'Users in ${hierarchyNodes.firstWhere(
                                  (n) => n['id'] == selectedNodeId,
                                  orElse: () => {'name': 'Node'},
                                )['name']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Divider(color: Colors.white12, height: 1),
                      Expanded(
                        child: selectedNodeId == null
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_back,
                                      size: 48,
                                      color: Colors.white24,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Click a node on the left',
                                      style:
                                          TextStyle(color: Colors.white54),
                                    ),
                                  ],
                                ),
                              )
                            : loading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.cyan,
                                    ),
                                  )
                                : nodeUsers.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'No users in this node',
                                          style: TextStyle(
                                              color: Colors.white70),
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: nodeUsers.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(
                                                color: Colors.white12),
                                        itemBuilder: (context, index) {
                                          final user = nodeUsers[index];
                                          final profile =
                                              user['profiledata']
                                                      as Map? ??
                                                  {};

                                          return ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: Colors.cyan
                                                  .withOpacity(0.2),
                                              child: Text(
                                                (profile['fullName'] ??
                                                        'U')
                                                    .toString()[0]
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.cyan,
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              profile['fullName'] ??
                                                  'Unknown',
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                if ((user['designation'] ??
                                                            '')
                                                        .toString()
                                                        .isNotEmpty)
                                                  Text(
                                                    '${user['designation']} • ${user['employeeType'] ?? 'N/A'}',
                                                    style:
                                                        const TextStyle(
                                                      color:
                                                          Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                Text(
                                                  profile['email'] ?? '',
                                                  style:
                                                      const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            trailing: Container(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.greenAccent
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12),
                                              ),
                                              child: Text(
                                                user['status'] ??
                                                    'active',
                                                style:
                                                    const TextStyle(
                                                  color:
                                                      Colors.greenAccent,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                      ),
                    ],
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

// -----------------------------------------------------------------------------
// NEW WIDGETS START HERE
// -----------------------------------------------------------------------------

class DiffReviewDialog extends StatefulWidget {
  final ValidationResult validation;
  final VoidCallback onConfirm;

  const DiffReviewDialog({
    super.key,
    required this.validation,
    required this.onConfirm,
  });

  @override
  State<DiffReviewDialog> createState() => _DiffReviewDialogState();
}

class _DiffReviewDialogState extends State<DiffReviewDialog> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    // 1. Filter Lists based on Search Query
    final filteredDiffs = widget.validation.diffs
        .where((d) => d.email.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    final filteredConflicts = widget.validation.authConflicts
        .where((u) => u.email.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    final filteredNewUsers = widget.validation.newUsers
        .where((u) => u.email.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return AlertDialog(
      backgroundColor: const Color(0xFF111118),
      title: const Row(
        children: [
          Icon(Icons.rate_review, color: Colors.cyan),
          SizedBox(width: 12),
          Text('Review Import Data', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. Summary Stats Badge Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _statBadge(
                      'Total',
                      widget.validation.newUsers.length +
                          widget.validation.usersToUpdate.length +
                          widget.validation.authConflicts.length,
                      Colors.white),
                  const SizedBox(width: 8),
                  _statBadge('New', widget.validation.newUsers.length,
                      Colors.greenAccent),
                  const SizedBox(width: 8),
                  _statBadge('Updates', widget.validation.usersToUpdate.length,
                      Colors.orangeAccent),
                  const SizedBox(width: 8),
                  _statBadge('Conflicts', widget.validation.authConflicts.length,
                      Colors.redAccent),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Search Bar
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                hintText: 'Search by email...',
                hintStyle: const TextStyle(color: Colors.white30),
                prefixIcon: const Icon(Icons.search, color: Colors.cyan),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
            const SizedBox(height: 16),

            // 4. Scrollable Content List
            Expanded(
              child: ListView(
                children: [
                  // --- SECTION: CONFLICTS (Red) ---
                  if (filteredConflicts.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text("⚠ Auth Conflicts (Skipped)",
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold)),
                    ),
                    ...filteredConflicts.map((u) => Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: Colors.redAccent.withOpacity(0.3))),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Colors.redAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(u.email,
                                      style: const TextStyle(
                                          color: Colors.white70))),
                              const Text("Exists in Auth only",
                                  style: TextStyle(
                                      color: Colors.white30, fontSize: 10)),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // --- SECTION: UPDATES (Orange) ---
                  if (filteredDiffs.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text("Updates",
                          style: TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold)),
                    ),
                    ...filteredDiffs.map((diff) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.orangeAccent.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.edit,
                                      color: Colors.orangeAccent, size: 14),
                                  const SizedBox(width: 8),
                                  Text(diff.email,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Divider(color: Colors.white10),
                              ...diff.changes.entries.map((e) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 2.0),
                                    child: Row(
                                      children: [
                                        Text('${e.key}: ',
                                            style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12)),
                                        Text('${e.value['old']}',
                                            style: const TextStyle(
                                                color: Colors.redAccent,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                fontSize: 12)),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 4),
                                          child: Icon(Icons.arrow_right_alt,
                                              color: Colors.white30, size: 14),
                                        ),
                                        Text('${e.value['new']}',
                                            style: const TextStyle(
                                                color: Colors.greenAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // --- SECTION: NEW USERS (Green) ---
                  if (filteredNewUsers.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text("New Users",
                          style: TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.greenAccent.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (searchQuery.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                  "Ready to create ${filteredNewUsers.length} new users.",
                                  style: const TextStyle(color: Colors.white70)),
                            ),
                          // List individual new users
                          ...filteredNewUsers.map((u) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.add_circle_outline,
                                        color: Colors.greenAccent, size: 14),
                                    const SizedBox(width: 8),
                                    Text(u.email,
                                        style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12)),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],

                  // Empty State
                  if (filteredConflicts.isEmpty &&
                      filteredDiffs.isEmpty &&
                      filteredNewUsers.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text("No matches found.",
                            style: TextStyle(color: Colors.white30)),
                      ),
                    )
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        FilledButton.icon(
          onPressed: widget.onConfirm,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Confirm & Sync'),
          style: FilledButton.styleFrom(
              backgroundColor: Colors.cyan, foregroundColor: Colors.black),
        ),
      ],
    );
  }

  Widget _statBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 8),
          Text('$label: $count',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class ImportProgressDialog extends StatefulWidget {
  final String tenantId;
  final List<CSVUserData> users;
  final UserDatabaseRepository repo;
  final VoidCallback onComplete;

  const ImportProgressDialog({
    super.key,
    required this.tenantId,
    required this.users,
    required this.repo,
    required this.onComplete,
  });

  @override
  State<ImportProgressDialog> createState() => _ImportProgressDialogState();
}

class _ImportProgressDialogState extends State<ImportProgressDialog> {
  int current = 0;
  int total = 0;
  String message = '';
  bool isComplete = false;
  Map<String, dynamic>? result;

  @override
  void initState() {
    super.initState();
    total = widget.users.length;
    startImport();
  }

  Future<void> startImport() async {
    final res = await widget.repo.importUsers(
      widget.tenantId,
      widget.users,
      (curr, tot, msg) {
        setState(() {
          current = curr;
          total = tot;
          message = msg;
        });
      },
    );

    setState(() {
      isComplete = true;
      result = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111118),
      title: Row(
        children: [
          if (!isComplete)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.cyan,
              ),
            )
          else
            const Icon(Icons.check_circle, color: Colors.greenAccent),
          const SizedBox(width: 12),
          Text(
            isComplete ? 'Import Complete' : 'Importing Users...',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isComplete) ...[
              LinearProgressIndicator(
                value: total > 0 ? current / total : 0,
                backgroundColor: Colors.white12,
                color: Colors.cyan,
              ),
              const SizedBox(height: 16),
              Text(
                'Progress: $current / $total',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✓ Successfully imported: ${result!['success']}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (result!['failed'] > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '✗ Failed: ${result!['failed']}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ],
                ),
              ),
              if (result!['failedUsers'].isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Failed users:',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 150,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          (result!['failedUsers'] as List<String>).map(
                        (e) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              '• $e',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        if (isComplete)
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onComplete();
            },
            child: const Text('Close'),
          ),
      ],
    );
  }
}