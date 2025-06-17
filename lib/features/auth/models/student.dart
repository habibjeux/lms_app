import '../../modules/models/enrollment.dart';
import '../../quiz/models/quiz_attempt.dart';
import 'user.dart';

class Student {
  final String id;
  final String studentNumber;
  final String birthDate;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  final User? user;
  final List<Enrollment>? enrollments;
  final List<QuizAttempt>? quizAttempts;

  const Student({
    required this.id,
    required this.studentNumber,
    required this.birthDate,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.user,
    this.enrollments,
    this.quizAttempts,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      studentNumber: json['studentNumber'],
      birthDate: json['birthDate'],
      userId: json['userId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentNumber': studentNumber,
        'birthDate': birthDate,
        'userId': userId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };
}
