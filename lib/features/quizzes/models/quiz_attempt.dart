import '../../auth/models/student.dart';
import 'quiz.dart';
import 'student_answer.dart';

class QuizAttempt {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final int timeSpent; // en secondes
  final double score;
  final QuizAttemptStatus status;
  final String studentId;
  final String quizId;
  final DateTime createdAt;
  final DateTime updatedAt;

  final Student? student;
  final Quiz? quiz;
  final List<StudentAnswer>? studentAnswers;

  const QuizAttempt({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.timeSpent,
    required this.score,
    required this.status,
    required this.studentId,
    required this.quizId,
    required this.createdAt,
    required this.updatedAt,
    this.student,
    this.quiz,
    this.studentAnswers,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      timeSpent: json['timeSpent'],
      score: json['score'].toDouble(),
      status: json['status'],
      studentId: json['studentId'],
      quizId: json['quizId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'timeSpent': timeSpent,
        'score': score,
        'status': status,
        'studentId': studentId,
        'quizId': quizId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

enum QuizAttemptStatus { inProgress, completed, abandoned }
