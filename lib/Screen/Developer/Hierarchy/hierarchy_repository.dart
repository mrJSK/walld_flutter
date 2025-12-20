import 'package:cloud_firestore/cloud_firestore.dart';

import 'org_node_model.dart';

class HierarchyRepository {
  final FirebaseFirestore _db;

  HierarchyRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Future<List<OrgNodeMeta>> loadHierarchy(String tenantId) async {
    final snap = await _db
        .collection('tenants/$tenantId/organizations')
        .doc('hierarchy')
        .collection('nodes')
        .get();

    final List<OrgNodeMeta> result = [];

    for (final doc in snap.docs) {
      result.add(OrgNodeMeta.fromMap(doc.id, doc.data()));
    }

    if (result.isEmpty) {
      // seed one root node
      result.add(
        OrgNodeMeta(
          id: 'root',
          name: 'Head Office',
          parentId: null,
          level: 0,
          designationIds: const [],
          isActive: true,
        ),
      );
      await saveHierarchy(tenantId, result);
    }

    return result;
  }

  Future<void> saveHierarchy(
      String tenantId, List<OrgNodeMeta> nodes) async {
    final batch = _db.batch();
    final coll = _db
        .collection('tenants/$tenantId/organizations')
        .doc('hierarchy')
        .collection('nodes');

    // Clear existing (simple approach for now)
    final existing = await coll.get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    for (final node in nodes) {
      final ref = coll.doc(node.id);
      batch.set(ref, node.toMap());
    }

    await batch.commit();
  }
}
