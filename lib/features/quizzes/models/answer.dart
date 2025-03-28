import '../../../core/models/base_model.dart';

class Answer extends BaseModel {
  final String text;
  final bool isCorrect;
  final double points;
  final String questionId;

  Answer({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required super.active,
    required this.text,
    required this.isCorrect,
    required this.points,
    required this.questionId,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
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
      isCorrect: json['isCorrect'] ?? false,
      points: json['points'] is String
          ? double.tryParse(json['points']) ?? 0.0
          : (json['points'] is int
              ? json['points'].toDouble()
              : (json['points'] ?? 0.0)),
      questionId: json['questionId'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'active': active,
      'text': text,
      'isCorrect': isCorrect,
      'points': points,
      'questionId': questionId,
    };
  }

  Answer copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? active,
    String? text,
    bool? isCorrect,
    double? points,
    String? questionId,
  }) {
    return Answer(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      active: active ?? this.active,
      text: text ?? this.text,
      isCorrect: isCorrect ?? this.isCorrect,
      points: points ?? this.points,
      questionId: questionId ?? this.questionId,
    );
  }
}
