enum ActivityType { RESOURCE, QUIZ, ASSIGNMENT, FORUM, CONTENT }

extension ActivityTypeExtension on ActivityType {
  String get value => toString().split('.').last;
}

ActivityType activityTypeFromString(String type) {
  return ActivityType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
      orElse: () => ActivityType.CONTENT);
}
