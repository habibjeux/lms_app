import '../../auth/models/student.dart';
import 'academic_year.dart';
import 'course_level.dart';

class Enrollment {
  final String id;
  final String studentId;
  final String courseLevelId;
  final String academicYearId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  final Student? student;
  final CourseLevel? courseLevel;
  final AcademicYear? academicYear;

  const Enrollment({
    required this.id,
    required this.studentId,
    required this.courseLevelId,
    required this.academicYearId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.student,
    this.courseLevel,
    this.academicYear,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: json['id'],
      studentId: json['studentId'],
      courseLevelId: json['courseLevelId'],
      academicYearId: json['academicYearId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'courseLevelId': courseLevelId,
        'academicYearId': academicYearId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };
}
