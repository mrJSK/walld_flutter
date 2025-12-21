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
    loadHierarchy();
  }

  Future<void> loadHierarchy() async {
    setState(() => loading = true);
    try {
      final nodes = await repo.loadHierarchyWithUserCounts(tenantId);
      setState(() {
        hierarchyNodes = nodes;
        status = 'Loaded ${nodes.length} nodes';
        statusColor = Colors.greenAccent;
      });
    } catch (e) {
      setState(() {
        status = 'Error: $e';
        statusColor = Colors.redAccent;
      });
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> loadNodeUsers(String nodeId) async {
    setState(() => loading = true);
    try {
      final users = await repo.loadUsersByNode(tenantId, nodeId);
      setState(() {
        selectedNodeId = nodeId;
        nodeUsers = users;
        status = 'Loaded ${users.length} users';
        statusColor = Colors.greenAccent;
      });
    } catch (e) {
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
      // Pick CSV file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final csvData = result.files.first.bytes;
      if (csvData == null) {
        showError('Failed to read file');
        return;
      }

      // Parse CSV
      final csvString = String.fromCharCodes(csvData);
      final List<List<dynamic>> csvTable =
          const CsvToListConverter().convert(csvString);

      if (csvTable.isEmpty || csvTable.length < 2) {
        showError('CSV file is empty or has no data rows');
        return;
      }

      // Skip header row and parse
      final List<CSVUserData> users = [];
      for (int i = 1; i < csvTable.length; i++) {
        try {
          final row = csvTable[i].map((e) => e.toString()).toList();
          users.add(CSVUserData.fromCSVRow(row));
        } catch (e) {
          showError('Error parsing row ${i + 1}: $e');
          return;
        }
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

      final validation = await repo.validateCSVData(tenantId, users);

      setState(() => loading = false);

      if (!validation.isValid) {
        showValidationErrorDialog(validation, users);
        return;
      }

      // Show confirmation dialog
      showConfirmationDialog(users, validation);
    } catch (e) {
      showError('Failed to process CSV: $e');
    }
  }

  void showValidationErrorDialog(
    ValidationResult validation,
    List<CSVUserData> users,
  ) {
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
                  ...validation.warnings.map(
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

  void showConfirmationDialog(
    List<CSVUserData> users,
    ValidationResult validation,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111118),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.greenAccent),
            SizedBox(width: 12),
            Text('Format Correct!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A28),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✓ Total Users: ${users.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '✓ Valid Nodes: ${validation.validNodeIds.length}',
                      style: const TextStyle(color: Colors.greenAccent),
                    ),
                    if (validation.warnings.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '⚠ Warnings: ${validation.warnings.length}',
                        style: const TextStyle(color: Colors.orangeAccent),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will create Firebase Auth accounts and place users in their nodes.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              if (validation.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Warnings:',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ...validation.warnings.take(3).map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          '• $w',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ),
              ],
            ],
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel, color: Colors.redAccent),
            label: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              importUsers(users);
            },
            icon: const Icon(Icons.upload, color: Colors.black),
            label: const Text('Import to Database'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
            ),
          ),
        ],
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
                    'Import users via CSV and view organization hierarchy',
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
                                      style: TextStyle(color: Colors.white70),
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
                                        onTap: () => loadNodeUsers(node['id']),
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
                              : 'Users in ${hierarchyNodes.firstWhere((n) => n['id'] == selectedNodeId, orElse: () => {'name': 'Node'})['name']}',
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_back,
                                      size: 48,
                                      color: Colors.white24,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Click a node on the left',
                                      style: TextStyle(color: Colors.white54),
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
                                          style:
                                              TextStyle(color: Colors.white70),
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
                                              user['profiledata'] as Map? ?? {};
                                          return ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor:
                                                  Colors.cyan.withOpacity(0.2),
                                              child: Text(
                                                (profile['fullName'] ?? 'U')
                                                    .toString()[0]
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                    color: Colors.cyan),
                                              ),
                                            ),
                                            title: Text(
                                              profile['fullName'] ?? 'Unknown',
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                            subtitle: Text(
                                              profile['email'] ?? '',
                                              style: const TextStyle(
                                                  color: Colors.white70),
                                            ),
                                            trailing: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.greenAccent
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                user['status'] ?? 'active',
                                                style: const TextStyle(
                                                  color: Colors.greenAccent,
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

// Import progress dialog
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
                style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                      children: (result!['failedUsers'] as List<String>)
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                '• $e',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          )
                          .toList(),
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
