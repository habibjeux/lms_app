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
    try {
      return AssignmentSubmission(
        id: json['id']?.toString() ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now(),
        deletedAt: json['deletedAt'] != null
            ? DateTime.parse(json['deletedAt'])
            : null,
        active: json['active'] ?? true,
        assignmentId: json['assignmentId']?.toString() ?? '',
        studentId: json['studentId']?.toString() ?? '',
        submissionDate: json['submissionDate'] != null
            ? DateTime.parse(json['submissionDate'])
            : DateTime.now(),
        files:
            json['files'] != null ? List<String>.from(json['files']) : const [],
        comment: json['comment']?.toString(),
        isLate: json['isLate'] ?? false,
        grade: json['grade'] != null
            ? AssignmentGrade.fromJson(json['grade'])
            : null,
      );
    } catch (e) {
      print("Erreur lors de la conversion de la soumission: $e");
      print("JSON reçu: $json");
      rethrow;
    }
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
    try {
      return AssignmentGrade(
        id: json['id']?.toString() ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now(),
        deletedAt: json['deletedAt'] != null
            ? DateTime.parse(json['deletedAt'])
            : null,
        active: json['active'] ?? true,
        submissionId: json['submissionId']?.toString() ?? '',
        teacherId: json['teacherId']?.toString() ?? '',
        score: _parseScore(json['score']),
        feedback: json['feedback']?.toString(),
        gradedAt: json['gradingDate'] != null
            ? DateTime.parse(json['gradingDate'])
            : (json['gradedDate'] != null
                ? DateTime.parse(json['gradedDate'])
                : DateTime.now()),
      );
    } catch (e) {
      print("Erreur lors de la conversion de la note: $e");
      print("JSON reçu: $json");
      rethrow;
    }
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

  static double _parseScore(dynamic score) {
    if (score == null) return 0.0;
    if (score is double) return score;
    if (score is int) return score.toDouble();
    if (score is String) {
      return double.tryParse(score) ?? 0.0;
    }
    return 0.0;
  }
}
