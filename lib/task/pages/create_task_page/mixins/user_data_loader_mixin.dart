import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

mixin UserDataLoaderMixin<T extends StatefulWidget> on State<T> {
  int? _currentUserLevel;
  String? _currentUserNodeId;

  int? get currentUserLevel => _currentUserLevel;
  String? get currentUserNodeId => _currentUserNodeId;

  Future<void> loadCurrentUserData(String tenantId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('tenants')
          .doc(tenantId)
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final data = userDoc.data();
      if (data == null) return;

      if (mounted) {
        setState(() {
          _currentUserLevel = data['level'] as int?;
          _currentUserNodeId = data['nodeId'] as String?;
        });
      }

      debugPrint(
          'Loaded current user: level=$_currentUserLevel, nodeId=$_currentUserNodeId');
    } catch (e) {
      debugPrint('Error loading current user data: $e');
    }
  }
}
