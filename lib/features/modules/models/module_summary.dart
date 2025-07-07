import 'package:json_annotation/json_annotation.dart';
import 'package:lms_app/core/models/base_model.dart';

part 'module_summary.g.dart';

@JsonSerializable()
class ModuleSummary extends BaseModel {
  final String moduleId;
  final String moduleTitle;
  final String? moduleDescription;
  final CourseInfo course;
  final int chaptersCount;
  final int summariesCount;
  final List<ChapterSummary> chapters;
  final DateTime generatedAt;

  ModuleSummary({
    required this.moduleId,
    required this.moduleTitle,
    this.moduleDescription,
    required this.course,
    required this.chaptersCount,
    required this.summariesCount,
    required this.chapters,
    required this.generatedAt,
  }) : super(
          id: moduleId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          active: true,
        );

  factory ModuleSummary.fromJson(Map<String, dynamic> json) =>
      _$ModuleSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$ModuleSummaryToJson(this);
}

@JsonSerializable()
class CourseInfo {
  final String title;
  final String level;

  CourseInfo({
    required this.title,
    required this.level,
  });

  factory CourseInfo.fromJson(Map<String, dynamic> json) =>
      _$CourseInfoFromJson(json);
  Map<String, dynamic> toJson() => _$CourseInfoToJson(this);
}

@JsonSerializable()
class ChapterSummary {
  final String id;
  final String title;
  final int order;
  final String summary;

  ChapterSummary({
    required this.id,
    required this.title,
    required this.order,
    required this.summary,
  });

  factory ChapterSummary.fromJson(Map<String, dynamic> json) =>
      _$ChapterSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$ChapterSummaryToJson(this);
}
