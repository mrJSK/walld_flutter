class OrgNodeMeta {
  String id;
  String name;
  String? parentId;
  String type;            // organization, department, team, etc.
  int level;              // depth in tree (0 = root)
  String? managerId;      // optional manager user id
  List<String> designationIds;
  bool isActive;

  OrgNodeMeta({
    required this.id,
    required this.name,
    required this.parentId,
    required this.type,
    required this.level,
    required this.managerId,
    required this.designationIds,
    required this.isActive,
  });

  factory OrgNodeMeta.fromMap(String id, Map<String, dynamic> map) {
    return OrgNodeMeta(
      id: id,
      name: map['name'] ?? id,
      parentId: map['parentId'],
      type: map['type'] ?? 'organization',
      level: (map['level'] ?? 0) as int,
      managerId: map['managerId'],
      designationIds: List<String>.from(map['designationIds'] ?? const []),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'parentId': parentId,
      'type': type,
      'level': level,
      'managerId': managerId,
      'designationIds': designationIds,
      'isActive': isActive,
    };
  }

  OrgNodeMeta copyWith({
    String? id,
    String? name,
    String? parentId,
    String? type,
    int? level,
    String? managerId,
    List<String>? designationIds,
    bool? isActive,
  }) {
    return OrgNodeMeta(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      type: type ?? this.type,
      level: level ?? this.level,
      managerId: managerId ?? this.managerId,
      designationIds: designationIds ?? this.designationIds,
      isActive: isActive ?? this.isActive,
    );
  }
}
