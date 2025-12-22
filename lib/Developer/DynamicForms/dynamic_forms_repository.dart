import 'package:cloud_firestore/cloud_firestore.dart';

import 'form_models.dart';

class DynamicFormsRepository {
  final FirebaseFirestore _db;

  DynamicFormsRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Future<List<FormSchemaMeta>> loadForms(String tenantId) async {
    final snap = await _db
        .collection('tenants/$tenantId/metadata')
        .doc('formSchemas')
        .get();

    final List<FormSchemaMeta> result = [];

    if (snap.exists && snap.data() != null) {
      final data = snap.data() as Map<String, dynamic>;
      final forms =
          (data['forms'] ?? <String, dynamic>{}) as Map<String, dynamic>;

      for (final entry in forms.entries) {
        final m = entry.value as Map<String, dynamic>;
        result.add(FormSchemaMeta.fromFirestore(entry.key, m));
      }
    }

    if (result.isEmpty) {
      result.add(FormSchemaMeta.defaultUserRegistration());
    }

    return result;
  }
}
