class TeachingUnit {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt; // Nullable
  final bool active;
  final String code;
  final String name;
  final int order;
  final String courseLevelId;
  final String semesterId;

  TeachingUnit({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.active,
    required this.code,
    required this.name,
    required this.order,
    required this.courseLevelId,
    required this.semesterId,
  });

  /// Factory pour créer une instance depuis un JSON
  factory TeachingUnit.fromJson(Map<String, dynamic> json) {
    return TeachingUnit(
        id: json['id'] ?? '',
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        deletedAt: json['deletedAt'] != null
            ? DateTime.parse(json['deletedAt'])
            : null,
        active: json['active'] ?? false,
        code: json['code'] ?? '',
        name: json['name'] ?? '',
        order: json['order'] ?? 0,
        courseLevelId: json['courseLevelId'] ?? '',
        semesterId: json['semesterId'] ?? '');
  }

  /// Convertir une instance en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'active': active,
      'code': code,
      'name': name,
      'order': order
    };
  }
}
