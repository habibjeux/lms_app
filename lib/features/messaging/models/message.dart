import 'package:lms_app/features/auth/models/user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class Message {
  final String id;
  final String content;
  final String senderId;
  final String receiverId;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String discussionId;
  final User? sender;
  final User? receiver;
  final List<MessageAttachment> attachments;
  final String? localId;
  final String? status; // pending, sent, error

  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.receiverId,
    this.readAt,
    required this.createdAt,
    this.updatedAt,
    required this.discussionId,
    this.sender,
    this.receiver,
    this.attachments = const [],
    this.localId,
    this.status,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    var attachments = <MessageAttachment>[];
    if (json['attachments'] != null) {
      attachments = (json['attachments'] as List)
          .map((attachment) => MessageAttachment.fromJson(attachment))
          .toList();
    }

    return Message(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      discussionId: json['discussionId'] ?? '',
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
      receiver:
          json['receiver'] != null ? User.fromJson(json['receiver']) : null,
      attachments: attachments,
      localId: json['localId'],
      status: json['status'] ?? 'sent',
    );
  }

  factory Message.pending({
    required String content,
    required String senderId,
    required String receiverId,
    required String discussionId,
    List<MessageAttachment> attachments = const [],
    required String localId,
  }) {
    return Message(
      id: 'pending_${DateTime.now().millisecondsSinceEpoch}_$localId',
      content: content,
      senderId: senderId,
      receiverId: receiverId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      discussionId: discussionId,
      attachments: attachments,
      localId: localId,
      status: 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'senderId': senderId,
      'receiverId': receiverId,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'discussionId': discussionId,
      'sender': sender,
      'receiver': receiver,
      'attachments':
          attachments.map((attachment) => attachment.toJson()).toList(),
      'localId': localId,
      'status': status,
    };
  }

  Message copyWith({
    String? id,
    String? content,
    String? senderId,
    String? receiverId,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? discussionId,
    User? sender,
    User? receiver,
    List<MessageAttachment>? attachments,
    String? localId,
    String? status,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      discussionId: discussionId ?? this.discussionId,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      attachments: attachments ?? this.attachments,
      localId: localId ?? this.localId,
      status: status ?? this.status,
    );
  }

  bool get isPending => status == 'pending';
  bool get isError => status == 'error';
  bool get isSent => status == 'sent' || status == null;
}

class MessageAttachment {
  final String id;
  final String messageId;
  final String filename;
  final String fileUrl;
  final int fileSize;
  final String mimeType;
  final DateTime createdAt;
  final String? localPath;

  MessageAttachment({
    required this.id,
    required this.messageId,
    required this.filename,
    required this.fileUrl,
    required this.fileSize,
    required this.mimeType,
    required this.createdAt,
    this.localPath,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    final baseUrl = dotenv.env['SERVER_URL'] ?? '';
    final fileUrl = json['fileUrl'] ?? '';

    // Vérifier si l'URL est déjà complète ou relative
    String fullUrl;
    if (fileUrl.startsWith('http')) {
      fullUrl = fileUrl;
    } else if (fileUrl.startsWith('/')) {
      fullUrl = '$baseUrl$fileUrl';
    } else {
      fullUrl = '$baseUrl/$fileUrl';
    }

    debugPrint('URL de la pièce jointe: $fullUrl');

    return MessageAttachment(
      id: json['id'] ?? '',
      messageId: json['messageId'] ?? '',
      filename: json['filename'] ?? '',
      fileUrl: fullUrl,
      fileSize: json['fileSize'] ?? 0,
      mimeType: json['mimeType'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      localPath: json['localPath'] ?? '',
    );
  }

  factory MessageAttachment.fromLocalFile({
    required String localPath,
    required String filename,
    required int fileSize,
    required String mimeType,
  }) {
    return MessageAttachment(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}_$filename',
      messageId: 'pending',
      filename: filename,
      fileUrl:
          localPath, // Pour les fichiers locaux, on utilise le chemin local
      fileSize: fileSize,
      mimeType: mimeType,
      createdAt: DateTime.now(),
      localPath: localPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'messageId': messageId,
      'filename': filename,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'createdAt': createdAt.toIso8601String(),
      'localPath': localPath,
    };
  }

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';
  bool get isLocal => localPath != null && localPath!.isNotEmpty;
  bool get isRemote => !isLocal && fileUrl.startsWith('http');
}
