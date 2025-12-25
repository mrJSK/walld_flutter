// lib/Screen/Developer/UserDatabase/userdatabaserepository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'userdatabasemodel.dart';

class UserDatabaseRepository {
  final FirebaseFirestore db;
  final FirebaseAuth auth = FirebaseAuth.instance;
  static const int RATE_LIMIT_DELAY_MS = 200; // Delay between operations

  UserDatabaseRepository({FirebaseFirestore? db})
      : db = db ?? FirebaseFirestore.instance;

  /// Validate CSV and separate New Users from Updates with Diff logic
  Future<ValidationResult> validateCSVData(
    String tenantId,
    List<CSVUserData> users,
  ) async {
    print("--- DEBUG: STARTING VALIDATION ---");
    
    List<String> errors = [];
    List<String> warnings = [];
    Set<String> validNodeIds = {};
    Set<String> invalidNodeIds = {};

    List<CSVUserData> newUsers = [];
    List<CSVUserData> usersToUpdate = [];
    List<CSVUserData> authConflicts = [];
    List<UserDiff> diffs = [];

    // 1. ---------- LOAD NODES ----------
    final nodesPath = 'tenants/$tenantId/organizations/hierarchy/nodes';
    final nodesSnap = await db.collection(nodesPath).get();
    final existingNodeIds = nodesSnap.docs.map((doc) => doc.id).toSet();

    // 2. ---------- LOAD EXISTING USERS (FETCH ALL STRATEGY) ----------
    Map<String, Map<String, dynamic>> existingFirestoreUsers = {};
    final userPath = 'tenants/$tenantId/users';
    
    print("DEBUG: Fetching ALL users to normalize email case...");
    final allUsersSnap = await db.collection(userPath).get();

    for (var doc in allUsersSnap.docs) {
      final data = doc.data();
      dynamic emailRaw = data['profiledata'] != null 
          ? (data['profiledata'] as Map)['email'] 
          : null;

      if (emailRaw != null) {
        String emailKey = emailRaw.toString().trim().toLowerCase();
        existingFirestoreUsers[emailKey] = {'id': doc.id, ...data};
      }
    }
    
    // 3. ---------- PROCESS CSV ROWS ----------
    Set<String> processedEmails = {};

    for (int i = 0; i < users.length; i++) {
      final user = users[i];
      final rowNum = i + 2;
      final emailLower = user.email.trim().toLowerCase();

      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(user.email)) {
        errors.add('Row $rowNum: Invalid email - ${user.email}');
        continue;
      }

      if (processedEmails.contains(emailLower)) {
        warnings.add('Row $rowNum: Duplicate skipped - ${user.email}');
        continue;
      }
      processedEmails.add(emailLower);

      if (user.nodeId.isEmpty) errors.add('Row $rowNum: Node ID required');
      else if (existingNodeIds.contains(user.nodeId)) validNodeIds.add(user.nodeId);
      else {
        invalidNodeIds.add(user.nodeId);
        errors.add('Row $rowNum: Invalid Node ID "${user.nodeId}"');
      }

      if (errors.any((e) => e.startsWith('Row $rowNum'))) continue;

      // 4. ---------- COMPARE ----------
      if (existingFirestoreUsers.containsKey(emailLower)) {
        // UPDATE CASE
        final existing = existingFirestoreUsers[emailLower]!;
        Map<String, Map<String, dynamic>> fieldChanges = {};

        void checkChange(String field, dynamic newVal, dynamic oldVal) {
          if (newVal.toString() != oldVal.toString()) {
            fieldChanges[field] = {'old': oldVal, 'new': newVal};
          }
        }

        checkChange('fullName', user.fullName, existing['profiledata']?['fullName'] ?? '');
        checkChange('designation', user.designation, existing['designation'] ?? '');
        checkChange('employeeType', user.employeeType, existing['employeeType'] ?? ''); // New Field
        checkChange('nodeId', user.nodeId, existing['nodeId'] ?? '');
        checkChange('level', user.level, existing['level'] ?? 0);

        if (fieldChanges.isNotEmpty) {
          usersToUpdate.add(user);
          diffs.add(UserDiff(email: user.email, changes: fieldChanges));
        } else {
          warnings.add('${user.email} is up to date.');
        }
      } else {
        // NEW CASE
        try {
          final methods = await auth.fetchSignInMethodsForEmail(user.email);
          if (methods.isNotEmpty) {
            authConflicts.add(user);
            warnings.add('User ${user.email} exists in Auth but not DB.');
          } else {
            newUsers.add(user);
          }
        } catch (e) {
          newUsers.add(user); 
        }
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      validNodeIds: validNodeIds.toList(),
      invalidNodeIds: invalidNodeIds.toList(),
      newUsers: newUsers,
      usersToUpdate: usersToUpdate,
      authConflicts: authConflicts,
      diffs: diffs,
    );
  }

