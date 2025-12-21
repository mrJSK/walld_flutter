import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class UserRepository {
  final FirebaseFirestore _db;

  UserRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Future<List<UserMeta>> loadPendingUsers(String tenantId) async {
    final snap = await _db
        .collection('tenants/$tenantId/users')
        .where('status', isEqualTo: 'pending_approval')
        .orderBy('createdat', descending: true)
        .get();

    return snap.docs.map((d) => UserMeta.fromMap(d.id, d.data())).toList();
  }

  Future<List<UserMeta>> loadAllUsers(String tenantId) async {
    final snap = await _db
        .collection('tenants/$tenantId/users')
        .orderBy('createdat', descending: true)
        .limit(100)
        .get();

    return snap.docs.map((d) => UserMeta.fromMap(d.id, d.data())).toList();
  }

  Future<void> approveUser(String tenantId, String userId) async {
    await _db.collection('tenants/$tenantId/users').doc(userId).update({
      'status': 'active',
      'approvedat': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectUser(String tenantId, String userId) async {
    await _db.collection('tenants/$tenantId/users').doc(userId).update({
      'status': 'rejected',
    });
  }

  Future<void> suspendUser(String tenantId, String userId) async {
    await _db.collection('tenants/$tenantId/users').doc(userId).update({
      'status': 'suspended',
    });
  }
}
