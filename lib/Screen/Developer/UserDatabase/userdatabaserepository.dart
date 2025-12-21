import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'userdatabasemodel.dart';

class UserDatabaseRepository {
  final FirebaseFirestore db;
  static const int RATE_LIMIT_DELAY_MS = 200; // Delay between operations

  UserDatabaseRepository({FirebaseFirestore? db})
      : db = db ?? FirebaseFirestore.instance;

  /// Validate CSV and prepare final usersToImport list
  Future<ValidationResult> validateCSVData(
    String tenantId,
    List<CSVUserData> users,
  ) async {
    List<String> errors = [];
    List<String> warnings = [];
    Set<String> validNodeIds = {};
    Set<String> invalidNodeIds = {};

    // ---------- LOAD NODES ----------
    final nodesSnap = await db
        .collection('tenants/$tenantId/organizations')
        .doc('hierarchy')
        .collection('nodes')
        .get();

    final existingNodeIds = nodesSnap.docs.map((doc) => doc.id).toSet();

    // ---------- DEDUP INSIDE CSV ----------
    final emailSet = <String>{};
    final uniqueUsers = <CSVUserData>[];

    for (int i = 0; i < users.length; i++) {
      final user = users[i];
      final rowNum = i + 2;
      final emailLower = user.email.trim().toLowerCase();

      // Email format
      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(user.email)) {
        errors.add('Row $rowNum: Invalid email format - ${user.email}');
        continue;
      }

      // Duplicate in CSV
      if (emailSet.contains(emailLower)) {
        warnings.add(
          'Row $rowNum: Duplicate email in CSV skipped - ${user.email}',
        );
        continue;
      }
      emailSet.add(emailLower);
      uniqueUsers.add(user);

      // Password
      if (user.password.length < 8) {
        errors.add(
          'Row $rowNum: Password must be at least 8 characters',
        );
      }

      // Full name
      if (user.fullName.isEmpty || user.fullName.length < 3) {
        errors.add(
          'Row $rowNum: Full name must be at least 3 characters',
        );
      }

      // Node ID
      if (user.nodeId.isEmpty) {
        errors.add('Row $rowNum: Node ID is required');
      } else if (existingNodeIds.contains(user.nodeId)) {
        validNodeIds.add(user.nodeId);
      } else {
        invalidNodeIds.add(user.nodeId);
        errors.add(
          'Row $rowNum: Node ID "${user.nodeId}" does not exist in organization',
        );
      }

      // Level
      if (user.level < 0) {
        warnings.add(
          'Row $rowNum: Invalid level value - ${user.level}',
        );
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
        validNodeIds: validNodeIds.toList(),
        invalidNodeIds: invalidNodeIds.toList(),
        usersToImport: const [],
      );
    }

    // ---------- SKIP EMAILS THAT ALREADY EXIST IN FIRESTORE ----------
    final existingEmails = <String>{};
    final emailList =
        uniqueUsers.map((u) => u.email.trim().toLowerCase()).toList();

    const int chunkSize = 10; // Firestore whereIn limit
    for (int i = 0; i < emailList.length; i += chunkSize) {
      final chunk = emailList.sublist(
        i,
        i + chunkSize > emailList.length ? emailList.length : i + chunkSize,
      );

      final snap = await db
          .collection('tenants/$tenantId/users')
          .where('profiledata.email', whereIn: chunk)
          .get();

      for (final doc in snap.docs) {
        final email =
            (doc.data()['profiledata']?['email'] as String?)?.toLowerCase();
        if (email != null) {
          existingEmails.add(email);
        }
      }
    }

    final usersToImport = <CSVUserData>[];
    for (final u in uniqueUsers) {
      final emailLower = u.email.trim().toLowerCase();
      if (existingEmails.contains(emailLower)) {
        warnings.add(
          'Email already exists in Firestore users, will be skipped: ${u.email}',
        );
      } else {
        usersToImport.add(u);
      }
    }

