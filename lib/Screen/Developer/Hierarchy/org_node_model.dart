class OrgNodeMeta {
  String id;
  String name;
  String? parentId;
  int level; // depth in tree (0=root)
  List<String> designationIds; // allowed designations at this node
  bool isActive;

  OrgNodeMeta({
    required this.id,
    required this.name,
    required this.parentId,
    required this.level,
    required this.designationIds,
    required this.isActive,
  });

  factory OrgNodeMeta.fromMap(String id, Map<String, dynamic> map) {
    return OrgNodeMeta(
      id: id,
      name: map['name'] ?? id,
      parentId: map['parentId'],
      level: (map['level'] ?? 0) as int,
      designationIds: List<String>.from(map['designationIds'] ?? const []),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'parentId': parentId,
      'level': level,
      'designationIds': designationIds,
      'isActive': isActive,
    };
  }
}
