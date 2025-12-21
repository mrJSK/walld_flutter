import 'package:cloud_firestore/cloud_firestore.dart';
import 'org_node_model.dart';

class HierarchyRepository {
  final FirebaseFirestore _db;

  HierarchyRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  static const String tenantId = 'default_tenant';

  Future<List<OrgNodeMeta>> loadHierarchy() async {
    // 1. Load all docs without Firestore orderBy → no composite index needed
    final snap = await _db
        .collection('tenants/$tenantId/organizations')
        .doc('hierarchy')
        .collection('nodes')
        .get();

    // 2. Map to models
    final nodes = snap.docs
        .map((doc) => OrgNodeMeta.fromMap(doc.id, doc.data()))
        .toList();

    // 3. Apply same ordering in Dart: first by level, then by name
    nodes.sort((a, b) {
      final levelCmp = a.level.compareTo(b.level);
      if (levelCmp != 0) return levelCmp;
      return a.name.compareTo(b.name);
    });

    return nodes;
  }

  Future<void> saveHierarchy(List<OrgNodeMeta> nodes) async {
    final batch = _db.batch();
    final coll = _db
        .collection('tenants/$tenantId/organizations')
        .doc('hierarchy')
        .collection('nodes');

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