    if (usersToImport.isEmpty) {
      warnings.add('No new users to import after duplicate checks.');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      validNodeIds: validNodeIds.toList(),
      invalidNodeIds: invalidNodeIds.toList(),
      usersToImport: usersToImport,
    );
  }

  /// IMPORT USERS – SKIPS existing Auth accounts instead of failing
  Future<Map<String, dynamic>> importUsers(
    String tenantId,
    List<CSVUserData> users,
    Function(int current, int total, String message) progressCallback,
  ) async {
    int successCount = 0;
    int failureCount = 0;
    List<String> failedUsers = [];
    List<String> skippedExistingEmails = [];

    for (int i = 0; i < users.length; i++) {
      final user = users[i];
      progressCallback(i + 1, users.length, 'Processing ${user.email}...');

      try {
        // Simple rate limit
        if (i > 0 && i % 10 == 0) {
          await Future.delayed(
            const Duration(milliseconds: RATE_LIMIT_DELAY_MS),
          );
        }

        // --- NEW: check in Firebase Auth and SKIP if already registered ---
        final methods = await FirebaseAuth.instance
            .fetchSignInMethodsForEmail(user.email.trim());
        if (methods.isNotEmpty) {
          skippedExistingEmails.add(user.email);
          continue;
        }

        // Create Firebase Auth user
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: user.email,
          password: user.password,
        );

        final userId = userCredential.user!.uid;

        // Node-level user doc
        await db
            .collection('tenants/$tenantId/organizations')
            .doc('hierarchy')
            .collection('nodes')
            .doc(user.nodeId)
            .collection('users')
            .doc(userId)
            .set({
          'profiledata': {
            'email': user.email,
            'fullName': user.fullName,
          },
          'designation': 'employee',
          'nodeId': user.nodeId,
          'level': user.level,
          'status': 'active',
          'createdat': FieldValue.serverTimestamp(),
          'importedFromCSV': true,
        });

        // Global users collection
        await db
            .collection('tenants/$tenantId/users')
            .doc(userId)
            .set({
          'profiledata': {
            'email': user.email,
            'fullName': user.fullName,
          },
          'designation': 'employee',
          'status': 'active',
          'createdat': FieldValue.serverTimestamp(),
          'nodeId': user.nodeId,
        }, SetOptions(merge: true));

        successCount++;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Extra safety: treat as skipped, not failure
          skippedExistingEmails.add(user.email);
          continue;
        }
        failureCount++;
        failedUsers.add('${user.email}: ${e.code} - ${e.message}');
      } catch (e) {
        failureCount++;
        failedUsers.add('${user.email}: $e');
      }
    }

    return {
      'success': successCount,
      'failed': failureCount,
      'failedUsers': failedUsers,
      'skippedExistingEmails': skippedExistingEmails,
    };
  }

  Future<List<Map<String, dynamic>>> loadUsersByNode(
    String tenantId,
    String nodeId,
  ) async {
    final snap = await db
        .collection('tenants/$tenantId/organizations')
        .doc('hierarchy')
        .collection('nodes')
        .doc(nodeId)
        .collection('users')
        .orderBy('createdat', descending: true)
        .get();

    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> loadHierarchyWithUserCounts(
    String tenantId,
  ) async {
    final nodesSnap = await db
        .collection('tenants/$tenantId/organizations')
        .doc('hierarchy')
        .collection('nodes')
        .get();

    List<Map<String, dynamic>> nodesWithCounts = [];

    for (final nodeDoc in nodesSnap.docs) {
      final usersSnap =
          await nodeDoc.reference.collection('users').count().get();
      nodesWithCounts.add({
        'id': nodeDoc.id,
        ...nodeDoc.data(),
        'userCount': usersSnap.count ?? 0,
      });
    }

    nodesWithCounts.sort((a, b) {
      final levelCmp = (a['level'] as int).compareTo(b['level'] as int);
      if (levelCmp != 0) return levelCmp;
      return (a['name'] as String).compareTo(b['name'] as String);
    });

    return nodesWithCounts;
  }
}
