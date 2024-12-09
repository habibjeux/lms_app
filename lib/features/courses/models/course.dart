import '../../auth/models/school.dart';
import 'course_level.dart';
import 'module.dart';

class Course {
  final String id;
  final String code;
  final String title;
  final String description;
  final bool active;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  final School? school;
  final List<Module>? modules;
  final List<CourseLevel>? levels;

  const Course({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.active,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.school,
    this.modules,
    this.levels,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      code: json['code'],
      title: json['title'],
      description: json['description'],
      active: json['active'],
      schoolId: json['schoolId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      modules: json['modules'] != null
          ? List<Module>.from(json['modules'].map((x) => Module.fromJson(x)))
          : null,
      levels: json['levels'] != null
          ? List<CourseLevel>.from(
              json['levels'].map((x) => CourseLevel.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'title': title,
        'description': description,
        'active': active,
        'schoolId': schoolId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };
}