  /// IMPORT OR UPDATE USERS 
  /// FIXED: Now uses pre-fetched Map to ensure Case-Insensitive matching works
  Future<Map<String, dynamic>> importUsers(
    String tenantId,
    List<CSVUserData> users,
    Function(int current, int total, String message) progressCallback,
  ) async {
    int successCount = 0;
    int failureCount = 0;
    List<String> failedUsers = [];

    // ---------------------------------------------------------
    // STEP 1: PRE-FETCH EXISTING USERS TO MAP (THE FIX)
    // ---------------------------------------------------------
    // We must build the same map as validation to find the Doc IDs
    // regardless of whether the email is stored as "Sanjay" or "sanjay".
    Map<String, String> emailToDocIdMap = {};
    
    try {
      final userPath = 'tenants/$tenantId/users';
      final allUsersSnap = await db.collection(userPath).get();
      
      for (var doc in allUsersSnap.docs) {
        final data = doc.data();
        dynamic emailRaw = data['profiledata'] != null 
            ? (data['profiledata'] as Map)['email'] 
            : null;
        if (emailRaw != null) {
          // KEY = Lowercase Email, VALUE = Document ID
          emailToDocIdMap[emailRaw.toString().trim().toLowerCase()] = doc.id;
        }
      }
      print("DEBUG: Import Loop - Mapped ${emailToDocIdMap.length} existing users for lookup.");
    } catch (e) {
      print("DEBUG: Error mapping existing users: $e");
    }

    // ---------------------------------------------------------
    // STEP 2: PROCESS USERS
    // ---------------------------------------------------------
    for (int i = 0; i < users.length; i++) {
      final user = users[i];
      final emailLower = user.email.trim().toLowerCase();
      
      progressCallback(i + 1, users.length, 'Syncing ${user.email}...');

      if (i > 0 && i % 10 == 0) await Future.delayed(const Duration(milliseconds: RATE_LIMIT_DELAY_MS));

      try {
        // CHECK MAP INSTEAD OF QUERYING DB AGAIN
        if (emailToDocIdMap.containsKey(emailLower)) {
          // ============================================
          // UPDATE EXISTING USER
          // ============================================
          final docId = emailToDocIdMap[emailLower]!;
          
          print("DEBUG: Updating existing user $docId (${user.email})");
          
          await db.collection('tenants/$tenantId/users').doc(docId).update({
            'profiledata.fullName': user.fullName,
            'designation': user.designation,
            'employeeType': user.employeeType, // This will now correctly update
            'nodeId': user.nodeId,
            'level': user.level,
            // DO NOT update status or password here
          });
          
          successCount++;
        } else {
          // ============================================
          // CREATE NEW USER
          // ============================================
          print("DEBUG: Creating NEW user (${user.email})");
          
          UserCredential? credential;
          try {
            credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: user.email,
              password: user.password,
            );

            final userId = credential.user!.uid;
            await db.collection('tenants/$tenantId/users').doc(userId).set({
              'profiledata': {
                'email': user.email,
                'fullName': user.fullName,
              },
              'designation': user.designation,
              'employeeType': user.employeeType, // New Field
              'status': 'active',
              'createdat': FieldValue.serverTimestamp(),
              'nodeId': user.nodeId,
              'level': user.level,
              'importedFromCSV': true,
            });
            successCount++;

          } on FirebaseAuthException catch (e) {
            if (e.code == 'email-already-in-use') {
              failureCount++;
              failedUsers.add('${user.email}: Exists in Auth but missing in DB (Conflict)');
            } else {
              rethrow;
            }
          }
        }
      } catch (e) {
        failureCount++;
        failedUsers.add('${user.email}: $e');
        print("DEBUG: Error processing ${user.email}: $e");
      }
    }

    return {
      'success': successCount,
      'failed': failureCount,
      'failedUsers': failedUsers,
    };
  }

  /// Load users for a node from tenants/{tenantId}/users
  Future<List<Map<String, dynamic>>> loadUsersByNode(
    String tenantId,
    String nodeId,
  ) async {
    final snap = await db
        .collection('tenants/$tenantId/users')
        .where('nodeId', isEqualTo: nodeId)
        .orderBy('createdat', descending: true)
        .get();

    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Load hierarchy nodes with user counts from tenants/{tenantId}/users
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
      final nodeId = nodeDoc.id;
      final usersSnap = await db
          .collection('tenants/$tenantId/users')
          .where('nodeId', isEqualTo: nodeId)
          .count()
          .get();

      nodesWithCounts.add({
        'id': nodeId,
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