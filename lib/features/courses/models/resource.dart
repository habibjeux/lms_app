import 'chapter.dart';
import 'module.dart';

class Resource {
  final String id;
  final String label;
  final String type;
  final String url;
  final bool visible;
  final String moduleId;
  final String? chapterId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  // Relations
  final Module? module;
  final Chapter? chapter;

  const Resource({
    required this.id,
    required this.label,
    required this.type,
    required this.url,
    required this.visible,
    required this.moduleId,
    this.chapterId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.module,
    this.chapter,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'],
      label: json['label'],
      type: json['type'],
      url: json['url'],
      visible: json['visible'],
      moduleId: json['moduleId'],
      chapterId: json['chapterId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'type': type,
        'url': url,
        'visible': visible,
        'moduleId': moduleId,
        'chapterId': chapterId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };
}
