import 'package:cloud_firestore/cloud_firestore.dart';

class UserHelper {
  static Future<String> getUserDisplayName({
    required String tenantId,
    required String userId,
  }) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('tenants')
          .doc(tenantId)
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        
        // Get profiledata nested map
        final profile = data?['profiledata'] as Map<dynamic, dynamic>? ?? {};
        
        // Get fullName from profiledata
        final fullName = profile['fullName'] as String?;
        
        // Fallback to email if fullName not available
        final email = data?['email'] as String?;
        
        // Return fullName if available, otherwise email, otherwise UID
        return fullName ?? email ?? userId;
      }
      
      return userId; // Fallback to UID if user not found
    } catch (e) {
      return userId; // Return UID on error
    }
  }
  
  /// Get user initials for avatar
  static String getUserInitials(String name) {
    if (name.isEmpty) return 'U';
    
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
