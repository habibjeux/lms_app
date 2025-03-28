import '../../../core/models/base_model.dart';

class AssignmentSubmission extends BaseModel {
  final String assignmentId;
  final String studentId;
  final DateTime submissionDate;
  final List<String> files;
  final String? comment;
  final bool isLate;
  final AssignmentGrade? grade;

  AssignmentSubmission({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required super.active,
    required this.assignmentId,
    required this.studentId,
    required this.submissionDate,
    required this.files,
    this.comment,
    required this.isLate,
    this.grade,
  });

  factory AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmission(
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
      assignmentId: json['assignmentId'],
      studentId: json['studentId'],
      submissionDate: json['submissionDate'] != null
          ? DateTime.parse(json['submissionDate'])
          : DateTime.now(),
      files:
          json['files'] != null ? List<String>.from(json['files']) : const [],
      comment: json['comment'],
      isLate: json['isLate'] ?? false,
      grade: json['grade'] != null
          ? AssignmentGrade.fromJson(json['grade'])
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'assignmentId': assignmentId,
      'studentId': studentId,
      'submissionDate': submissionDate.toIso8601String(),
      'files': files,
      'comment': comment,
      'isLate': isLate,
      'grade': grade?.toJson(),
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'id': id,
    };
  }
}

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
