enum ActivityScope { MODULE, CHAPTER }

extension ActivityScopeExtension on ActivityScope {
  String get value => toString().split('.').last;
}

ActivityScope activityScopeFromString(String scope) {
  return ActivityScope.values.firstWhere(
      (e) => e.toString().split('.').last == scope,
      orElse: () => ActivityScope.MODULE);
}
