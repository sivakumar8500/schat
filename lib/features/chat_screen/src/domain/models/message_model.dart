import 'dart:typed_data';
import 'dart:convert';
import 'package:schat/injection.dart';
import 'package:schat/core/storage/storage_service.dart';

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
      duration: int.tryParse((json['duration'] ?? json['duration_seconds'])?.toString() ?? '0') ?? 0,
      status: (json['status'] ?? 'completed').toString(),
      startTime: (json['start_time'] ?? json['startTime'] ?? json['timestamp'] ?? DateTime.now().toIso8601String()).toString(),
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
  /// Top-level message type: "text", "system", "image", "video", "audio", etc.
  /// "system" messages are group status notifications (e.g. "John is added").
  final String messageType;
  final bool isDeleted;
  final bool isDeletedForMe;
  final bool isRead;
  final bool isDelivered;
  final String createdAt;
  final String updatedAt;
  
  // New features support
  final bool isReply;
  final String? replyMessageId;
  final String? replyMessageBody;
  final bool isEdited;
  final int? editedAt;
  final bool isPinned;
  final int? pinnedAt;

  // Location support
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? locationTitle;

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

  // Attachment tracking status
  final bool isFileViewed;
  final bool isFileDownloaded;
  final bool isFileShared;

  // Call support
  final CallMeta? callMeta;
  final double? duration;
  final List<String> deletedFor;

  // Disappearing messages
  final int? expiry;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.mediaUrl,
    this.mediaType,
    this.messageType = 'text',
    required this.isDeleted,
    this.isDeletedForMe = false,
    this.isRead = false,
    this.isDelivered = false,
    required this.createdAt,
    required this.updatedAt,
    this.isReply = false,
    this.replyMessageId,
    this.replyMessageBody,
    this.isEdited = false,
    this.editedAt,
    this.isPinned = false,
    this.pinnedAt,
    this.latitude,
    this.longitude,
    this.address,
    this.locationTitle,
    this.attachmentBytes,
    this.attachmentName,
    this.isUploading = false,
    this.isFailed = false,
    this.allowShare = true,
    this.allowDownload = true,
    this.allowView = true,
    this.isFileViewed = false,
    this.isFileDownloaded = false,
    this.isFileShared = false,
    this.fileSize,
    this.callMeta,
    this.duration,
    this.deletedFor = const [],
    this.expiry,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    String contentText = '';
    String? mediaUrl;
    final String rawType = (json['type'] as String?)?.toLowerCase() ?? 'text';
    // messageType holds the top-level type (e.g. 'system', 'text', 'image').
    // mediaType holds the media sub-type for attachment bubbles.
    final String messageType = rawType;
    String? mediaType = rawType == 'system' ? null : rawType;

    dynamic contentData = json['content'];
    if (contentData is String) {
      try {
        final decoded = jsonDecode(contentData);
        if (decoded is Map) {
          contentData = decoded;
        }
      } catch (_) {}
    }
    double? duration;
    if (contentData is Map) {
      contentText = (contentData['text'] ?? '')?.toString() ?? '';
      mediaUrl = (contentData['fileKey'] ?? contentData['file_key'] ?? contentData['url']) as String?;
      final rawDuration = contentData['duration'] ?? json['duration'];
      if (rawDuration != null) {
        duration = double.tryParse(rawDuration.toString());
      }
    } else if (contentData is String) {
      contentText = contentData;
      mediaUrl = (json['media_url'] ?? json['url']) as String?;
      final rawDuration = json['duration'];
      if (rawDuration != null) {
        duration = double.tryParse(rawDuration.toString());
      }
    }

    final dynamic security = json['security'];
    final dynamic viewControl = json['viewControl'] ?? json['view_control'];
    
    bool allowShare = true;
    bool allowDownload = true;
    bool allowView = true;
    bool isFileViewed = false;
    bool isFileDownloaded = false;
    bool isFileShared = false;

    if (security is Map) {
      allowShare = (security['allowShare'] ?? security['allow_share'] ?? allowShare) as bool;
      allowDownload = (security['allowDownload'] ?? security['allow_download'] ?? allowDownload) as bool;
      allowView = (security['allowView'] ?? security['allow_view'] ?? allowView) as bool;
      isFileViewed = (security['isFileViewed'] ?? security['file_viewed'] ?? security['is_file_viewed'] ?? isFileViewed) as bool? ?? false;
      isFileDownloaded = (security['isFileDownloaded'] ?? security['file_downloaded'] ?? security['is_file_downloaded'] ?? isFileDownloaded) as bool? ?? false;
      isFileShared = (security['isFileShared'] ?? security['file_shared'] ?? security['is_file_shared'] ?? isFileShared) as bool? ?? false;
    }

    if (viewControl is Map) {
      allowShare = (viewControl['allowShare'] ?? viewControl['allow_share'] ?? allowShare) as bool;
      allowDownload = (viewControl['allowDownload'] ?? viewControl['allow_download'] ?? allowDownload) as bool;
      allowView = (viewControl['allowView'] ?? viewControl['allow_view'] ?? allowView) as bool;
      isFileViewed = (viewControl['isFileViewed'] ?? viewControl['file_viewed'] ?? viewControl['is_file_viewed'] ?? isFileViewed) as bool? ?? false;
      isFileDownloaded = (viewControl['isFileDownloaded'] ?? viewControl['file_downloaded'] ?? viewControl['is_file_downloaded'] ?? isFileDownloaded) as bool? ?? false;
      isFileShared = (viewControl['isFileShared'] ?? viewControl['file_shared'] ?? viewControl['is_file_shared'] ?? isFileShared) as bool? ?? false;
    }

    if (json['allowShare'] != null) {
      allowShare = json['allowShare'] as bool;
    } else if (json['allow_share'] != null) allowShare = json['allow_share'] as bool;

    if (json['allowDownload'] != null) {
      allowDownload = json['allowDownload'] as bool;
    } else if (json['allow_download'] != null) allowDownload = json['allow_download'] as bool;

    if (json['allowView'] != null) {
      allowView = json['allowView'] as bool;
    } else if (json['allow_view'] != null) allowView = json['allow_view'] as bool;

    if (json['isFileViewed'] != null) {
      isFileViewed = json['isFileViewed'] as bool;
    } else if (json['file_viewed'] != null) isFileViewed = json['file_viewed'] as bool;

    if (json['isFileDownloaded'] != null) {
      isFileDownloaded = json['isFileDownloaded'] as bool;
    } else if (json['file_downloaded'] != null) isFileDownloaded = json['file_downloaded'] as bool;

    if (json['isFileShared'] != null) {
      isFileShared = json['isFileShared'] as bool;
    } else if (json['file_shared'] != null) isFileShared = json['file_shared'] as bool;

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
    } else if (json['callType'] != null || json['call_type'] != null) {
      callMeta = CallMeta.fromJson(json);
    }

    final dynamic rawDeletedFor = json['deletedFor'] ?? json['deleted_for'];
    final List<String> deletedForList = [];
    if (rawDeletedFor is List) {
      for (var item in rawDeletedFor) {
        if (item != null) {
          deletedForList.add(item.toString());
        }
      }
    }
    final String? currentUserId = getIt.isRegistered<StorageService>() ? getIt<StorageService>().getUserId() : null;
    final bool rawIsDeleted = (json['isDeleted'] ?? json['is_deleted'] ?? json['isDeletedForEveryone']) as bool? ?? false;
    final bool isDeletedForMeOnly = currentUserId != null && deletedForList.contains(currentUserId) && !rawIsDeleted;
    final bool resolvedIsDeleted = rawIsDeleted || (currentUserId != null && deletedForList.contains(currentUserId));

    // Extract location data if present
    double? latitude;
    double? longitude;
    String? address;
    String? locationTitle;

    if (contentData is Map) {
      if (contentData['latitude'] != null) {
        latitude = double.tryParse(contentData['latitude'].toString());
      }
      if (contentData['longitude'] != null) {
        longitude = double.tryParse(contentData['longitude'].toString());
      }
      address = contentData['address']?.toString();
      locationTitle = contentData['title']?.toString();
    }

    // Fallback to top-level keys for messages loaded from local cache
    if (latitude == null && json['latitude'] != null) {
      latitude = double.tryParse(json['latitude'].toString());
    }
    if (longitude == null && json['longitude'] != null) {
      longitude = double.tryParse(json['longitude'].toString());
    }
    if (address == null && json['address'] != null) {
      address = json['address']?.toString();
    }
    if (locationTitle == null && json['title'] != null) {
      locationTitle = json['title']?.toString();
    }

    return MessageModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      conversationId: (json['conversationId'] ?? json['conversation_id'] ?? json['conversation'])?.toString() ?? '',
      senderId: (json['senderId'] ?? json['sender_id'] ?? json['sender'])?.toString() ?? '',
      content: contentText,
      mediaUrl: mediaUrl,
      messageType: messageType,
      mediaType: (mediaType ?? (json['media_type'] as String?))?.toLowerCase(),
      isDeleted: resolvedIsDeleted,
      isDeletedForMe: isDeletedForMeOnly,
      isRead: _parseIsRead(json),
      isDelivered: _parseIsDelivered(json),
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
      editedAt: int.tryParse((json['editedAt'] ?? json['edited_at'])?.toString() ?? ''),
      isPinned: (json['isPinned'] ?? json['is_pinned']) as bool? ?? false,
      pinnedAt: int.tryParse((json['pinnedAt'] ?? json['pinned_at'])?.toString() ?? ''),
      latitude: latitude,
      longitude: longitude,
      address: address,
      locationTitle: locationTitle,
      attachmentBytes: null,
      attachmentName: parsedAttachmentName,
      isUploading: false,
      isFailed: (json['isFailed'] ?? json['is_failed']) as bool? ?? false,
      allowShare: allowShare,
      allowDownload: allowDownload,
      allowView: allowView,
      isFileViewed: isFileViewed,
      isFileDownloaded: isFileDownloaded,
      isFileShared: isFileShared,
      fileSize: fileSize,
      callMeta: callMeta,
      duration: duration,
      deletedFor: deletedForList,
      expiry: () {
        final dynamic rawExpiry = json['expiry'] ?? json['expiry_config'] ?? json['expires_at'] ?? json['expire_at'];
        if (rawExpiry is int) return rawExpiry;
        if (rawExpiry is num) return rawExpiry.toInt();
        if (rawExpiry is Map) {
          final expAt = rawExpiry['expires_at'] ?? rawExpiry['expireAt'] ?? rawExpiry['expire_at'] ?? rawExpiry['expiry'];
          if (expAt is int) return expAt;
          if (expAt is num) return expAt.toInt();
          if (expAt is String) {
            final parsed = int.tryParse(expAt);
            if (parsed != null) return parsed;
            final dt = DateTime.tryParse(expAt);
            if (dt != null) return dt.toUtc().millisecondsSinceEpoch ~/ 1000;
          }
          return null;
        }
        if (rawExpiry is String) {
          final parsed = int.tryParse(rawExpiry);
          if (parsed != null) return parsed;
          final dt = DateTime.tryParse(rawExpiry);
          if (dt != null) return dt.toUtc().millisecondsSinceEpoch ~/ 1000;
        }
        return null;
      }(),
    );
  }

  /// Parses isRead from either a legacy bool field or the backend `status` string.
  /// status values: "sent" | "delivered" | "read"
  static bool _parseIsRead(Map<String, dynamic> json) {
    // Legacy bool field (cached messages)
    final legacyBool = json['isRead'] ?? json['is_read'];
    if (legacyBool is bool) return legacyBool;

    // New backend status string
    final status = (json['status'] as String?)?.toLowerCase();
    return status == 'read';
  }

  /// Parses isDelivered from either a legacy bool field or the backend `status` string.
  static bool _parseIsDelivered(Map<String, dynamic> json) {
    // Legacy bool field (cached messages)
    final legacyBool = json['isDelivered'] ?? json['is_delivered'];
    if (legacyBool is bool) return legacyBool;

    // New backend status string — "delivered" or "read" both mean delivered
    final status = (json['status'] as String?)?.toLowerCase();
    return status == 'delivered' || status == 'read';
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
      if (duration != null) 'duration': duration,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (address != null) 'address': address,
      if (locationTitle != null) 'title': locationTitle,
    },
    'type': messageType != 'text' ? messageType : mediaType,
    'isDeleted': isDeleted,
    'isDeletedForMe': isDeletedForMe,
    'isRead': isRead,
    'isDelivered': isDelivered,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'isReply': isReply,
    'replyMessageId': replyMessageId,
    'replyMessageBody': replyMessageBody,
    'isEdited': isEdited,
    'editedAt': editedAt,
    'isPinned': isPinned,
    'pinnedAt': pinnedAt,
    'attachmentName': attachmentName,
    'fileSize': fileSize,
    'isFailed': isFailed,
    'isFileViewed': isFileViewed,
    'isFileDownloaded': isFileDownloaded,
    'isFileShared': isFileShared,
    'security': {
      'allowShare': allowShare,
      'allowDownload': allowDownload,
      'allowView': allowView,
      'isFileViewed': isFileViewed,
      'isFileDownloaded': isFileDownloaded,
      'isFileShared': isFileShared,
    },
    'viewControl': {
      'allowShare': allowShare,
      'allowDownload': allowDownload,
      'allowView': allowView,
      'isFileViewed': isFileViewed,
      'isFileDownloaded': isFileDownloaded,
      'isFileShared': isFileShared,
    },
    'deletedFor': deletedFor,
    if (callMeta != null) 'callMeta': callMeta!.toJson(),
    if (expiry != null) 'expiry': expiry,
  };

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    String? mediaUrl,
    String? mediaType,
    String? messageType,
    bool? isDeleted,
    bool? isDeletedForMe,
    bool? isRead,
    bool? isDelivered,
    String? createdAt,
    String? updatedAt,
    bool? isReply,
    String? replyMessageId,
    String? replyMessageBody,
    bool? isEdited,
    int? editedAt,
    bool? isPinned,
    int? pinnedAt,
    Uint8List? attachmentBytes,
    String? attachmentName,
    bool? isUploading,
    bool? isFailed,
    bool? allowShare,
    bool? allowDownload,
    bool? allowView,
    bool? isFileViewed,
    bool? isFileDownloaded,
    bool? isFileShared,
    int? fileSize,
    CallMeta? callMeta,
    double? duration,
    List<String>? deletedFor,
    int? expiry,
    double? latitude,
    double? longitude,
    String? address,
    String? locationTitle,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      messageType: messageType ?? this.messageType,
      isDeleted: isDeleted ?? this.isDeleted,
      isDeletedForMe: isDeletedForMe ?? this.isDeletedForMe,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isReply: isReply ?? this.isReply,
      replyMessageId: replyMessageId ?? this.replyMessageId,
      replyMessageBody: replyMessageBody ?? this.replyMessageBody,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      attachmentBytes: attachmentBytes ?? this.attachmentBytes,
      attachmentName: attachmentName ?? this.attachmentName,
      isUploading: isUploading ?? this.isUploading,
      isFailed: isFailed ?? this.isFailed,
      allowShare: allowShare ?? this.allowShare,
      allowDownload: allowDownload ?? this.allowDownload,
      allowView: allowView ?? this.allowView,
      isFileViewed: isFileViewed ?? this.isFileViewed,
      isFileDownloaded: isFileDownloaded ?? this.isFileDownloaded,
      isFileShared: isFileShared ?? this.isFileShared,
      fileSize: fileSize ?? this.fileSize,
      callMeta: callMeta ?? this.callMeta,
      duration: duration ?? this.duration,
      deletedFor: deletedFor ?? this.deletedFor,
      expiry: expiry ?? this.expiry,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      locationTitle: locationTitle ?? this.locationTitle,
    );
  }
}

