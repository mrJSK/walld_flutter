import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/glass_container.dart';

class ViewAssignedTasksPage extends StatelessWidget {
  const ViewAssignedTasksPage({super.key});

  static const String tenantId = 'default_tenant';

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

    // ✅ Fetch ALL tasks (no assigned_to filter here)
    final stream = FirebaseFirestore.instance
        .collection('tenants')
        .doc(tenantId)
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
          final error = snapshot.error;
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
            debugPrint('Unknown snapshot error: $error');
          }

          return Center(
            child: Text(
              'Failed to load assigned tasks.\n'
              'Check debug console for Firestore index URL.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final allDocs = snapshot.data?.docs ?? [];

        // ✅ Client-side filter: check if current user's UID is in assigned_to
        final myTasks = allDocs.where((doc) {
          final data = doc.data();
          final assignedTo = (data['assigned_to'] ?? '') as String;

          if (assignedTo.isEmpty) return false;

          // Check if UID appears in comma-separated list
          // Support both single UID and comma-separated UIDs
          final assignees = assignedTo.split(',').map((s) => s.trim()).toList();
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

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.separated(
            itemCount: myTasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = myTasks[index].data();
              final title = (data['title'] ?? '') as String;
              final description = (data['description'] ?? '') as String;
              final status = (data['status'] ?? 'PENDING') as String;
              final priority = (data['custom_fields']?['priority'] ?? '')
                  .toString()
                  .toUpperCase();
              final dueIso = (data['due_date'] ?? '') as String;

              DateTime? due;
              if (dueIso.isNotEmpty) {
                try {
                  due = DateTime.parse(dueIso);
                } catch (_) {}
              }

              // ✅ Show group indicator if it's a group task
              final groupName = (data['group_name'] ?? '') as String;
              final assignedTo = (data['assigned_to'] ?? '') as String;
              final assigneeCount = assignedTo.split(',').length;

              return GlassContainer(
                blur: 18,
                opacity: 0.18,
                tint: Colors.black,
                borderRadius: BorderRadius.circular(18),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title.isEmpty ? '(No title)' : title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Group indicator
                        if (groupName.isNotEmpty && assigneeCount > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purpleAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.purpleAccent.withOpacity(0.8),
                                  width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.group,
                                    size: 14, color: Colors.purpleAccent),
                                const SizedBox(width: 4),
                                Text(
                                  '$assigneeCount members',
                                  style: const TextStyle(
                                    color: Colors.purpleAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Group name if exists
                    if (groupName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Group: $groupName',
                          style: const TextStyle(
                            color: Colors.purpleAccent,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    // Description
                    if (description.isNotEmpty)
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),

                    const SizedBox(height: 6),

                    // Status row
                    Row(
                      children: [
                        if (priority.isNotEmpty)
                          _Chip(
                            label: priority,
                            color: Colors.deepOrangeAccent,
                          ),
                        const SizedBox(width: 6),
                        _Chip(
                          label: status,
                          color: status == 'COMPLETED'
                              ? Colors.greenAccent
                              : Colors.cyanAccent,
                        ),
                        const Spacer(),
                        if (due != null)
                          Text(
                            'Due: '
                            '${due.year}-${due.month.toString().padLeft(2, '0')}-'
                            '${due.day.toString().padLeft(2, '0')} '
                            '${due.hour.toString().padLeft(2, '0')}:'
                            '${due.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.8), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
