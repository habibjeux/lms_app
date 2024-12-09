import 'question.dart';
import 'student_answer.dart';

class Answer {
  final String id;
  final String text;
  final bool isCorrect;
  final int points;
  final String questionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  final Question? question;
  final List<StudentAnswer>? studentAnswers;

  const Answer({
    required this.id,
    required this.text,
    required this.isCorrect,
    required this.points,
    required this.questionId,
    required this.createdAt,
    required this.updatedAt,
    this.question,
    this.studentAnswers,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'],
      text: json['text'],
      isCorrect: json['isCorrect'],
      points: json['points'],
      questionId: json['questionId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isCorrect': isCorrect,
        'points': points,
        'questionId': questionId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
