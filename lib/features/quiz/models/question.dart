import '../../../core/models/base_model.dart';
import 'answer.dart';
import 'question_type.dart';

class Question extends BaseModel {
  final String quizId;
  final String text;
  final QuestionType type;
  final String originalType;
  final double points;
  final int order;
  final bool required;
  final List<Answer> answers;
  final String? explanation;
  final String? imageUrl;

  Question({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required super.active,
    required this.quizId,
    required this.text,
    required this.type,
    required this.originalType,
    required this.points,
    required this.order,
    required this.required,
    required this.answers,
    this.explanation,
    this.imageUrl,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    List<Answer> answers = [];
    if (json['answers'] != null) {
      answers = (json['answers'] as List)
          .map((answer) => Answer.fromJson(answer))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    }

    // Conversion sécurisée des points
    double points = 1.0;
    if (json['points'] != null) {
      if (json['points'] is String) {
        points = double.parse(json['points']);
      } else if (json['points'] is int) {
        points = (json['points'] as int).toDouble();
      } else if (json['points'] is double) {
        points = json['points'];
      }
    }

    // Stocker le type original de l'API AVANT toute conversion
    String originalType = json['type'] ?? 'SCQ';

    // Mapper les types de l'API vers nos types internes
    QuestionType mappedType;
    switch (originalType) {
      case 'SCQ':
        mappedType = QuestionType.MULTIPLE_CHOICE;
        break;
      case 'MCQ':
        mappedType = QuestionType.MULTIPLE_CHOICE;
        break;
      case 'TRUE_FALSE':
        mappedType = QuestionType.TRUE_FALSE;
        break;
      case 'MATCHING':
        mappedType = QuestionType.MATCHING;
        break;
      case 'SHORT_ANSWER':
        mappedType = QuestionType.SHORT_ANSWER;
        break;
      case 'ESSAY':
        mappedType = QuestionType.ESSAY;
        break;
      default:
        mappedType = QuestionType.MULTIPLE_CHOICE;
    }

    return Question(
      id: json['id'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      active: json['active'] ?? true,
      quizId: json['quizId'] ?? '',
      text: json['text'] ?? '',
      type: mappedType,
      originalType: originalType,
      points: points,
      order: json['order'] ?? 0,
      required: json['required'] ?? true,
      answers: answers,
      explanation: json['explanation'],
      imageUrl: json['imageUrl'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'quizId': quizId,
      'text': text,
      'type': originalType,
      'points': points,
      'order': order,
      'required': required,
      'answers': answers.map((answer) => answer.toJson()).toList(),
      'explanation': explanation,
      'imageUrl': imageUrl,
    };
  }

  Question copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? active,
    String? quizId,
    String? text,
    QuestionType? type,
    String? originalType,
    double? points,
    int? order,
    bool? required,
    List<Answer>? answers,
    String? explanation,
    String? imageUrl,
  }) {
    return Question(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      active: active ?? this.active,
      quizId: quizId ?? this.quizId,
      text: text ?? this.text,
      type: type ?? this.type,
      originalType: originalType ?? this.originalType,
      points: points ?? this.points,
      order: order ?? this.order,
      required: required ?? this.required,
      answers: answers ?? List.from(this.answers),
      explanation: explanation ?? this.explanation,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // Getters utiles
  List<Answer> get correctAnswers {
    return answers.where((answer) => answer.isCorrect).toList();
  }

  bool get isMultipleChoice => type == QuestionType.MULTIPLE_CHOICE;
  bool get isTrueFalse => type == QuestionType.TRUE_FALSE;
  bool get isShortAnswer => type == QuestionType.SHORT_ANSWER;
  bool get isEssay => type == QuestionType.ESSAY;
  bool get isMatching => type == QuestionType.MATCHING;
  bool get isFillBlank => type == QuestionType.FILL_BLANK;

  // Nouveaux getters basés sur le type original de l'API
  bool get isSCQ => originalType == 'SCQ';
  bool get isMCQ => originalType == 'MCQ' || originalType == 'MULTIPLE_CHOICE';

  bool get allowsMultipleAnswers {
    // Basé sur le type original de l'API
    return originalType == 'MCQ' ||
        originalType == 'MULTIPLE_CHOICE' ||
        originalType == 'MATCHING';
  }

  bool get requiresTextInput {
    return originalType == 'SHORT_ANSWER' || type == QuestionType.ESSAY;
  }
}
