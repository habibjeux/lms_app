import '../../../core/models/base_model.dart';

class AssignmentAttachment extends BaseModel {
  final String assignmentId;
  final String filename;
  final String url;
  final int fileSize;
  final String mimeType;

  AssignmentAttachment({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required super.active,
    required this.assignmentId,
    required this.filename,
    required this.url,
    required this.fileSize,
    required this.mimeType,
  });

  factory AssignmentAttachment.fromJson(Map<String, dynamic> json) {
    try {
      return AssignmentAttachment(
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
        assignmentId:
            json['assignmentId']?.toString() ?? '', // Peut être absent de l'API
        filename: json['filename']?.toString() ?? '',
        url: json['url']?.toString() ?? '',
        fileSize: json['fileSize'] is int ? json['fileSize'] : 0,
        mimeType: json['mimeType']?.toString() ?? 'application/octet-stream',
      );
    } catch (e) {
      print("Erreur lors de la conversion de l'attachment: $e");
      print("JSON reçu: $json");
      rethrow;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> baseJson = super.toJson();
    return {
      ...baseJson,
      'assignmentId': assignmentId,
      'filename': filename,
      'url': url,
      'fileSize': fileSize,
      'mimeType': mimeType
    };
  }

  String _getAttachmentId(dynamic attachment) {
    return attachment.id?.toString() ?? attachment.filename?.toString() ?? '';
  }
}
