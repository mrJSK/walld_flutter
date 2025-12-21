import 'package:cloud_firestore/cloud_firestore.dart';
import 'org_node_model.dart';

class HierarchyRepository {
  final FirebaseFirestore _db;

  HierarchyRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // FIXED: single tenant id
  static const String tenantId = 'default_tenant';

  Future<List<OrgNodeMeta>> loadHierarchy() async {
    final snap = await _db
        .collection('tenants/$tenantId/organizations')
        .doc('hierarchy')
        .collection('nodes')
        .orderBy('level')
        .orderBy('name')
        .get();

    final result = snap.docs
        .map((doc) => OrgNodeMeta.fromMap(doc.id, doc.data()))
        .toList();

    return result;
  }

  Future<void> saveHierarchy(List<OrgNodeMeta> nodes) async {
    final batch = _db.batch();
    final coll = _db
        .collection('tenants/$tenantId/organizations')
        .doc('hierarchy')
        .collection('nodes');

    // Clear existing nodes
    final existing = await coll.get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    // Write new nodes
    for (final node in nodes) {
      final ref = coll.doc(node.id);
      batch.set(ref, node.toMap());
    }

    await batch.commit();
  }
}
