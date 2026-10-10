import 'dart:typed_data';
import 'dart:convert';
import 'package:hive/hive.dart';
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

class MessageReaction {
  final String emoji;
  final String userId;
  final String? userName;
  final String? createdAt;

  const MessageReaction({
    required this.emoji,
    required this.userId,
    this.userName,
    this.createdAt,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      emoji: (json['emoji'] ?? json['reaction'] ?? '').toString(),
      userId: (json['userId'] ?? json['user_id'] ?? json['user'] ?? '').toString(),
      userName: (json['userName'] ?? json['user_name'] ?? json['username'] ?? json['displayName'] ?? json['display_name'])?.toString(),
      createdAt: (json['createdAt'] ?? json['created_at'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'emoji': emoji,
    'userId': userId,
    if (userName != null) 'userName': userName,
    if (createdAt != null) 'createdAt': createdAt,
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
  String get status => isRead ? 'read' : (isDelivered ? 'delivered' : 'sent');
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

  // View Once Support
  final bool isViewOnce;
  final int maxViews;
  final bool isViewOnceOpened;

  // Call support
  final CallMeta? callMeta;
  final double? duration;
  final List<String> deletedFor;

  // Message reactions
  final List<MessageReaction> reactions;

  // Disappearing messages
  final int? expiry;

  // Group & sender info
  final String? senderName;
  final String? senderProfilePictureUrl;

  // Contextual role for Parent-to-Child monitoring ("send" | "receive" | "view")
  final String? userView;
  bool get isGuardianView => userView == 'view';

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
    this.isViewOnce = false,
    this.maxViews = 1,
    this.isViewOnceOpened = false,
    this.fileSize,
    this.callMeta,
    this.duration,
    this.deletedFor = const [],
    this.reactions = const [],
    this.expiry,
    this.senderName,
    this.senderProfilePictureUrl,
    this.userView,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    String contentText = '';
    String? mediaUrl;
    final String rawType = (json['type'] ?? json['message_type'] ?? json['messageType'] ?? json['media_type'] ?? json['mediaType'] as String?)?.toLowerCase() ?? 'text';
    String messageType = rawType;
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
      contentText = (contentData['text'] ?? contentData['caption'] ?? '')?.toString() ?? '';
      mediaUrl = (contentData['fileKey'] ?? contentData['file_key'] ?? contentData['url'] ?? contentData['mediaUrl'] ?? contentData['media_url'] ?? contentData['path'] ?? contentData['filePath'] ?? contentData['file_url'] ?? contentData['file'] ?? contentData['document'] ?? contentData['video'] ?? contentData['audio'])?.toString();
      final rawDuration = contentData['duration'] ?? json['duration'];
      if (rawDuration != null) {
        duration = double.tryParse(rawDuration.toString());
      }
    } else if (contentData is String) {
      contentText = contentData;
      mediaUrl = (json['media_url'] ?? json['mediaUrl'] ?? json['url'] ?? json['fileKey'] ?? json['file_key'] ?? json['path'] ?? json['filePath'] ?? json['file_url'] ?? json['file'] ?? json['document'])?.toString();
      final rawDuration = json['duration'];
      if (rawDuration != null) {
        duration = double.tryParse(rawDuration.toString());
      }
    } else {
      mediaUrl = (json['media_url'] ?? json['mediaUrl'] ?? json['url'] ?? json['fileKey'] ?? json['file_key'] ?? json['path'] ?? json['filePath'] ?? json['file_url'] ?? json['file'] ?? json['document'])?.toString();
    }

    if (mediaUrl == null || mediaUrl.isEmpty) {
      // Check nested media object
      final mediaObj = json['media'] ?? json['attachment'];
      if (mediaObj is Map) {
        mediaUrl = (mediaObj['fileKey'] ?? mediaObj['file_key'] ?? mediaObj['url'] ?? mediaObj['mediaUrl'] ?? mediaObj['media_url'] ?? mediaObj['path'] ?? mediaObj['filePath'] ?? mediaObj['key'])?.toString();
      } else if (mediaObj is String && mediaObj.isNotEmpty) {
        mediaUrl = mediaObj;
      }
    }

    if (mediaUrl == null || mediaUrl.isEmpty) {
      final attachmentsList = json['attachments'];
      if (attachmentsList is List && attachmentsList.isNotEmpty && attachmentsList.first is Map) {
        final firstAtt = attachmentsList.first as Map;
        mediaUrl = (firstAtt['fileKey'] ?? firstAtt['file_key'] ?? firstAtt['url'] ?? firstAtt['path'])?.toString();
      }
    }

    if (mediaUrl == null || mediaUrl.isEmpty) {
      mediaUrl = (json['media_url'] ?? json['mediaUrl'] ?? json['url'] ?? json['fileKey'] ?? json['file_key'] ?? json['path'] ?? json['filePath'] ?? json['attachmentPath'] ?? json['mediaPath'] ?? json['file_path'] ?? json['file_url'] ?? json['file'] ?? json['document'] ?? json['s3Url'] ?? json['s3_url'])?.toString();
    }

    if ((mediaUrl == null || mediaUrl.isEmpty) && contentText.isNotEmpty && (messageType == 'image' || messageType == 'video' || messageType == 'file' || messageType == 'audio' || messageType == 'document' || messageType == 'voice')) {
      if (contentText.startsWith('http') || contentText.startsWith('/') || contentText.startsWith('file:') || contentText.contains('.')) {
        mediaUrl = contentText;
      }
    }

    // Auto-detect mediaType if it defaulted to text but mediaUrl/extension is present
    if ((mediaType == 'text' || mediaType == null || mediaType.isEmpty) && mediaUrl != null && mediaUrl.isNotEmpty) {
      final lowerUrl = mediaUrl.toLowerCase().split('?').first;
      if (lowerUrl.endsWith('.mp4') || lowerUrl.endsWith('.mov') || lowerUrl.endsWith('.avi') || lowerUrl.endsWith('.mkv') || lowerUrl.endsWith('.3gp') || lowerUrl.endsWith('.webm')) {
        mediaType = 'video';
        if (messageType == 'text') messageType = 'video';
      } else if (lowerUrl.endsWith('.jpg') || lowerUrl.endsWith('.jpeg') || lowerUrl.endsWith('.png') || lowerUrl.endsWith('.webp') || lowerUrl.endsWith('.gif') || lowerUrl.endsWith('.bmp') || lowerUrl.endsWith('.heic')) {
        mediaType = 'image';
        if (messageType == 'text') messageType = 'image';
      } else if (lowerUrl.endsWith('.mp3') || lowerUrl.endsWith('.m4a') || lowerUrl.endsWith('.wav') || lowerUrl.endsWith('.aac') || lowerUrl.endsWith('.ogg') || lowerUrl.endsWith('.opus')) {
        mediaType = 'audio';
        if (messageType == 'text') messageType = 'audio';
      } else if (lowerUrl.endsWith('.pdf') || lowerUrl.endsWith('.doc') || lowerUrl.endsWith('.docx') || lowerUrl.endsWith('.xls') || lowerUrl.endsWith('.xlsx') || lowerUrl.endsWith('.txt') || lowerUrl.endsWith('.zip') || lowerUrl.endsWith('.csv') || lowerUrl.endsWith('.ppt') || lowerUrl.endsWith('.pptx')) {
        mediaType = 'file';
        if (messageType == 'text') messageType = 'file';
      } else {
        // If mediaUrl exists but extension is unknown, check rawType or default to image
        if (rawType != 'text' && rawType != 'system') {
          mediaType = rawType;
          messageType = rawType;
        } else {
          mediaType = 'image';
          messageType = 'image';
        }
      }
    }

    final dynamic security = json['security'];
    final dynamic viewControl = json['viewControl'] ?? json['view_control'];
    final dynamic perms = json['permissions'];
    
    bool allowShare = true;
    bool allowDownload = true;
    bool allowView = true;
    bool isFileViewed = false;
    bool isFileDownloaded = false;
    bool isFileShared = false;

    if (security is Map) {
      if (security['allowShare'] != null) allowShare = security['allowShare'] == true;
      else if (security['allow_share'] != null) allowShare = security['allow_share'] == true;
      else if (security['canShare'] != null) allowShare = security['canShare'] == true;
      else if (security['can_share'] != null) allowShare = security['can_share'] == true;

      if (security['allowDownload'] != null) allowDownload = security['allowDownload'] == true;
      else if (security['allow_download'] != null) allowDownload = security['allow_download'] == true;
      else if (security['canDownload'] != null) allowDownload = security['canDownload'] == true;
      else if (security['can_download'] != null) allowDownload = security['can_download'] == true;

      if (security['isLocked'] == true || security['is_locked'] == true) {
        allowView = false;
      } else if (security['allowView'] != null) {
        allowView = security['allowView'] == true;
      } else if (security['allow_view'] != null) {
        allowView = security['allow_view'] == true;
      } else if (security['canView'] != null) {
        allowView = security['canView'] == true;
      } else if (security['can_view'] != null) {
        allowView = security['can_view'] == true;
      }

      isFileViewed = (security['isFileViewed'] ?? security['file_viewed'] ?? security['is_file_viewed'] ?? isFileViewed) == true;
      isFileDownloaded = (security['isFileDownloaded'] ?? security['file_downloaded'] ?? security['is_file_downloaded'] ?? isFileDownloaded) == true;
      isFileShared = (security['isFileShared'] ?? security['file_shared'] ?? security['is_file_shared'] ?? isFileShared) == true;
    }

    if (viewControl is Map) {
      if (viewControl['allowShare'] != null) allowShare = viewControl['allowShare'] as bool;
      else if (viewControl['allow_share'] != null) allowShare = viewControl['allow_share'] as bool;
      else if (viewControl['canShare'] != null) allowShare = viewControl['canShare'] as bool;
      else if (viewControl['can_share'] != null) allowShare = viewControl['can_share'] as bool;

      if (viewControl['allowDownload'] != null) allowDownload = viewControl['allowDownload'] as bool;
      else if (viewControl['allow_download'] != null) allowDownload = viewControl['allow_download'] as bool;
      else if (viewControl['canDownload'] != null) allowDownload = viewControl['canDownload'] as bool;
      else if (viewControl['can_download'] != null) allowDownload = viewControl['can_download'] as bool;

      if (viewControl['isLocked'] == true || viewControl['is_locked'] == true) {
        allowView = false;
      } else if (viewControl['allowView'] != null) {
        allowView = viewControl['allowView'] as bool;
      } else if (viewControl['allow_view'] != null) {
        allowView = viewControl['allow_view'] as bool;
      } else if (viewControl['canView'] != null) {
        allowView = viewControl['canView'] as bool;
      } else if (viewControl['can_view'] != null) {
        allowView = viewControl['can_view'] as bool;
      }

      isFileViewed = (viewControl['isFileViewed'] ?? viewControl['file_viewed'] ?? viewControl['is_file_viewed'] ?? isFileViewed) as bool? ?? false;
      isFileDownloaded = (viewControl['isFileDownloaded'] ?? viewControl['file_downloaded'] ?? viewControl['is_file_downloaded'] ?? isFileDownloaded) as bool? ?? false;
      isFileShared = (viewControl['isFileShared'] ?? viewControl['file_shared'] ?? viewControl['is_file_shared'] ?? isFileShared) as bool? ?? false;
    }

    if (perms is Map) {
      if (perms['allowShare'] != null) allowShare = perms['allowShare'] as bool;
      else if (perms['allow_share'] != null) allowShare = perms['allow_share'] as bool;
      else if (perms['canShare'] != null) allowShare = perms['canShare'] as bool;
      else if (perms['can_share'] != null) allowShare = perms['can_share'] as bool;

      if (perms['allowDownload'] != null) allowDownload = perms['allowDownload'] as bool;
      else if (perms['allow_download'] != null) allowDownload = perms['allow_download'] as bool;
      else if (perms['canDownload'] != null) allowDownload = perms['canDownload'] as bool;
      else if (perms['can_download'] != null) allowDownload = perms['can_download'] as bool;

      if (perms['allowView'] != null) allowView = perms['allowView'] as bool;
      else if (perms['allow_view'] != null) allowView = perms['allow_view'] as bool;
      else if (perms['canView'] != null) allowView = perms['canView'] as bool;
      else if (perms['can_view'] != null) allowView = perms['can_view'] as bool;
    }

    if (json['allowShare'] != null) {
      allowShare = json['allowShare'] as bool;
    } else if (json['allow_share'] != null) {
      allowShare = json['allow_share'] as bool;
    } else if (json['canShare'] != null) {
      allowShare = json['canShare'] as bool;
    } else if (json['can_share'] != null) {
      allowShare = json['can_share'] as bool;
    }

    if (json['allowDownload'] != null) {
      allowDownload = json['allowDownload'] as bool;
    } else if (json['allow_download'] != null) {
      allowDownload = json['allow_download'] as bool;
    } else if (json['canDownload'] != null) {
      allowDownload = json['canDownload'] as bool;
    } else if (json['can_download'] != null) {
      allowDownload = json['can_download'] as bool;
    }

    if (json['allowView'] != null) {
      allowView = json['allowView'] as bool;
    } else if (json['allow_view'] != null) {
      allowView = json['allow_view'] as bool;
    } else if (json['canView'] != null) {
      allowView = json['canView'] as bool;
    } else if (json['can_view'] != null) {
      allowView = json['can_view'] as bool;
    }

    if (json['isRevoked'] == true || json['is_revoked'] == true || json['revoked'] == true) {
      allowView = false;
      allowDownload = false;
      allowShare = false;
    }

    if (json['isFileViewed'] != null) {
      isFileViewed = json['isFileViewed'] as bool;
    } else if (json['file_viewed'] != null) isFileViewed = json['file_viewed'] as bool;

    if (json['isFileDownloaded'] != null) {
      isFileDownloaded = json['isFileDownloaded'] as bool;
    } else if (json['file_downloaded'] != null) isFileDownloaded = json['file_downloaded'] as bool;

    if (json['isFileShared'] != null) {
      isFileShared = json['isFileShared'] as bool;
    } else if (json['file_shared'] != null) isFileShared = json['file_shared'] as bool;

    bool isViewOnce = false;
    int maxViews = 1;
    bool isViewOnceOpened = false;

    if (viewControl is Map) {
      final vcType = (viewControl['type'] ?? viewControl['viewType'] ?? '').toString().toLowerCase();
      isViewOnce = vcType == 'once' || viewControl['isViewOnce'] == true || viewControl['is_view_once'] == true;
      maxViews = int.tryParse((viewControl['maxViews'] ?? viewControl['max_views'])?.toString() ?? '') ?? (isViewOnce ? 1 : 1);
      isViewOnceOpened = (viewControl['isOpened'] == true || viewControl['is_opened'] == true || viewControl['openedAt'] != null || viewControl['opened_at'] != null);
    }

    if (json['isViewOnce'] != null) {
      isViewOnce = json['isViewOnce'] as bool;
    } else if (json['is_view_once'] != null) {
      isViewOnce = json['is_view_once'] as bool;
    }

    if (json['maxViews'] != null) {
      maxViews = int.tryParse(json['maxViews'].toString()) ?? maxViews;
    } else if (json['max_views'] != null) {
      maxViews = int.tryParse(json['max_views'].toString()) ?? maxViews;
    }

    if (json['isViewOnceOpened'] != null) {
      isViewOnceOpened = json['isViewOnceOpened'] as bool;
    } else if (json['is_view_once_opened'] != null) {
      isViewOnceOpened = json['is_view_once_opened'] as bool;
    } else if (isViewOnce && isFileViewed) {
      isViewOnceOpened = true;
    }

    if (isViewOnce && !isViewOnceOpened) {
      final msgId = (json['id'] ?? json['_id'] ?? json['message_id'] ?? json['messageId'])?.toString();
      if (msgId != null && Hive.isBoxOpen('opened_view_once_messages')) {
        try {
          final box = Hive.box('opened_view_once_messages');
          if (box.get(msgId) == true) {
            isViewOnceOpened = true;
            isFileViewed = true;
          }
        } catch (_) {}
      }
    }

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

    String? parsedSenderName = (json['senderName'] ?? json['sender_name'] ?? json['sender_username'] ?? json['senderUsername'])?.toString();
    String? parsedSenderProfilePic = (json['senderProfilePictureUrl'] ?? json['sender_profile_picture_url'] ?? json['senderProfilePic'] ?? json['sender_profile_pic'] ?? json['profile_picture_url'] ?? json['profilePictureUrl'])?.toString();
    if (parsedSenderName == null || parsedSenderName.isEmpty || parsedSenderProfilePic == null || parsedSenderProfilePic.isEmpty) {
      final senderObj = json['sender'] ?? json['sender_details'] ?? json['user'] ?? json['sender_user'];
      if (senderObj is Map) {
        if (parsedSenderName == null || parsedSenderName.isEmpty) {
          parsedSenderName = (senderObj['name'] ?? senderObj['username'] ?? senderObj['display_name'] ?? senderObj['contactName'] ?? senderObj['first_name'] ?? senderObj['phone_number'] ?? senderObj['phoneNumber'])?.toString();
        }
        if (parsedSenderProfilePic == null || parsedSenderProfilePic.isEmpty) {
          parsedSenderProfilePic = (senderObj['profile_picture_url'] ?? senderObj['profilePictureUrl'] ?? senderObj['avatar'] ?? senderObj['image_url'])?.toString();
        }
      }
    }

    final List<MessageReaction> reactionsList = [];
    final dynamic rawReactions = json['reactions'] ?? json['reaction_list'] ?? json['message_reactions'];
    if (rawReactions is List) {
      for (var r in rawReactions) {
        if (r is Map) {
          reactionsList.add(MessageReaction.fromJson(Map<String, dynamic>.from(r)));
        } else if (r is String && r.isNotEmpty) {
          reactionsList.add(MessageReaction(emoji: r, userId: ''));
        }
      }
    } else if (rawReactions is Map) {
      rawReactions.forEach((key, val) {
        if (val is List) {
          for (var u in val) {
            reactionsList.add(MessageReaction(
              emoji: key.toString(),
              userId: u is Map ? (u['userId'] ?? u['user_id'] ?? '').toString() : u.toString(),
            ));
          }
        } else {
          reactionsList.add(MessageReaction.fromJson(Map<String, dynamic>.from(rawReactions)));
        }
      });
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
      isViewOnce: isViewOnce,
      maxViews: maxViews,
      isViewOnceOpened: isViewOnceOpened,
      fileSize: fileSize,
      callMeta: callMeta,
      duration: duration,
      deletedFor: deletedForList,
      reactions: reactionsList,
      senderName: parsedSenderName,
      senderProfilePictureUrl: parsedSenderProfilePic,
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
      userView: (json['userView'] ?? json['user_view'])?.toString(),
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
    'mediaUrl': mediaUrl,
    'media_url': mediaUrl,
    'fileKey': mediaUrl,
    'file_key': mediaUrl,
    'mediaType': mediaType,
    'media_type': mediaType,
    'messageType': messageType,
    'type': (mediaType != null && mediaType!.isNotEmpty && mediaType != 'text') ? mediaType : (messageType != 'text' ? messageType : 'text'),
    'isDeleted': isDeleted,
    'isDeletedForMe': isDeletedForMe,
    'isRead': isRead,
    'isDelivered': isDelivered,
    'status': isRead ? 'read' : (isDelivered ? 'delivered' : 'sent'),
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
    'duration': duration,
    'isFailed': isFailed,
    'isFileViewed': isFileViewed,
    'isFileDownloaded': isFileDownloaded,
    'isFileShared': isFileShared,
    'isViewOnce': isViewOnce,
    'maxViews': maxViews,
    'isViewOnceOpened': isViewOnceOpened,
    'allowShare': allowShare,
    'allowDownload': allowDownload,
    'allowView': allowView,
    'security': {
      'allowShare': allowShare,
      'allowDownload': allowDownload,
      'allowView': allowView,
      'isFileViewed': isFileViewed,
      'isFileDownloaded': isFileDownloaded,
      'isFileShared': isFileShared,
    },
    'viewControl': {
      'type': isViewOnce ? 'once' : 'normal',
      'maxViews': maxViews,
      'isOpened': isViewOnceOpened,
      'allowShare': allowShare,
      'allowDownload': allowDownload,
      'allowView': allowView,
      'isFileViewed': isFileViewed,
      'isFileDownloaded': isFileDownloaded,
      'isFileShared': isFileShared,
    },
    'deletedFor': deletedFor,
    'reactions': reactions.map((r) => r.toJson()).toList(),
    if (userView != null) 'userView': userView,
    if (callMeta != null) 'callMeta': callMeta!.toJson(),
    if (expiry != null) 'expiry': expiry,
    if (senderName != null) 'senderName': senderName,
    if (senderProfilePictureUrl != null) 'senderProfilePictureUrl': senderProfilePictureUrl,
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
    bool? isViewOnce,
    int? maxViews,
    bool? isViewOnceOpened,
    int? fileSize,
    CallMeta? callMeta,
    double? duration,
    List<String>? deletedFor,
    List<MessageReaction>? reactions,
    int? expiry,
    String? senderName,
    String? senderProfilePictureUrl,
    double? latitude,
    double? longitude,
    String? address,
    String? locationTitle,
    String? userView,
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
      isViewOnce: isViewOnce ?? this.isViewOnce,
      maxViews: maxViews ?? this.maxViews,
      isViewOnceOpened: isViewOnceOpened ?? this.isViewOnceOpened,
      fileSize: fileSize ?? this.fileSize,
      callMeta: callMeta ?? this.callMeta,
      duration: duration ?? this.duration,
      deletedFor: deletedFor ?? this.deletedFor,
      reactions: reactions ?? this.reactions,
      expiry: expiry ?? this.expiry,
      senderName: senderName ?? this.senderName,
      senderProfilePictureUrl: senderProfilePictureUrl ?? this.senderProfilePictureUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      locationTitle: locationTitle ?? this.locationTitle,
      userView: userView ?? this.userView,
    );
  }
}

