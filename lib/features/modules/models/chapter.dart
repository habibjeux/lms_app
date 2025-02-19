import 'activity.dart';

class Chapter {
  final String id;
  final String title;
  final String description;
  final int order;
  final bool visible;
  final String moduleId;
  final String? content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool active;
  final List<Activity> activities;

  Chapter({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.visible,
    required this.moduleId,
    this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.active,
    this.activities = const [],
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    List<Activity> activitiesList = [];
    if (json['activities'] != null) {
      activitiesList = (json['activities'] as List)
          .map((activityJson) => Activity.fromJson(activityJson))
          .where((activity) => activity.active)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    }

    return Chapter(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      order: json['order'],
      visible: json['visible'],
      moduleId: json['moduleId'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      active: json['active'],
      activities: activitiesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'order': order,
      'visible': visible,
      'moduleId': moduleId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'active': active,
      'activities': activities.map((activity) => activity.toJson()).toList(),
    };
  }

  Chapter copyWith({
    String? id,
    String? title,
    String? description,
    int? order,
    bool? visible,
    String? moduleId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? active,
    List<Activity>? activities,
  }) {
    return Chapter(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order ?? this.order,
      visible: visible ?? this.visible,
      moduleId: moduleId ?? this.moduleId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      active: active ?? this.active,
      activities: activities ?? this.activities,
    );
  }
}
