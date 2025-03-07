import '../../../core/models/base_model.dart';

class AssignmentGrade extends BaseModel {
  final String submissionId;
  final String teacherId;
  final double score;
  final String? feedback;
  final DateTime gradedAt;

  AssignmentGrade({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required super.active,
    required this.submissionId,
    required this.teacherId,
    required this.score,
    this.feedback,
    required this.gradedAt,
  });

  factory AssignmentGrade.fromJson(Map<String, dynamic> json) {
    return AssignmentGrade(
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
      submissionId: json['submissionId'],
      teacherId: json['teacherId'],
      score: json['score'] is int ? json['score'].toDouble() : json['score'],
      feedback: json['feedback'],
      gradedAt: json['gradedAt'] != null
          ? DateTime.parse(json['gradedAt'])
          : DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> baseJson = super.toJson();
    return {
      ...baseJson,
      'submissionId': submissionId,
      'teacherId': teacherId,
      'score': score,
      'feedback': feedback,
      'gradedAt': gradedAt.toIso8601String(),
    };
  }
}
