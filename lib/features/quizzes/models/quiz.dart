import '../../courses/models/module.dart';
import 'question.dart';
import 'quiz_attempt.dart';

class Quiz {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final int duration;
  final int maxAttempts;
  final bool visible;
  final double passingScore;
  final double maxScore;
  final String moduleId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  final Module? module;
  final List<Question>? questions;
  final List<QuizAttempt>? attempts;

  const Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.duration,
    required this.maxAttempts,
    required this.visible,
    required this.passingScore,
    required this.maxScore,
    required this.moduleId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.module,
    this.questions,
    this.attempts,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      duration: json['duration'],
      maxAttempts: json['maxAttempts'],
      visible: json['visible'],
      passingScore: json['passingScore'].toDouble(),
      maxScore: json['maxScore'].toDouble(),
      moduleId: json['moduleId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'duration': duration,
        'maxAttempts': maxAttempts,
        'visible': visible,
        'passingScore': passingScore,
        'maxScore': maxScore,
        'moduleId': moduleId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };
}
