class LastMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String? mediaUrl;
  final String? mediaType;
  final bool isDeleted;
  final String createdAt;
  final String updatedAt;

  const LastMessageModel({
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

  factory LastMessageModel.fromJson(Map<String, dynamic> json) {
    String contentText = '';
    String? mediaUrl;
    String? mediaType = json['type'] as String?;

    final dynamic contentData = json['content'];
    if (contentData is Map<String, dynamic>) {
      contentText = contentData['text'] as String? ?? '';
      mediaUrl = (contentData['fileKey'] ?? contentData['file_key'] ?? contentData['url']) as String?;
    } else if (contentData is String) {
      contentText = contentData;
      mediaUrl = (json['media_url'] ?? json['url']) as String?;
    }

    return LastMessageModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      conversationId: (json['conversationId'] ?? json['conversation_id'] ?? json['conversation'])?.toString() ?? '',
      senderId: (json['senderId'] ?? json['sender_id'] ?? json['sender'])?.toString() ?? '',
      content: contentText,
      mediaUrl: mediaUrl,
      mediaType: mediaType ?? (json['media_type'] as String?),
      isDeleted: (json['isDeleted'] ?? json['is_deleted'] ?? json['isDeletedForEveryone']) as bool? ?? false,
      createdAt: (json['createdAt'] ?? json['created_at'])?.toString() ?? '',
      updatedAt: (json['updatedAt'] ?? json['updated_at'])?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'senderId': senderId,
    'content': content,
    'media_url': mediaUrl,
    'media_type': mediaType,
    'is_deleted': isDeleted,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}
