class Forum {
  final String id;
  final String title;
  final String description;
  final String? moduleId;
  final String? chapterId;
  final String schoolId;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Topic> topics;

  Forum({
    required this.id,
    required this.title,
    required this.description,
    this.moduleId,
    this.chapterId,
    required this.schoolId,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    required this.topics,
  });

  factory Forum.fromJson(Map<String, dynamic> json) {
    return Forum(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      moduleId: json['moduleId'],
      chapterId: json['chapterId'],
      schoolId: json['schoolId'] ?? '',
      active: json['active'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      topics: (json['topics'] as List<dynamic>?)
              ?.map((topic) => Topic.fromJson(topic))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'moduleId': moduleId,
      'chapterId': chapterId,
      'schoolId': schoolId,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'topics': topics.map((topic) => topic.toJson()).toList(),
    };
  }
}

class Topic {
  final String id;
  final String title;
  final String content;
  final bool pinned;
  final DateTime createdAt;
  final Author author;
  final int replyCount;
  final List<Reply>? replies;

  Topic({
    required this.id,
    required this.title,
    required this.content,
    required this.pinned,
    required this.createdAt,
    required this.author,
    required this.replyCount,
    this.replies,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      pinned: json['pinned'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      author: Author.fromJson(json['author']),
      replyCount: json['_count']?['replies'] ?? 0,
      replies: (json['replies'] as List<dynamic>?)
          ?.map((reply) => Reply.fromJson(reply))
          .toList(), // Parsing des replies
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'pinned': pinned,
      'createdAt': createdAt.toIso8601String(),
      'author': author.toJson(),
      '_count': {'replies': replyCount},
      'replies': replies?.map((reply) => reply.toJson()).toList(),
    };
  }
}

class Author {
  final String id;
  final String firstName;
  final String lastName;
  final String role;

  Author({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
    };
  }

  String get fullName => '$firstName $lastName';
}

class Reply {
  final String id;
  final String content;
  final DateTime createdAt;
  final Author author;
  final String? parentReplyId;
  final List<Reply>? childReplies;

  Reply({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.author,
    this.parentReplyId,
    this.childReplies,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      author: Author.fromJson(json['author']),
      parentReplyId: json['parentReplyId'],
      childReplies: (json['childReplies'] as List<dynamic>?)
          ?.map((reply) => Reply.fromJson(reply))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'author': author.toJson(),
      'parentReplyId': parentReplyId,
      'childReplies': childReplies?.map((reply) => reply.toJson()).toList(),
    };
  }
}
