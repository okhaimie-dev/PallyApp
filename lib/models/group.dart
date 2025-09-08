class Group {
  final int id;
  final String name;
  final String description;
  final String category;
  final String icon;
  final String color;
  final bool isPrivate;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    required this.isPrivate,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      icon: json['icon'] ?? 'group',
      color: json['color'] ?? 'blue',
      isPrivate: json['isPrivate'] ?? false,
      createdBy: json['createdBy'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'icon': icon,
      'color': color,
      'isPrivate': isPrivate,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class GroupMember {
  final int id;
  final int groupId;
  final String userEmail;
  final String role;
  final DateTime joinedAt;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userEmail,
    required this.role,
    required this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'],
      groupId: json['groupId'],
      userEmail: json['userEmail'],
      role: json['role'] ?? 'member',
      joinedAt: DateTime.parse(json['joinedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'userEmail': userEmail,
      'role': role,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}

class GroupResponse {
  final bool success;
  final Group? group;
  final String message;

  GroupResponse({
    required this.success,
    this.group,
    required this.message,
  });

  factory GroupResponse.fromJson(Map<String, dynamic> json) {
    return GroupResponse(
      success: json['success'] ?? false,
      group: json['group'] != null ? Group.fromJson(json['group']) : null,
      message: json['message'] ?? '',
    );
  }
}

class MessagesResponse {
  final bool success;
  final List<ChatMessage> messages;
  final String message;

  MessagesResponse({
    required this.success,
    required this.messages,
    required this.message,
  });

  factory MessagesResponse.fromJson(Map<String, dynamic> json) {
    return MessagesResponse(
      success: json['success'] ?? false,
      messages: (json['messages'] as List<dynamic>?)
          ?.map((msg) => ChatMessage.fromJson(msg))
          .toList() ?? [],
      message: json['message'] ?? '',
    );
  }
}

class ChatMessage {
  final int id;
  final int groupId;
  final String senderEmail;
  final String content;
  final String messageType;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.groupId,
    required this.senderEmail,
    required this.content,
    required this.messageType,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      groupId: json['groupId'],
      senderEmail: json['senderEmail'],
      content: json['content'],
      messageType: json['messageType'] ?? 'text',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'senderEmail': senderEmail,
      'content': content,
      'messageType': messageType,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class MessageResponse {
  final bool success;
  final int? messageId;
  final String? error;

  MessageResponse({
    required this.success,
    this.messageId,
    this.error,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    return MessageResponse(
      success: json['success'] ?? false,
      messageId: json['messageId'],
      error: json['error'],
    );
  }
}
