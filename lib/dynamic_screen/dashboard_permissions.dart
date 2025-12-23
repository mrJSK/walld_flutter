import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DashboardPermissions {
  static const String _tenantId = 'default_tenant';

  /// Pure helper – no setState/mounted/allowedWidgetIds inside this file.
  /// It only logs and then calls [onAllowedWidgetIds].
  static Future<void> loadUserPermissions({
    required BuildContext context,
    required String userId,
    required void Function(Set<String> allowedWidgetIds) onAllowedWidgetIds,
  }) async {
    debugPrint('[PERM] ---- loadUserPermissions START ----');
    debugPrint('[PERM] userId=$userId');

    try {
      // 1) Load user doc
      final userDoc = await FirebaseFirestore.instance
          .collection('tenants')
          .doc(_tenantId)
          .collection('users')
          .doc(userId)
          .get();

      debugPrint('[PERM] userDoc.exists = ${userDoc.exists}');
      if (!userDoc.exists) {
        debugPrint('[PERM] user doc missing -> signOut & login-only');
        await FirebaseAuth.instance.signOut();
        onAllowedWidgetIds({'login'});
        return;
      }

      final data = userDoc.data() as Map<String, dynamic>;
      debugPrint('[PERM] userDoc.data = $data');

      final designation = data['designation'] as String?;
      debugPrint('[PERM] designation = $designation');

      if (designation == null || designation.trim().isEmpty) {
        debugPrint('[PERM] designation null/empty -> signOut & login-only');
        await FirebaseAuth.instance.signOut();
        onAllowedWidgetIds({'login'});
        return;
      }

      // 2) Load designation metadata
      final metaDoc = await FirebaseFirestore.instance
          .collection('tenants')
          .doc(_tenantId)
          .collection('metadata')
          .doc('designations')
          .get();

      debugPrint('[PERM] metaDoc.exists = ${metaDoc.exists}');
      if (!metaDoc.exists) {
        debugPrint('[PERM] designations meta missing -> signOut & login-only');
        await FirebaseAuth.instance.signOut();
        onAllowedWidgetIds({'login'});
        return;
      }

      final meta = metaDoc.data() as Map<String, dynamic>;
      debugPrint('[PERM] meta keys = ${meta.keys.toList()}');

      final allDesignations =
          meta['designations'] as Map<String, dynamic>? ?? {};
      debugPrint(
          '[PERM] allDesignations keys = ${allDesignations.keys.toList()}');

      final designationData =
          allDesignations[designation] as Map<String, dynamic>?;
      debugPrint('[PERM] designationData = $designationData');

      if (designationData == null) {
        debugPrint(
            '[PERM] designation $designation not found -> signOut & login-only');
        await FirebaseAuth.instance.signOut();
        onAllowedWidgetIds({'login'});
        return;
      }

      final permissionsRaw =
          (designationData['permissions'] as List<dynamic>? ?? []);
      final permissions =
          permissionsRaw.map((e) => e.toString()).toSet();
      debugPrint('[PERM] permissions = $permissions');

      // 3) Map permissions to widget ids
      final allowed = <String>{};
      if (permissions.contains('create_task') ||
          permissions.contains('createtask')) {
        allowed.add('createtask');
      }
      if (permissions.contains('view_assigned_tasks') ||
          permissions.contains('viewassignedtasks')) {
        allowed.add('viewassignedtasks');
      }
      if (permissions.contains('view_all_tasks') ||
          permissions.contains('viewalltasks')) {
        allowed.add('viewalltasks');
      }
      if (permissions.contains('complete_task') ||
          permissions.contains('completetask')) {
        allowed.add('completetask');
      }

      debugPrint('[PERM] allowedWidgetIds computed = $allowed');

      onAllowedWidgetIds(allowed.isEmpty ? {'login'} : allowed);

      debugPrint('[PERM] ---- loadUserPermissions END OK ----');
    } catch (e, st) {
      debugPrint('[PERM] Permission load error: $e');
      debugPrint('[PERM] Stack: $st');
      // Do NOT auto sign-out during debugging; just fall back to login view.
      onAllowedWidgetIds({'login'});
    }
  }
}
