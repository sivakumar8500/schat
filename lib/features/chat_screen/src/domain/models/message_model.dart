class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String? mediaUrl;
  final String? mediaType;
  final bool isDeleted;
  final String createdAt;
  final String updatedAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.mediaUrl,
    this.mediaType,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    id: json['id'] as String? ?? '',
    conversationId: json['conversation_id'] as String? ?? '',
    senderId: json['sender_id'] as String? ?? '',
    content: json['content'] as String? ?? '',
    mediaUrl: json['media_url'] as String?,
    mediaType: json['media_type'] as String?,
    isDeleted: json['is_deleted'] as bool? ?? false,
    createdAt: json['created_at'] as String? ?? '',
    updatedAt: json['updated_at'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation_id': conversationId,
    'sender_id': senderId,
    'content': content,
    'media_url': mediaUrl,
    'media_type': mediaType,
    'is_deleted': isDeleted,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}
