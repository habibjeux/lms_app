import 'enrollment.dart';
import 'teaching.dart';

class AcademicYear {
  final String id;
  final String year;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  final List<Enrollment>? enrollments;
  final List<Teaching>? teachings;

  const AcademicYear({
    required this.id,
    required this.year,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.enrollments,
    this.teachings,
  });

  factory AcademicYear.fromJson(Map<String, dynamic> json) {
    return AcademicYear(
      id: json['id'],
      year: json['year'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'year': year,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };
}
