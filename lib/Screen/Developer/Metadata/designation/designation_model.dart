class DesignationMeta {
  String id;
  String name;
  int hierarchyLevel;
  List<String> reportsTo;
  List<String> permissions;
  List<String> screenAccess;
  bool requiresApproval;
  bool isRoot;

  DesignationMeta({
    required this.id,
    required this.name,
    required this.hierarchyLevel,
    required this.reportsTo,
    required this.permissions,
    required this.screenAccess,
    required this.requiresApproval,
    required this.isRoot,
  });

  factory DesignationMeta.fromMap(String id, Map<String, dynamic> map) {
    return DesignationMeta(
      id: id,
      name: map['name'] ?? '',
      hierarchyLevel: (map['hierarchy_level'] ?? 0) as int,
      reportsTo: List<String>.from(map['reports_to'] ?? const []),
      permissions: List<String>.from(map['permissions'] ?? const []),
      screenAccess: List<String>.from(map['screen_access'] ?? const []),
      requiresApproval: map['requires_approval'] ?? false,
      isRoot: map['is_root'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'hierarchy_level': hierarchyLevel,
      'reports_to': reportsTo,
      'permissions': permissions,
      'screen_access': screenAccess,
      'requires_approval': requiresApproval,
      'is_root': isRoot,
    };
  }
}
