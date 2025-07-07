// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'module_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModuleSummary _$ModuleSummaryFromJson(Map<String, dynamic> json) =>
    ModuleSummary(
      moduleId: json['moduleId'] as String,
      moduleTitle: json['moduleTitle'] as String,
      moduleDescription: json['moduleDescription'] as String?,
      course: CourseInfo.fromJson(json['course'] as Map<String, dynamic>),
      chaptersCount: (json['chaptersCount'] as num).toInt(),
      summariesCount: (json['summariesCount'] as num).toInt(),
      chapters: (json['chapters'] as List<dynamic>)
          .map((e) => ChapterSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );

Map<String, dynamic> _$ModuleSummaryToJson(ModuleSummary instance) =>
    <String, dynamic>{
      'moduleId': instance.moduleId,
      'moduleTitle': instance.moduleTitle,
      'moduleDescription': instance.moduleDescription,
      'course': instance.course,
      'chaptersCount': instance.chaptersCount,
      'summariesCount': instance.summariesCount,
      'chapters': instance.chapters,
      'generatedAt': instance.generatedAt.toIso8601String(),
    };

CourseInfo _$CourseInfoFromJson(Map<String, dynamic> json) => CourseInfo(
      title: json['title'] as String,
      level: json['level'] as String,
    );

Map<String, dynamic> _$CourseInfoToJson(CourseInfo instance) =>
    <String, dynamic>{
      'title': instance.title,
      'level': instance.level,
    };

ChapterSummary _$ChapterSummaryFromJson(Map<String, dynamic> json) =>
    ChapterSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      order: (json['order'] as num).toInt(),
      summary: json['summary'] as String,
    );

Map<String, dynamic> _$ChapterSummaryToJson(ChapterSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'order': instance.order,
      'summary': instance.summary,
    };
