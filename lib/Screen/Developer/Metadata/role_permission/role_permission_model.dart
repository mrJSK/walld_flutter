class RolePermissionMeta {
  String roleId;
  List<String> permissions;
  String description;

  RolePermissionMeta({
    required this.roleId,
    required this.permissions,
    this.description = '',
  });

  factory RolePermissionMeta.fromMap(String id, Map<String, dynamic> map) {
    return RolePermissionMeta(
      roleId: id,
      permissions: List<String>.from(map['permissions'] ?? const []),
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'permissions': permissions,
        'description': description,
      };
}
