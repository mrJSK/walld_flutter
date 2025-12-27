import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models/created_task_view_model.dart';
import 'widgets/created_task_list.dart';
import 'widgets/created_task_workspace.dart';

class ViewAllTasksPage extends StatefulWidget {
  const ViewAllTasksPage({super.key});
  static const String tenantId = 'default_tenant';

  @override
  State<ViewAllTasksPage> createState() => _ViewAllTasksPageState();
}

class _ViewAllTasksPageState extends State<ViewAllTasksPage> {
  CreatedTaskViewModel? selectedTask;
  String? errorMessage;

  @override
Widget build(BuildContext context) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return const Center(
      child: Text(
        'You must be logged in',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  final uid = user.uid;
  
  // Query: WHERE assignedBy == currentUserUid
  final stream = FirebaseFirestore.instance
      .collection('tenants')
      .doc(ViewAllTasksPage.tenantId)
      .collection('tasks')
      .where('assignedby', isEqualTo: uid)
      .orderBy('createdat', descending: true)
      .snapshots();

  return StreamBuilder<QuerySnapshot>(
    stream: stream,
    builder: (context, snapshot) {
      // Handle errors
      if (snapshot.hasError) {
        final errorMessage = snapshot.error.toString();
        
        // Print error details to terminal
        debugPrint('═══════════════════════════════════════════════════════════');
        debugPrint('🔴 FIRESTORE INDEX ERROR');
        debugPrint('═══════════════════════════════════════════════════════════');
        debugPrint(errorMessage);
        debugPrint('═══════════════════════════════════════════════════════════');
        
        // Extract and print the Firebase Console URL
        final urlMatch = RegExp(r'https://console\.firebase\.google\.com[^\s]+')
            .firstMatch(errorMessage);
        if (urlMatch != null) {
          final indexUrl = urlMatch.group(0);
          debugPrint('');
          debugPrint('📌 CREATE INDEX HERE (Click the link below):');
          debugPrint(indexUrl);
          debugPrint('');
          debugPrint('═══════════════════════════════════════════════════════════');
        }
        
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 64,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Error loading tasks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'This query requires a Firestore index.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Check your terminal/console for the index creation link.',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Copy error to clipboard or trigger a refresh
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Loading state
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.cyan),
          ),
        );
      }

      final docs = snapshot.data?.docs ?? [];
      
      // Parse documents with error handling
      final models = <CreatedTaskViewModel>[];
      for (final doc in docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            models.add(
              CreatedTaskViewModel.fromFirestore(
                docId: doc.id,
                data: data,
              ),
            );
          }
        } catch (e) {
          debugPrint('⚠️  Error parsing task ${doc.id}: $e');
          // Continue to next document instead of crashing
        }
      }

      if (models.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 80,
                color: Colors.white.withOpacity(0.2),
              ),
              const SizedBox(height: 16),
              const Text(
                'No tasks created yet',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a new task to get started',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }

      // Ensure selectedTask is still valid
      if (selectedTask != null) {
        final exists = models.any((t) => t.docId == selectedTask!.docId);
        if (!exists) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => selectedTask = null);
            }
          });
        }
      }

      return Row(
        children: [
          // LEFT: List of created tasks
          Expanded(
            flex: 2,
            child: CreatedTaskList(
              tasks: models,
              selectedTaskId: selectedTask?.docId,
              onTaskSelected: (task) {
                setState(() => selectedTask = task);
              },
            ),
          ),
          // RIGHT: Workspace with chat to lead
          Expanded(
            flex: 3,
            child: selectedTask == null
                ? buildEmptyWorkspace()
                : CreatedTaskWorkspace(
                    task: selectedTask!,
                    currentUserUid: uid,
                    tenantId: ViewAllTasksPage.tenantId,
                    onBack: () {
                      setState(() => selectedTask = null);
                    },
                  ),
          ),
        ],
      );
    },
  );
}


  Widget buildEmptyWorkspace() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.touch_app,
            size: 64,
            color: Colors.white24,
          ),
          SizedBox(height: 16),
          Text(
            'Select a task from the left',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}


  Widget buildEmptyWorkspace() {
    return const Center(
      child: Text('Select a task from the left'),
    );
  }

