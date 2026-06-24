import 'recipient_model.dart';
import 'last_message_model.dart';

class ChatModel {
  final String id;
  final bool isGroup;
  final String? groupName;
  final String? groupDescription;
  final String createdAt;
  final String updatedAt;
  final RecipientModel recipient;
  final LastMessageModel? lastMessage;

  const ChatModel({
    this.id = '',
    this.isGroup = false,
    this.groupName,
    this.groupDescription,
    this.createdAt = '',
    this.updatedAt = '',
    required this.recipient,
    this.lastMessage,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      isGroup: json['is_group'] as bool? ?? false,
      groupName: json['group_name']?.toString(),
      groupDescription: json['group_description']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      recipient: RecipientModel.fromJson(json['recipient'] as Map<String, dynamic>? ?? {}),
      lastMessage: json['last_message'] != null
          ? LastMessageModel.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'is_group': isGroup,
        'group_name': groupName,
        'group_description': groupDescription,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'recipient': recipient.toJson(),
        'last_message': lastMessage?.toJson(),
      };

  ChatModel copyWith({
    String? id,
    bool? isGroup,
    String? groupName,
    String? groupDescription,
    String? createdAt,
    String? updatedAt,
    RecipientModel? recipient,
    LastMessageModel? lastMessage,
  }) {
    return ChatModel(
      id: id ?? this.id,
      isGroup: isGroup ?? this.isGroup,
      groupName: groupName ?? this.groupName,
      groupDescription: groupDescription ?? this.groupDescription,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      recipient: recipient ?? this.recipient,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}
