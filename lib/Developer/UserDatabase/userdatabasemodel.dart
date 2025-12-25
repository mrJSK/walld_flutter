// lib/Screen/Developer/UserDatabase/userdatabasemodel.dart

class CSVUserData {
  String email;
  String password;
  String fullName;
  String nodeId;
  int level;
  String designation;
  String employeeType; // New 7th Column

  CSVUserData({
    required this.email,
    required this.password,
    required this.fullName,
    required this.nodeId,
    required this.level,
    required this.designation,
    required this.employeeType,
  });

  factory CSVUserData.fromCSVRow(List<String> row) {
    // Now requires 7 columns
    if (row.length < 7) {
      throw Exception('CSV row must have 7 columns: email, password, fullName, nodeId, level, designation, employeeType');
    }
    return CSVUserData(
      email: row[0].trim(),
      password: row[1].trim(),
      fullName: row[2].trim(),
      nodeId: row[3].trim(),
      level: int.tryParse(row[4].trim()) ?? 0,
      designation: row[5].trim(),
      employeeType: row[6].trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
      'fullName': fullName,
      'nodeId': nodeId,
      'level': level,
      'designation': designation,
      'employeeType': employeeType,
    };
  }
}

/// Helper class to store Old vs New values for UI display
class UserDiff {
  final String email;
  final Map<String, Map<String, dynamic>> changes; // Key: fieldName, Value: {'old': ..., 'new': ...}

  UserDiff({required this.email, required this.changes});
}

class ValidationResult {
  bool isValid;
  List<String> errors;
  List<String> warnings;
  List<String> validNodeIds;
  List<String> invalidNodeIds;
  
  // Lists for processing
  List<CSVUserData> newUsers;
  List<CSVUserData> usersToUpdate;
  List<CSVUserData> authConflicts;
  List<UserDiff> diffs; // Specific changes for the UI

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.validNodeIds,
    required this.invalidNodeIds,
    required this.newUsers,
    required this.usersToUpdate,
    required this.diffs,
    required this.authConflicts
  });
}