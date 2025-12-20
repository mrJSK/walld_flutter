import 'package:cloud_firestore/cloud_firestore.dart';

import 'designation/designation_model.dart';
import 'role_permission/role_permission_model.dart';
import 'form_schema/form_schema_model.dart';

class MetadataRepository {
  final FirebaseFirestore _db;

  MetadataRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;
  /* ------------------------------ Designations ----------------------------- */

  Future<List<DesignationMeta>> loadDesignations(String tenantId) async {
    final snap = await _db
        .collection('tenants/$tenantId/metadata')
        .doc('designations')
        .get();

    final List<DesignationMeta> result = [];

    if (snap.exists && snap.data() != null) {
      final data = snap.data() as Map<String, dynamic>;
      final map =
          (data['designations'] ?? <String, dynamic>{}) as Map<String, dynamic>;
      for (final entry in map.entries) {
        result.add(DesignationMeta.fromMap(entry.key, entry.value));
      }
    }

    // Seed default if empty
    if (result.isEmpty) {
      result.add(
        DesignationMeta(
          id: 'developer',
          name: 'Developer',
          hierarchyLevel: 1,
          reportsTo: const [],
          permissions: const ['all'],
          screenAccess: const ['developer'],
          requiresApproval: false,
          isRoot: true,
        ),
      );
    }

    return result;
  }

  Future<void> saveDesignations(
      String tenantId, List<DesignationMeta> list) async {
    final data = {
      'designations': {for (final d in list) d.id: d.toMap()},
    };

    await _db
        .collection('tenants/$tenantId/metadata')
        .doc('designations')
        .set(data);
  }

  /* --------------------------- Role Permissions --------------------------- */

  Future<List<RolePermissionMeta>> loadRolePermissions(
      String tenantId) async {
    final snap = await _db
        .collection('tenants/$tenantId/metadata')
        .doc('rolePermissions')
        .get();

    final List<RolePermissionMeta> result = [];

    if (snap.exists && snap.data() != null) {
      final data = snap.data() as Map<String, dynamic>;
      final map =
          (data['roles'] ?? <String, dynamic>{}) as Map<String, dynamic>;
      for (final entry in map.entries) {
        result.add(RolePermissionMeta.fromMap(entry.key, entry.value));
      }
    }

    if (result.isEmpty) {
      result.add(RolePermissionMeta(roleId: 'developer_root', permissions: ['*']));
    }

    return result;
  }

  Future<void> saveRolePermissions(
      String tenantId, List<RolePermissionMeta> list) async {
    final data = {
      'roles': {for (final r in list) r.roleId: r.toMap()},
    };

    await _db
        .collection('tenants/$tenantId/metadata')
        .doc('rolePermissions')
        .set(data);
  }

  /* ------------------------------ Form Schemas ---------------------------- */

  Future<List<FormSchemaMeta>> loadFormSchemas(String tenantId) async {
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
      result.add(
        FormSchemaMeta(
          formId: 'user_registration',
          name: 'User Registration Form',
          description: 'New user signup with designation + department',
          rawJsonSchema: FormSchemaMeta.defaultUserRegistrationSchema(),
        ),
      );
    }

    return result;
  }

  Future<void> saveFormSchemas(
      String tenantId, List<FormSchemaMeta> list) async {
    final forms = <String, dynamic>{};

    for (final f in list) {
      forms[f.formId] = f.toFirestore();
    }

    await _db
        .collection('tenants/$tenantId/metadata')
        .doc('formSchemas')
        .set({'forms': forms});
  }
}
