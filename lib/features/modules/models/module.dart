import 'chapter.dart';

class Module {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool active;
  final String code;
  final String title;
  final int coefficient;
  final int credits;
  final String description;
  final int order;
  final String teachingUnitId;
  final List<Chapter> chapters;

  Module({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.active,
    required this.code,
    required this.title,
    required this.coefficient,
    required this.credits,
    required this.description,
    required this.order,
    required this.teachingUnitId,
    this.chapters = const [],
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    List<Chapter> chaptersList = [];
    if (json['chapters'] != null) {
      chaptersList = (json['chapters'] as List)
          .map((chapterJson) => Chapter.fromJson(chapterJson))
          .toList();
    }

    return Module(
      id: json['id'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      active: json['active'] ?? false,
      code: json['code'] ?? '',
      title: json['title'] ?? '',
      coefficient: json['coefficient'] ?? 0,
      credits: json['credits'] ?? 0,
      description: json['description'] ?? '',
      order: json['order'] ?? 0,
      teachingUnitId: json['teachingUnitId'] ?? '',
      chapters: chaptersList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'active': active,
      'code': code,
      'title': title,
      'coefficient': coefficient,
      'credits': credits,
      'description': description,
      'order': order,
      'teachingUnitId': teachingUnitId,
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
    };
  }

  Module copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? active,
    String? code,
    String? title,
    int? coefficient,
    int? credits,
    String? description,
    int? order,
    String? teachingUnitId,
    List<Chapter>? chapters,
  }) {
    return Module(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      active: active ?? this.active,
      code: code ?? this.code,
      title: title ?? this.title,
      coefficient: coefficient ?? this.coefficient,
      credits: credits ?? this.credits,
      description: description ?? this.description,
      order: order ?? this.order,
      teachingUnitId: teachingUnitId ?? this.teachingUnitId,
      chapters: chapters ?? this.chapters,
    );
  }
}
