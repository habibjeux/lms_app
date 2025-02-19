import '../../modules/models/teaching.dart';
import 'user.dart';

class Teacher {
  final String id;
  final String specialty;
  final String grade;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  final User? user;
  final List<Teaching>? teachings;

  const Teacher({
    required this.id,
    required this.specialty,
    required this.grade,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.user,
    this.teachings,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'],
      specialty: json['specialty'],
      grade: json['grade'],
      userId: json['userId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'specialty': specialty,
        'grade': grade,
        'userId': userId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };
}
