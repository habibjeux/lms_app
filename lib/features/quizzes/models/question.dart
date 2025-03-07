import '../../../core/models/base_model.dart';
import 'answer.dart';
import 'enums/question_type.dart';

class Question extends BaseModel {
  final String text;
  final QuestionType type;
  final double points;
  final List<Answer> answers;
  final String quizId;

  Question({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required super.active,
    required this.text,
    required this.type,
    required this.points,
    required this.answers,
    required this.quizId,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      active: json['active'] ?? true,
      text: json['text'],
      type: QuestionType.values.firstWhere(
        (e) => e.toString() == 'QuestionType.${json['type']}',
        orElse: () => QuestionType.MCQ,
      ),
      points: json['points'] is String
          ? double.tryParse(json['points']) ?? 0.0
          : (json['points'] is int
              ? json['points'].toDouble()
              : (json['points'] ?? 0.0)),
      answers: _parseAnswers(json['answers']),
      quizId: json['quizId'] ?? '',
    );
  }

  static List<Answer> _parseAnswers(dynamic answersJson) {
    if (answersJson == null) return [];

    try {
      return (answersJson as List).map((answer) {
        return Answer.fromJson(answer);
      }).toList();
    } catch (e) {
      print("Erreur lors de la conversion des réponses: $e");
      return [];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'active': active,
      'text': text,
      'type': type.toString().split('.').last,
      'points': points,
      'answers': answers.map((answer) => answer.toJson()).toList(),
      'quizId': quizId,
    };
  }

  Question copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? active,
    String? text,
    QuestionType? type,
    double? points,
    List<Answer>? answers,
    String? quizId,
  }) {
    return Question(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      active: active ?? this.active,
      text: text ?? this.text,
      type: type ?? this.type,
      points: points ?? this.points,
      answers: answers ?? List.from(this.answers),
      quizId: quizId ?? this.quizId,
    );
  }

  bool get isMultipleChoice => type == QuestionType.MCQ;

  bool get isSingleChoice => type == QuestionType.SCQ;

  bool get isTrueFalse => type == QuestionType.TRUE_FALSE;

  bool get isShortAnswer => type == QuestionType.SHORT_ANSWER;

  List<Answer> get correctAnswers {
    return answers.where((answer) => answer.isCorrect).toList();
  }

  List<Answer> get incorrectAnswers {
    return answers.where((answer) => !answer.isCorrect).toList();
  }
}
