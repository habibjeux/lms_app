import '../../../core/models/base_model.dart';

class StudentAnswer extends BaseModel {
  final String questionId;
  final String quizAttemptId;
  final String? answerId;
  final List<String> selectedAnswerIds;
  final String? textAnswer;
  final double score;
  final bool isCorrect;

  StudentAnswer({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required super.active,
    required this.questionId,
    required this.quizAttemptId,
    this.answerId,
    required this.selectedAnswerIds,
    this.textAnswer,
    required this.score,
    required this.isCorrect,
  });

  factory StudentAnswer.fromJson(Map<String, dynamic> json) {
    // Gérer les deux formats possibles
    List<String> selectedAnswerIds = [];
    if (json['selectedAnswerIds'] != null) {
      selectedAnswerIds = List<String>.from(json['selectedAnswerIds']);
    } else if (json['answerId'] != null) {
      selectedAnswerIds = [json['answerId']];
    }

    return StudentAnswer(
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
      questionId: json['questionId'] ?? '',
      quizAttemptId: json['quizAttemptId'] ?? '',
      answerId: json['answerId'],
      selectedAnswerIds: selectedAnswerIds,
      textAnswer: json['textAnswer'],
      score: json['score'] is int
          ? (json['score'] as int).toDouble()
          : (json['score'] is String
              ? double.parse(json['score'])
              : (json['score'] ?? 0.0)),
      isCorrect: json['isCorrect'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();

    // Le backend attend 'answerId' (un seul ID) et non 'selectedAnswerIds'
    String? answerId;
    if (selectedAnswerIds.isNotEmpty) {
      // Pour les questions à choix unique, prendre le premier ID
      // Pour les questions à choix multiples, on devra envoyer plusieurs requêtes
      answerId = selectedAnswerIds.first;
    }

    return {
      ...baseJson,
      'questionId': questionId,
      'quizAttemptId': quizAttemptId,
      'answerId': answerId, // ✅ Format attendu par le backend
      'selectedAnswerIds':
          selectedAnswerIds, // ✅ Garder pour compatibilité locale
      'textAnswer': textAnswer,
      'score': score,
      'isCorrect': isCorrect,
    };
  }

  StudentAnswer copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? active,
    String? questionId,
    String? quizAttemptId,
    String? answerId,
    List<String>? selectedAnswerIds,
    String? textAnswer,
    double? score,
    bool? isCorrect,
  }) {
    return StudentAnswer(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      active: active ?? this.active,
      questionId: questionId ?? this.questionId,
      quizAttemptId: quizAttemptId ?? this.quizAttemptId,
      answerId: answerId ?? this.answerId,
      selectedAnswerIds: selectedAnswerIds ?? List.from(this.selectedAnswerIds),
      textAnswer: textAnswer ?? this.textAnswer,
      score: score ?? this.score,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  // Getters utiles
  bool get hasAnswer => selectedAnswerIds.isNotEmpty || textAnswer != null;

  String get displayAnswer {
    if (textAnswer != null && textAnswer!.isNotEmpty) {
      return textAnswer!;
    }
    return selectedAnswerIds.join(', ');
  }
}
