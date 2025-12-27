import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/glass_container.dart';
import 'models/assigned_task_view_model.dart';
import 'widgets/assigned_task_list.dart';
import 'widgets/assigned_task_workspace.dart';

class ViewAssignedTasksPage extends StatefulWidget {
  const ViewAssignedTasksPage({super.key});

  static const String tenantId = 'default_tenant';

  @override
  State<ViewAssignedTasksPage> createState() => _ViewAssignedTasksPageState();
}

class _ViewAssignedTasksPageState extends State<ViewAssignedTasksPage> {
  AssignedTaskViewModel? _selectedTask;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          'You must be logged in to see assigned tasks.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final uid = user.uid;

    final stream = FirebaseFirestore.instance
        .collection('tenants')
        .doc(ViewAssignedTasksPage.tenantId)
        .collection('tasks')
        .orderBy('created_at', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.cyanAccent),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildError(snapshot.error);
        }

        final allDocs = snapshot.data?.docs ?? [];

        // Filter tasks where current uid is in assigned_to (comma-separated)
        final myTasks = allDocs.where((doc) {
          final data = doc.data();
          final assignedTo = (data['assigned_to'] ?? '') as String;
          if (assignedTo.isEmpty) return false;
          final assignees =
              assignedTo.split(',').map((s) => s.trim()).toList();
          return assignees.contains(uid);
        }).toList();

        if (myTasks.isEmpty) {
          return const Center(
            child: Text(
              'No tasks are currently assigned to you.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final models = myTasks.map((doc) {
          final data = doc.data();
          return AssignedTaskViewModel.fromFirestore(
            docId: doc.id,
            data: data,
          );
        }).toList();

        // Ensure selected task is valid
        if (_selectedTask != null) {
          final exists = models.any((t) => t.docId == _selectedTask!.docId);
          if (!exists) {
            _selectedTask = null;
          }
        }

        return Row(
          children: [
            // LEFT: List of assigned tasks
            Expanded(
              flex: 2,
              child: AssignedTaskList(
                tasks: models,
                selectedTaskId: _selectedTask?.docId,
                currentUserId: uid,  // ADD THIS
                onTaskSelected: (task) {
                  setState(() => _selectedTask = task);
                },
              ),
            ),
            // RIGHT: Workspace
            Expanded(
              flex: 3,
              child: _selectedTask == null
                  ? _buildEmptyWorkspace()
                  : AssignedTaskWorkspace(
                      task: _selectedTask!,
                      currentUserUid: uid,
                      tenantId: ViewAssignedTasksPage.tenantId,
                      onBack: () {
                        setState(() => _selectedTask = null);
                      },
                    ),
            ),
          ],
        );

      },
    );
  }

  Widget _buildEmptyWorkspace() {
    return Center(
      child: GlassContainer(
        blur: 18,
        opacity: 0.12,
        tint: Colors.black,
        borderRadius: BorderRadius.circular(18),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: const Text(
          'Select a task from the left to see details.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildError(Object? error) {
    String debugMessage = 'Unknown snapshot error: $error';
    String consoleUrl = '';

    if (error is FirebaseException && error.message != null) {
      final msg = error.message!;
      final marker = 'https://';
      final idx = msg.indexOf(marker);
      if (idx != -1) {
        consoleUrl = msg.substring(idx).trim();
        debugPrint('🔥 FIRESTORE INDEX URL: $consoleUrl');
      } else {
        debugPrint('Firestore error (no URL found): $msg');
      }
    } else {
      debugPrint(debugMessage);
    }

    return Center(
      child: Text(
        'Failed to load assigned tasks.\n'
        'Check debug console for Firestore details.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}
