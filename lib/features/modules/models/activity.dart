import '../../../core/models/base_model.dart';
import '../../forum/models/forum.dart';
import '../../quizzes/models/quiz.dart';
import 'enums/activity_scope.dart';
import 'enums/activity_type.dart';
import 'resource.dart';

class Activity extends BaseModel {
  final String title;
  final ActivityType type;
  final bool visible;
  final int order;
  final ActivityScope scope;
  final DateTime? startDate;
  final DateTime? endDate;
  final String moduleId;
  final String? chapterId;

  Activity({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required super.active,
    required this.title,
    required this.type,
    required this.visible,
    required this.order,
    required this.scope,
    this.startDate,
    this.endDate,
    required this.moduleId,
    this.chapterId,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    ActivityType activityType = ActivityType.values.firstWhere(
      (e) => e.toString() == 'ActivityType.${json['type']}',
    );

    switch (activityType) {
      case ActivityType.RESOURCE:
        return Resource.fromJson(json);
      case ActivityType.QUIZ:
        // TODO: Implémenter Quiz.fromJson
        // return Quiz.fromJson(json);
        break;
      case ActivityType.ASSIGNMENT:
        // TODO: Implémenter Assignment.fromJson
        // return Assignment.fromJson(json);
        break;
      default:
        break;
    }

    return Activity(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      active: json['active'],
      title: json['title'],
      type: activityType,
      visible: json['visible'],
      order: json['order'],
      scope: ActivityScope.values.firstWhere(
        (e) => e.toString() == 'ActivityScope.${json['scope']}',
      ),
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      moduleId: json['moduleId'],
      chapterId: json['chapterId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'active': active,
      'title': title,
      'type': type.toString().split('.').last,
      'visible': visible,
      'order': order,
      'scope': scope.toString().split('.').last,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'moduleId': moduleId,
      'chapterId': chapterId,
    };
  }
}
