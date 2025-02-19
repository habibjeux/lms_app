// ignore: constant_identifier_names
enum ResourceType { PDF, VIDEO, LINK, FILE, IMAGE }

extension ResourceTypeExtension on ResourceType {
  String get value => toString().split('.').last;
}

ResourceType resourceTypeFromString(String type) {
  return ResourceType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
      orElse: () => ResourceType.FILE);
}
