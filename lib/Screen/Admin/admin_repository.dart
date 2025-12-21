import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRepository {
  final FirebaseFirestore _db;

  AdminRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // ==================== DASHBOARD STATS ====================
  
  Future<Map<String, int>> loadTaskCounts(String tenantId) async {
    final coll = _db.collection('tenants/$tenantId/tasks');

    // HARDCODED: These are the core task statuses
    const statuses = <String>[
      'PENDING',
      'IN_PROGRESS',
      'BLOCKED',
      'PENDING_APPROVAL',
      'COMPLETED',
    ];

    final futures = <Future<QuerySnapshot>>[
      for (final s in statuses) coll.where('status', isEqualTo: s).get(),
    ];

    final snaps = await Future.wait(futures);

    return {
      'PENDING': snaps[0].size,
      'IN_PROGRESS': snaps[1].size,
      'BLOCKED': snaps[2].size,
      'PENDING_APPROVAL': snaps[3].size,
      'COMPLETED': snaps[4].size,
    };
  }

  Future<List<Map<String, dynamic>>> loadRecentTasks(
    String tenantId, {
    required String status,
    int limit = 20,
  }) async {
    final snap = await _db
        .collection('tenants/$tenantId/tasks')
        .where('status', isEqualTo: status)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .get();

    return snap.docs
        .map((d) => {
              'id': d.id,
              ...d.data(),
            })
        .toList();
  }

  Future<Map<String, int>> loadOrgHealth(String tenantId) async {
    final usersColl = _db.collection('tenants/$tenantId/users');
    final orgColl = _db
        .collection('tenants/$tenantId/organizations')
        .doc('hierarchy')
        .collection('nodes');
    final pendingUsersColl =
        _db.collection('tenants/$tenantId/users').where('status', isEqualTo: 'pending_approval');

    final results = await Future.wait([
      usersColl.where('status', isEqualTo: 'active').get(),
      orgColl.get(),
      pendingUsersColl.get(),
    ]);

    return {
      'activeUsers': results[0].size,
      'orgNodes': results[1].size,
      'pendingRegistrations': results[2].size,
    };
  }

  Future<List<Map<String, dynamic>>> loadPendingApprovals(
    String tenantId, {
    int limit = 20,
  }) async {
    final snap = await _db
        .collection('tenants/$tenantId/approvals')
        .where('status', isEqualTo: 'PENDING')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snap.docs
        .map((d) => {
              'id': d.id,
              ...d.data(),
            })
        .toList();
  }

  // ==================== APPROVAL ACTIONS ====================
  
  Future<void> approveTask(String tenantId, String approvalId) async {
    final ref = _db.collection('tenants/$tenantId/approvals').doc(approvalId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      final taskId = data['taskId'] as String?;
      if (taskId == null) return;

      final taskRef = _db.collection('tenants/$tenantId/tasks').doc(taskId);

      tx.update(ref, {
        'status': 'APPROVED',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.update(taskRef, {
        'status': 'COMPLETED',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectTask(String tenantId, String approvalId) async {
    final ref = _db.collection('tenants/$tenantId/approvals').doc(approvalId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      final taskId = data['taskId'] as String?;
      if (taskId == null) return;

      final taskRef = _db.collection('tenants/$tenantId/tasks').doc(taskId);

      tx.update(ref, {
        'status': 'REJECTED',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.update(taskRef, {
        'status': 'IN_PROGRESS', // back to work
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
