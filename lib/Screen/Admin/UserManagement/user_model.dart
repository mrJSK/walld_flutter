import 'package:cloud_firestore/cloud_firestore.dart';

class UserMeta {
  String id;
  String email;
  String fullName;
  String designation;
  String? department;
  String status; // pending_approval, active, inactive, suspended
  DateTime createdAt;

  UserMeta({
    required this.id,
    required this.email,
    required this.fullName,
    required this.designation,
    this.department,
    required this.status,
    required this.createdAt,
  });

  factory UserMeta.fromMap(String id, Map<String, dynamic> map) {
    final profile = map['profiledata'] as Map<String, dynamic>? ?? {};
    return UserMeta(
      id: id,
      email: profile['email'] ?? '',
      fullName: profile['fullName'] ?? 'Unknown',
      designation: map['designation'] ?? 'employee',
      department: map['department'],
      status: map['status'] ?? 'pending_approval',
      createdAt: (map['createdat'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
