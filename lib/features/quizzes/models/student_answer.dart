import 'answer.dart';
import 'question.dart';
import 'quiz_attempt.dart';

class StudentAnswer {
  final String id;
  final double score;
  final String quizAttemptId;
  final String questionId;
  final String? answerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  final QuizAttempt? quizAttempt;
  final Question? question;
  final Answer? answer;

  const StudentAnswer({
    required this.id,
    required this.score,
    required this.quizAttemptId,
    required this.questionId,
    this.answerId,
    required this.createdAt,
    required this.updatedAt,
    this.quizAttempt,
    this.question,
    this.answer,
  });

  factory StudentAnswer.fromJson(Map<String, dynamic> json) {
    return StudentAnswer(
      id: json['id'],
      score: json['score'].toDouble(),
      quizAttemptId: json['quizAttemptId'],
      questionId: json['questionId'],
      answerId: json['answerId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'score': score,
        'quizAttemptId': quizAttemptId,
        'questionId': questionId,
        'answerId': answerId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
