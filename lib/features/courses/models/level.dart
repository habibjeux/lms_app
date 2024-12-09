import 'course.dart';
import 'enrollment.dart';
import 'teaching.dart';

class Level {
  final String id;
  final String title;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  final List<CourseLevel>? courses;

  const Level({
    required this.id,
    required this.title,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.courses,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'],
      title: json['title'],
      active: json['active'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'active': active,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };
}

class CourseLevel {
  final String id;
  final String courseId;
  final String levelId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  // Relations
  final Course? course;
  final Level? level;
  final List<Enrollment>? enrollments;
  final List<Teaching>? teachings;

  const CourseLevel({
    required this.id,
    required this.courseId,
    required this.levelId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.course,
    this.level,
    this.enrollments,
    this.teachings,
  });

  factory CourseLevel.fromJson(Map<String, dynamic> json) {
    return CourseLevel(
      id: json['id'],
      courseId: json['courseId'],
      levelId: json['levelId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'levelId': levelId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };
}
