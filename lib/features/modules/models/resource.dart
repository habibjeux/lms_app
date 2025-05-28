import 'activity.dart';
import 'enums/activity_scope.dart';
import 'enums/activity_type.dart';
import 'enums/resource_type.dart';

class Resource extends Activity {
  final ResourceType resourceType;
  final String url;
  final int? fileSize;
  final String? mimeType;
  final String? compressedUrl;
  final int? compressedSize;
  final String compressionStatus;

  Resource({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required super.active,
    required super.title,
    required super.visible,
    required super.order,
    required super.scope,
    super.startDate,
    super.endDate,
    required super.moduleId,
    super.chapterId,
    required this.resourceType,
    required this.url,
    this.fileSize,
    this.mimeType,
    this.compressedUrl,
    this.compressedSize,
    required this.compressionStatus,
  }) : super(type: ActivityType.RESOURCE);

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      active: json['active'],
      title: json['title'],
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
      resourceType: ResourceType.values.firstWhere(
        (e) => e.toString() == 'ResourceType.${json['resourceType']}',
      ),
      url: json['url'],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      compressedUrl: json['compressedUrl'],
      compressedSize: json['compressedSize'],
      compressionStatus: json['compressionStatus'] ?? 'FAILED',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'resourceType': resourceType.toString().split('.').last,
      'url': url,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'compressedUrl': compressedUrl,
      'compressedSize': compressedSize,
      'compressionStatus': compressionStatus,
    };
  }
}
