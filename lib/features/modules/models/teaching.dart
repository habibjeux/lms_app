import '../../auth/models/teacher.dart';
import 'academic_year.dart';
import 'course_level.dart';
import 'module.dart';

class Teaching {
  final String id;
  final String moduleId;
  final String courseLevelId;
  final String teacherId;
  final String academicYearId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  // Relations
  final Module? module;
  final CourseLevel? courseLevel;
  final Teacher? teacher;
  final AcademicYear? academicYear;
  final List<CourseSession>? courseSessions;

  const Teaching({
    required this.id,
    required this.moduleId,
    required this.courseLevelId,
    required this.teacherId,
    required this.academicYearId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.module,
    this.courseLevel,
    this.teacher,
    this.academicYear,
    this.courseSessions,
  });

  factory Teaching.fromJson(Map<String, dynamic> json) {
    return Teaching(
      id: json['id'],
      moduleId: json['moduleId'],
      courseLevelId: json['courseLevelId'],
      teacherId: json['teacherId'],
      academicYearId: json['academicYearId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'moduleId': moduleId,
        'courseLevelId': courseLevelId,
        'teacherId': teacherId,
        'academicYearId': academicYearId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };
}

class CourseSession {
  final String id;
  final String type;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final String teachingId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  // Relations
  final Teaching? teaching;

  const CourseSession({
    required this.id,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.teachingId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.teaching,
  });

  factory CourseSession.fromJson(Map<String, dynamic> json) {
    return CourseSession(
      id: json['id'],
      type: json['type'],
      status: json['status'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      teachingId: json['teachingId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'status': status,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'teachingId': teachingId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };
}
