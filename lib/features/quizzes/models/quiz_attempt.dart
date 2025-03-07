// lib/features/quizzes/models/quiz_attempt.dart
import '../../../core/models/base_model.dart';
import 'quiz.dart';
import 'student_answer.dart';

class QuizAttempt extends BaseModel {
  final String quizId;
  final DateTime startDate;
  final DateTime? endDate;
  final int timeSpent; // en secondes
  final double score;
  final String status; // 'in_progress', 'completed', 'expired'
  final List<StudentAnswer> studentAnswers;
  final bool isSubmitted;
  final bool isSynchronized;

  QuizAttempt({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required super.active,
    required this.quizId,
    required this.startDate,
    this.endDate,
    required this.timeSpent,
    required this.score,
    required this.status,
    required this.studentAnswers,
    this.isSubmitted = false,
    this.isSynchronized = false,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    List<StudentAnswer> studentAnswers = [];

    if (json['studentAnswers'] != null) {
      studentAnswers = (json['studentAnswers'] as List)
          .map((answer) => StudentAnswer.fromJson(answer))
          .toList();
    }

    return QuizAttempt(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      active: json['active'] ?? true,
      quizId: json['quizId'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      timeSpent: json['timeSpent'] ?? 0,
      score: (json['score'] is int)
          ? json['score'].toDouble()
          : (json['score'] ?? 0.0),
      status: json['status'] ?? 'in_progress',
      studentAnswers: studentAnswers,
      isSubmitted: json['isSubmitted'] ?? false,
      isSynchronized: json['isSynchronized'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'active': active,
      'quizId': quizId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'timeSpent': timeSpent,
      'score': score,
      'status': status,
      'studentAnswers':
          studentAnswers.map((answer) => answer.toJson()).toList(),
      'isSubmitted': isSubmitted,
      'isSynchronized': isSynchronized,
    };
  }

  // Créer une nouvelle tentative pour un quiz
  factory QuizAttempt.create(Quiz quiz) {
    final now = DateTime.now();
    return QuizAttempt(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: now,
      updatedAt: now,
      active: true,
      quizId: quiz.id,
      startDate: now,
      timeSpent: 0,
      score: 0,
      status: 'in_progress',
      studentAnswers: [],
      isSubmitted: false,
      isSynchronized: false,
    );
  }

  QuizAttempt copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? active,
    String? quizId,
    DateTime? startDate,
    DateTime? endDate,
    int? timeSpent,
    double? score,
    String? status,
    List<StudentAnswer>? studentAnswers,
    bool? isSubmitted,
    bool? isSynchronized,
  }) {
    return QuizAttempt(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      active: active ?? this.active,
      quizId: quizId ?? this.quizId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      timeSpent: timeSpent ?? this.timeSpent,
      score: score ?? this.score,
      status: status ?? this.status,
      studentAnswers: studentAnswers ?? List.from(this.studentAnswers),
      isSubmitted: isSubmitted ?? this.isSubmitted,
      isSynchronized: isSynchronized ?? this.isSynchronized,
    );
  }

  // Vérifier si la tentative est en cours
  bool get isInProgress => status == 'in_progress';

  // Vérifier si la tentative est terminée
  bool get isCompleted => status == 'completed';

  // Vérifier si la tentative a expiré
  bool get isExpired => status == 'expired';

  // Obtenir la durée de la tentative
  Duration get duration {
    if (endDate != null) {
      return endDate!.difference(startDate);
    } else {
      return Duration(seconds: timeSpent);
    }
  }

  // Vérifier si la tentative peut être soumise
  bool get canSubmit {
    return isInProgress && studentAnswers.isNotEmpty;
  }

  // Vérifier si la tentative a des réponses non synchronisées
  bool get hasUnsynchronizedAnswers {
    return studentAnswers.any((answer) => !answer.isSynchronized);
  }

  // Format de score pour affichage
  String get scoreText {
    return '${score.toStringAsFixed(1)} pts';
  }

  // Durée formatée pour affichage
  String get durationText {
    final duration = this.duration;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes > 0) {
      return '$minutes min ${seconds} sec';
    } else {
      return '$seconds secondes';
    }
  }
}
