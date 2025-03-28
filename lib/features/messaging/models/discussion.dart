import 'package:lms_app/features/auth/models/user.dart';

import 'message.dart';

class Discussion {
  final String id;
  final DateTime lastMessageAt;
  final String participantOneId;
  final String participantTwoId;
  final Map<String, dynamic> participantOne;
  final Map<String, dynamic> participantTwo;
  final List<Message> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;
  final bool isLocal;

  Discussion({
    required this.id,
    required this.lastMessageAt,
    required this.participantOneId,
    required this.participantTwoId,
    required this.participantOne,
    required this.participantTwo,
    this.messages = const [],
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = 0,
    this.isLocal = false,
  });

  factory Discussion.fromJson(Map<String, dynamic> json) {
    var messages = <Message>[];
    print("messages" + messages.toString());
    if (json['messages'] != null) {
      messages = (json['messages'] as List)
          .map((msg) => Message.fromJson(msg))
          .toList();
    }
    print("messages" + messages.toString());

    return Discussion(
      id: json['id'],
      lastMessageAt: DateTime.parse(json['lastMessageAt']),
      participantOneId: json['participantOneId'],
      participantTwoId: json['participantTwoId'],
      participantOne: User.fromJson(json['participantOne']).toJson(),
      participantTwo: User.fromJson(json['participantTwo']).toJson(),
      messages: messages,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      unreadCount: json['unreadCount'] ?? 0,
      isLocal: json['isLocal'] ?? false,
    );
  }

  factory Discussion.local({
    required String participantOneId,
    required String participantTwoId,
    required Map<String, dynamic> participantOne,
    required Map<String, dynamic> participantTwo,
  }) {
    final now = DateTime.now();
    final localId = 'local_${now.millisecondsSinceEpoch}';

    return Discussion(
      id: localId,
      lastMessageAt: now,
      participantOneId: participantOneId,
      participantTwoId: participantTwoId,
      participantOne: participantOne,
      participantTwo: participantTwo,
      createdAt: now,
      updatedAt: now,
      isLocal: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'participantOneId': participantOneId,
      'participantTwoId': participantTwoId,
      'participantOne': participantOne,
      'participantTwo': participantTwo,
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'unreadCount': unreadCount,
      'isLocal': isLocal
    };
  }

  Discussion copyWith({
    String? id,
    DateTime? lastMessageAt,
    String? participantOneId,
    String? participantTwoId,
    Map<String, dynamic>? participantOne,
    Map<String, dynamic>? participantTwo,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? unreadCount,
    bool? isLocal,
  }) {
    return Discussion(
      id: id ?? this.id,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      participantOneId: participantOneId ?? this.participantOneId,
      participantTwoId: participantTwoId ?? this.participantTwoId,
      participantOne: participantOne ?? this.participantOne,
      participantTwo: participantTwo ?? this.participantTwo,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  Map<String, dynamic> getOtherParticipant(String currentUserId) {
    return participantOneId == currentUserId ? participantTwo : participantOne;
  }

  String getOtherParticipantId(String currentUserId) {
    return participantOneId == currentUserId
        ? participantTwoId
        : participantOneId;
  }

  Message? get lastMessage {
    if (messages.isEmpty) return null;
    return messages.first;
  }

  bool hasUnreadMessages(String currentUserId) {
    return unreadCount > 0;
  }

  factory Discussion.empty() {
    return Discussion(
      id: '',
      lastMessageAt: DateTime.now(),
      participantOneId: '',
      participantTwoId: '',
      participantOne: {},
      participantTwo: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
