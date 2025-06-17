import '../../../core/models/base_model.dart';

class Answer extends BaseModel {
  final String questionId;
  final String text;
  final bool isCorrect;
  final int order;
  final String? explanation;

  Answer({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required super.active,
    required this.questionId,
    required this.text,
    required this.isCorrect,
    required this.order,
    this.explanation,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
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
      questionId: json['questionId'] ?? json['quizId'] ?? '',
      text: json['text'] ?? '',
      isCorrect: json['isCorrect'] ?? json['correct'] ?? false,
      order: json['order'] ?? 0,
      explanation: json['explanation'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'questionId': questionId,
      'text': text,
      'isCorrect': isCorrect,
      'order': order,
      'explanation': explanation,
    };
  }

  Answer copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? active,
    String? questionId,
    String? text,
    bool? isCorrect,
    int? order,
    String? explanation,
  }) {
    return Answer(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      active: active ?? this.active,
      questionId: questionId ?? this.questionId,
      text: text ?? this.text,
      isCorrect: isCorrect ?? this.isCorrect,
      order: order ?? this.order,
      explanation: explanation ?? this.explanation,
    );
  }
}
