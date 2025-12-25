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

    final stream = FirebaseFirestore.instance
        .collection('tenants')
        .doc(tenantId)
        .collection('tasks')
        .where('assigned_to', isEqualTo: uid)   // 👈 filter by current user
        .orderBy('created_at', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
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

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
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
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = docs[index].data();
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

              return GlassContainer(
                blur: 18,
                opacity: 0.18,
                tint: Colors.black,
                borderRadius: BorderRadius.circular(18),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: main content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.isEmpty ? '(No title)' : title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
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
