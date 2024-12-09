import 'module.dart';
import 'resource.dart';

class Chapter {
  final String id;
  final String title;
  final int order;
  final String description;
  final bool visible;
  final String moduleId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  // Relations
  final Module? module;
  final List<Resource>? resources;

  const Chapter({
    required this.id,
    required this.title,
    required this.order,
    required this.description,
    required this.visible,
    required this.moduleId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.module,
    this.resources,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'],
      title: json['title'],
      order: json['order'],
      description: json['description'],
      visible: json['visible'],
      moduleId: json['moduleId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'order': order,
        'description': description,
        'visible': visible,
        'moduleId': moduleId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };
}
