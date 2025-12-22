class CSVUserData {
  String email;
  String password;
  String fullName;
  String nodeId;
  int level;
  String designation; // New field

  CSVUserData({
    required this.email,
    required this.password,
    required this.fullName,
    required this.nodeId,
    required this.level,
    required this.designation, // New field
  });

  factory CSVUserData.fromCSVRow(List<String> row) {
    if (row.length < 6) { // Now requires 6 columns
      throw Exception('CSV row must have 6 columns: email, password, fullName, nodeId, level, designation');
    }
    return CSVUserData(
      email: row[0].trim(),
      password: row[1].trim(),
      fullName: row[2].trim(),
      nodeId: row[3].trim(),
      level: int.tryParse(row[4].trim()) ?? 0,
      designation: row[5].trim(), // New field
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
      'fullName': fullName,
      'nodeId': nodeId,
      'level': level,
      'designation': designation, // New field
    };
  }
}

class ValidationResult {
  bool isValid;
  List<String> errors;
  List<String> warnings;
  List<String> validNodeIds;
  List<String> invalidNodeIds;
  List<CSVUserData> usersToImport; // only unique + not in Firestore

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.validNodeIds,
    required this.invalidNodeIds,
    required this.usersToImport,
  });
}
