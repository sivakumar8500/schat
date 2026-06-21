import 'dart:typed_data';

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String? mediaUrl;
  final String? mediaType;
  final bool isDeleted;
  final bool isRead;
  final String createdAt;
  final String updatedAt;
  
  // New features support
  final bool isReply;
  final String? replyMessageId;
  final String? replyMessageBody;
  final bool isEdited;
  final bool isPinned;

  // Background upload tracking
  final Uint8List? attachmentBytes;
  final String? attachmentName;
  final bool isUploading;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.mediaUrl,
    this.mediaType,
    required this.isDeleted,
    this.isRead = false,
    required this.createdAt,
    required this.updatedAt,
    this.isReply = false,
    this.replyMessageId,
    this.replyMessageBody,
    this.isEdited = false,
    this.isPinned = false,
    this.attachmentBytes,
    this.attachmentName,
    this.isUploading = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
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

    return MessageModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      conversationId: (json['conversationId'] ?? json['conversation_id'] ?? json['conversation'])?.toString() ?? '',
      senderId: (json['senderId'] ?? json['sender_id'] ?? json['sender'])?.toString() ?? '',
      content: contentText,
      mediaUrl: mediaUrl,
      mediaType: mediaType ?? (json['media_type'] as String?),
      isDeleted: (json['isDeleted'] ?? json['is_deleted'] ?? json['isDeletedForEveryone']) as bool? ?? false,
      isRead: (json['isRead'] ?? json['is_read']) as bool? ?? false,
      createdAt: (json['createdAt'] ?? json['created_at'])?.toString() ?? '',
      updatedAt: (json['updatedAt'] ?? json['updated_at'])?.toString() ?? '',
      isReply: (json['isReply'] ?? json['is_reply']) as bool? ?? false,
      replyMessageId: (json['replyMessageId'] ?? json['reply_message_id'])?.toString(),
      replyMessageBody: () {
        final dynamic body = json['replyMessageBody'] ?? json['reply_message_body'];
        if (body is Map) {
          return (body['text'] ?? body['content'] ?? '')?.toString();
        }
        return body?.toString();
      }(),
      isEdited: (json['isEdited'] ?? json['is_edited']) as bool? ?? false,
      isPinned: (json['isPinned'] ?? json['is_pinned']) as bool? ?? false,
      attachmentBytes: null,
      attachmentName: null,
      isUploading: false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'senderId': senderId,
    'content': {
      'text': content,
      'fileKey': mediaUrl,
    },
    'type': mediaType,
    'isDeleted': isDeleted,
    'isRead': isRead,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'isReply': isReply,
    'replyMessageId': replyMessageId,
    'replyMessageBody': replyMessageBody,
    'isEdited': isEdited,
    'isPinned': isPinned,
  };

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    String? mediaUrl,
    String? mediaType,
    bool? isDeleted,
    bool? isRead,
    String? createdAt,
    String? updatedAt,
    bool? isReply,
    String? replyMessageId,
    String? replyMessageBody,
    bool? isEdited,
    bool? isPinned,
    Uint8List? attachmentBytes,
    String? attachmentName,
    bool? isUploading,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      isDeleted: isDeleted ?? this.isDeleted,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isReply: isReply ?? this.isReply,
      replyMessageId: replyMessageId ?? this.replyMessageId,
      replyMessageBody: replyMessageBody ?? this.replyMessageBody,
      isEdited: isEdited ?? this.isEdited,
      isPinned: isPinned ?? this.isPinned,
      attachmentBytes: attachmentBytes ?? this.attachmentBytes,
      attachmentName: attachmentName ?? this.attachmentName,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}
