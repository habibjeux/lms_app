import '../../../core/models/base_model.dart';

class StudentAnswer extends BaseModel {
  final String questionId;
  final String? answerId;
  final String quizAttemptId;
  final double score;
  final bool isSynchronized;
  final String? textAnswer;

  StudentAnswer({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required super.active,
    required this.questionId,
    this.answerId,
    required this.quizAttemptId,
    required this.score,
    this.isSynchronized = false,
    this.textAnswer,
  });

  factory StudentAnswer.fromJson(Map<String, dynamic> json) {
    return StudentAnswer(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      active: json['active'] ?? true,
      questionId: json['questionId'],
      answerId: json['answerId'],
      quizAttemptId: json['quizAttemptId'],
      score: json['score'] is String
          ? double.tryParse(json['score']) ?? 0.0
          : (json['score'] is int
              ? json['score'].toDouble()
              : (json['score'] ?? 0.0)),
      isSynchronized: json['isSynchronized'] ?? false,
      textAnswer: json['textAnswer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'active': active,
      'questionId': questionId,
      'answerId': answerId,
      'quizAttemptId': quizAttemptId,
      'score': score,
      'isSynchronized': isSynchronized,
      'textAnswer': textAnswer,
    };
  }

  // Créer une nouvelle réponse d'étudiant
  factory StudentAnswer.create({
    required String questionId,
    String? answerId,
    required String quizAttemptId,
    String? textAnswer,
    double score = 0,
  }) {
    final now = DateTime.now();
    return StudentAnswer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: now,
      updatedAt: now,
      active: true,
      questionId: questionId,
      answerId: answerId,
      quizAttemptId: quizAttemptId,
      score: score,
      isSynchronized: false,
      textAnswer: textAnswer,
    );
  }

  StudentAnswer copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? active,
    String? questionId,
    String? answerId,
    String? quizAttemptId,
    double? score,
    bool? isSynchronized,
    String? textAnswer,
  }) {
    return StudentAnswer(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      active: active ?? this.active,
      questionId: questionId ?? this.questionId,
      answerId: answerId ?? this.answerId,
      quizAttemptId: quizAttemptId ?? this.quizAttemptId,
      score: score ?? this.score,
      isSynchronized: isSynchronized ?? this.isSynchronized,
      textAnswer: textAnswer ?? this.textAnswer,
    );
  }
}
