import 'assignment_attachment.dart';
import 'enums/activity_type.dart';
import 'enums/activity_scope.dart';
import 'activity.dart';

class Assignment extends Activity {
  final String instructions;
  final double maxScore;
  final bool allowLateSubmission;
  final int? maxLateDays;
  final double? lateSubmissionPenalty;
  final List<String> acceptedFileTypes;
  final int maxFileSize;
  final List<AssignmentAttachment> attachments;

  Assignment({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required super.active,
    required super.title,
    super.visible = true,
    required super.order,
    required super.scope,
    super.startDate,
    super.endDate,
    required super.moduleId,
    super.chapterId,
    required this.instructions,
    required this.maxScore,
    required this.allowLateSubmission,
    this.maxLateDays,
    this.lateSubmissionPenalty,
    required this.acceptedFileTypes,
    required this.maxFileSize,
    this.attachments = const [],
  }) : super(type: ActivityType.ASSIGNMENT);

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      active: json['active'] ?? true,
      title: json['title'],
      visible: json['visible'] ?? true,
      order: json['order'] ?? 0,
      scope: json['scope'] != null
          ? ActivityScope.values.firstWhere(
              (e) => e.toString() == 'ActivityScope.${json['scope']}',
              orElse: () => ActivityScope.MODULE,
            )
          : ActivityScope.MODULE,
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      moduleId: json['moduleId'],
      chapterId: json['chapterId'],
      instructions: json['instructions'] ?? '',
      maxScore: json['maxScore'] is int
          ? json['maxScore'].toDouble()
          : (json['maxScore'] ?? 0.0),
      allowLateSubmission: json['allowLateSubmission'] ?? false,
      maxLateDays: json['maxLateDays'],
      lateSubmissionPenalty: json['lateSubmissionPenalty'] != null
          ? (json['lateSubmissionPenalty'] is int
              ? json['lateSubmissionPenalty'].toDouble()
              : json['lateSubmissionPenalty'])
          : null,
      acceptedFileTypes: json['acceptedFileTypes'] != null
          ? List<String>.from(json['acceptedFileTypes'])
          : const [],
      maxFileSize: json['maxFileSize'] ?? 10485760, // 10MB par défaut
      attachments: json['attachments'] != null
          ? List<AssignmentAttachment>.from(
              json['attachments'].map((x) => AssignmentAttachment.fromJson(x)))
          : const [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> baseJson = super.toJson();
    return {
      ...baseJson,
      'instructions': instructions,
      'maxScore': maxScore,
      'allowLateSubmission': allowLateSubmission,
      'maxLateDays': maxLateDays,
      'lateSubmissionPenalty': lateSubmissionPenalty,
      'acceptedFileTypes': acceptedFileTypes,
      'maxFileSize': maxFileSize,
      'attachments': attachments.map((x) => x.toJson()).toList(),
    };
  }
}
