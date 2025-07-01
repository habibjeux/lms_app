import '../../../core/models/base_model.dart';
import 'student_answer.dart';

class QuizAttempt extends BaseModel {
  final String quizId;
  final String studentId;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final double score;
  final int timeSpent;
  final bool isSubmitted;
  final bool isSynchronized;
  final List<StudentAnswer> studentAnswers;

  QuizAttempt({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required super.active,
    required this.quizId,
    required this.studentId,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.score,
    required this.timeSpent,
    required this.isSubmitted,
    required this.isSynchronized,
    required this.studentAnswers,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    List<StudentAnswer> answers = [];
    if (json['studentAnswers'] != null) {
      answers = (json['studentAnswers'] as List)
          .map((answer) => StudentAnswer.fromJson(answer))
          .toList();
    }

    return QuizAttempt(
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
      studentId: json['studentId'] ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      status: json['status'] ?? 'pending',
      score: json['score'] is int
          ? (json['score'] as int).toDouble()
          : (json['score'] is String
              ? double.parse(json['score'])
              : (json['score'] ?? 0.0)),
      timeSpent: json['timeSpent'] is int ? json['timeSpent'] : 0,
      isSubmitted: json['isSubmitted'] ?? false,
      isSynchronized: json['isSynchronized'] ?? false,
      studentAnswers: answers,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'quizId': quizId,
      'studentId': studentId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status,
      'score': score,
      'timeSpent': timeSpent,
      'isSubmitted': isSubmitted,
      'isSynchronized': isSynchronized,
      'studentAnswers':
          studentAnswers.map((answer) => answer.toJson()).toList(),
    };
  }

  // Getters utiles
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';

  String get scoreText {
    if (score == score.roundToDouble()) {
      return score.round().toString();
    } else {
      return score.toStringAsFixed(1);
    }
  }

  String get timeSpentText {
    final minutes = timeSpent ~/ 60;
    final seconds = timeSpent % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
