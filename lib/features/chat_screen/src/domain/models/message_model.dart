import 'dart:typed_data';

class CallMeta {
  final String callType; // "audio" or "video"
  final int duration; // seconds
  final String status; // "completed", "missed", "rejected", "busy"
  final String startTime;

  const CallMeta({
    required this.callType,
    required this.duration,
    required this.status,
    required this.startTime,
  });

  factory CallMeta.fromJson(Map<String, dynamic> json) {
    return CallMeta(
      callType: (json['callType'] ?? json['call_type'] ?? 'audio').toString(),
      duration: int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      status: (json['status'] ?? 'completed').toString(),
      startTime: (json['start_time'] ?? json['startTime'] ?? DateTime.now().toIso8601String()).toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'callType': callType,
    'duration': duration,
    'status': status,
    'start_time': startTime,
  };
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String? mediaUrl;
  final String? mediaType;
  final bool isDeleted;
  final bool isRead;
  final bool isDelivered;
  final String createdAt;
  final String updatedAt;
  
  // New features support
  final bool isReply;
  final String? replyMessageId;
  final String? replyMessageBody;
  final bool isEdited;
  final bool isPinned;
  final int? pinnedAt;

  // Background upload tracking
  final Uint8List? attachmentBytes;
  final String? attachmentName;
  final bool isUploading;
  final int? fileSize;
  final bool isFailed;

  // Attachment permissions
  final bool allowShare;
  final bool allowDownload;
  final bool allowView;

  // Call support
  final CallMeta? callMeta;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.mediaUrl,
    this.mediaType,
    required this.isDeleted,
    this.isRead = false,
    this.isDelivered = false,
    required this.createdAt,
    required this.updatedAt,
    this.isReply = false,
    this.replyMessageId,
    this.replyMessageBody,
    this.isEdited = false,
    this.isPinned = false,
    this.pinnedAt,
    this.attachmentBytes,
    this.attachmentName,
    this.isUploading = false,
    this.isFailed = false,
    this.allowShare = true,
    this.allowDownload = true,
    this.allowView = true,
    this.fileSize,
    this.callMeta,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    String contentText = '';
    String? mediaUrl;
    String? mediaType = (json['type'] as String?)?.toLowerCase();

    final dynamic contentData = json['content'];
    if (contentData is Map) {
      contentText = (contentData['text'] ?? '')?.toString() ?? '';
      mediaUrl = (contentData['fileKey'] ?? contentData['file_key'] ?? contentData['url']) as String?;
    } else if (contentData is String) {
      contentText = contentData;
      mediaUrl = (json['media_url'] ?? json['url']) as String?;
    }

    final dynamic security = json['security'];
    final dynamic viewControl = json['viewControl'] ?? json['view_control'];
    
    bool allowShare = true;
    bool allowDownload = true;
    bool allowView = true;

    if (security is Map) {
      allowShare = (security['allowShare'] ?? security['allow_share'] ?? allowShare) as bool;
      allowDownload = (security['allowDownload'] ?? security['allow_download'] ?? allowDownload) as bool;
      allowView = (security['allowView'] ?? security['allow_view'] ?? allowView) as bool;
    }

    if (viewControl is Map) {
      allowShare = (viewControl['allowShare'] ?? viewControl['allow_share'] ?? allowShare) as bool;
      allowDownload = (viewControl['allowDownload'] ?? viewControl['allow_download'] ?? allowDownload) as bool;
      allowView = (viewControl['allowView'] ?? viewControl['allow_view'] ?? allowView) as bool;
    }

    allowShare = (json['allowShare'] ?? json['allow_share'] ?? allowShare) as bool;
    allowDownload = (json['allowDownload'] ?? json['allow_download'] ?? allowDownload) as bool;
    allowView = (json['allowView'] ?? json['allow_view'] ?? allowView) as bool;

    int? fileSize;
    final dynamic rawFileSize = json['fileSize'] ?? json['file_size'] ?? json['file_size_bytes'] ?? 
        (contentData is Map ? (contentData['fileSize'] ?? contentData['file_size']) : null);
    if (rawFileSize != null) {
      fileSize = int.tryParse(rawFileSize.toString());
    }

    final String? parsedAttachmentName = (json['attachmentName'] ?? json['attachment_name'] ?? json['file_name'] ?? 
        (contentData is Map ? (contentData['fileName'] ?? contentData['file_name'] ?? contentData['name']) : null)) as String?;

    CallMeta? callMeta;
    final dynamic rawCallMeta = json['callMeta'] ?? json['call_meta'];
    if (rawCallMeta is Map) {
      callMeta = CallMeta.fromJson(Map<String, dynamic>.from(rawCallMeta));
    }

    return MessageModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      conversationId: (json['conversationId'] ?? json['conversation_id'] ?? json['conversation'])?.toString() ?? '',
      senderId: (json['senderId'] ?? json['sender_id'] ?? json['sender'])?.toString() ?? '',
      content: contentText,
      mediaUrl: mediaUrl,
      mediaType: (mediaType ?? (json['media_type'] as String?))?.toLowerCase(),
      isDeleted: (json['isDeleted'] ?? json['is_deleted'] ?? json['isDeletedForEveryone']) as bool? ?? false,
      isRead: (json['isRead'] ?? json['is_read']) as bool? ?? false,
      isDelivered: (json['isDelivered'] ?? json['is_delivered']) as bool? ?? false,
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
      pinnedAt: json['pinnedAt'] ?? json['pinned_at'],
      attachmentBytes: null,
      attachmentName: parsedAttachmentName,
      isUploading: false,
      isFailed: (json['isFailed'] ?? json['is_failed']) as bool? ?? false,
      allowShare: allowShare,
      allowDownload: allowDownload,
      allowView: allowView,
      fileSize: fileSize,
      callMeta: callMeta,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'senderId': senderId,
    'content': {
      'text': content,
      'fileKey': mediaUrl,
      if (attachmentName != null) 'fileName': attachmentName,
      if (fileSize != null) 'fileSize': fileSize,
    },
    'type': mediaType,
    'isDeleted': isDeleted,
    'isRead': isRead,
    'isDelivered': isDelivered,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'isReply': isReply,
    'replyMessageId': replyMessageId,
    'replyMessageBody': replyMessageBody,
    'isEdited': isEdited,
    'isPinned': isPinned,
    'pinnedAt': pinnedAt,
    'attachmentName': attachmentName,
    'fileSize': fileSize,
    'isFailed': isFailed,
    'viewControl': {
      'allowShare': allowShare,
      'allowDownload': allowDownload,
      'allowView': allowView,
    },
    if (callMeta != null) 'callMeta': callMeta!.toJson(),
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
    bool? isDelivered,
    String? createdAt,
    String? updatedAt,
    bool? isReply,
    String? replyMessageId,
    String? replyMessageBody,
    bool? isEdited,
    bool? isPinned,
    int? pinnedAt,
    Uint8List? attachmentBytes,
    String? attachmentName,
    bool? isUploading,
    bool? isFailed,
    bool? allowShare,
    bool? allowDownload,
    bool? allowView,
    int? fileSize,
    CallMeta? callMeta,
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
      isDelivered: isDelivered ?? this.isDelivered,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isReply: isReply ?? this.isReply,
      replyMessageId: replyMessageId ?? this.replyMessageId,
      replyMessageBody: replyMessageBody ?? this.replyMessageBody,
      isEdited: isEdited ?? this.isEdited,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      attachmentBytes: attachmentBytes ?? this.attachmentBytes,
      attachmentName: attachmentName ?? this.attachmentName,
      isUploading: isUploading ?? this.isUploading,
      isFailed: isFailed ?? this.isFailed,
      allowShare: allowShare ?? this.allowShare,
      allowDownload: allowDownload ?? this.allowDownload,
      allowView: allowView ?? this.allowView,
      fileSize: fileSize ?? this.fileSize,
      callMeta: callMeta ?? this.callMeta,
    );
  }
}

