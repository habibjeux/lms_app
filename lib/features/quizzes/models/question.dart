import 'answer.dart';
import 'quiz.dart';
import 'student_answer.dart';

class Question {
  final String id;
  final QuestionType type;
  final String text;
  final int points;
  final String quizId;
  final DateTime createdAt;
  final DateTime updatedAt;

  final Quiz? quiz;
  final List<Answer>? answers;
  final List<StudentAnswer>? studentAnswers;

  const Question({
    required this.id,
    required this.type,
    required this.text,
    required this.points,
    required this.quizId,
    required this.createdAt,
    required this.updatedAt,
    this.quiz,
    this.answers,
    this.studentAnswers,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      type: json['type'],
      text: json['text'],
      points: json['points'],
      quizId: json['quizId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'text': text,
        'points': points,
        'quizId': quizId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

enum QuestionType { multipleChoice, trueFalse, essay, shortAnswer }
