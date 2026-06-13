// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MessageModel _$MessageModelFromJson(Map<String, dynamic> json) =>
    _MessageModel(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      type: json['type'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      content: MessageContent.fromJson(json['content'] as Map<String, dynamic>),
      security: MessageSecurity.fromJson(
        json['security'] as Map<String, dynamic>,
      ),
      viewControl: MessageViewControl.fromJson(
        json['viewControl'] as Map<String, dynamic>,
      ),
      expiry: MessageExpiry.fromJson(json['expiry'] as Map<String, dynamic>),
      callMeta: json['callMeta'] == null
          ? null
          : MessageCallMeta.fromJson(json['callMeta'] as Map<String, dynamic>),
      deletedFor:
          (json['deletedFor'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isDeletedForEveryone: json['isDeletedForEveryone'] as bool? ?? false,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$MessageModelToJson(_MessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'chatId': instance.chatId,
      'type': instance.type,
      'senderId': instance.senderId,
      'receiverId': instance.receiverId,
      'content': instance.content,
      'security': instance.security,
      'viewControl': instance.viewControl,
      'expiry': instance.expiry,
      'callMeta': instance.callMeta,
      'deletedFor': instance.deletedFor,
      'isDeletedForEveryone': instance.isDeletedForEveryone,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

_MessageContent _$MessageContentFromJson(Map<String, dynamic> json) =>
    _MessageContent(
      text: json['text'] as String?,
      fileUrl: json['fileUrl'] as String?,
      thumbnail: json['thumbnail'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      mimeType: json['mimeType'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MessageContentToJson(_MessageContent instance) =>
    <String, dynamic>{
      'text': instance.text,
      'fileUrl': instance.fileUrl,
      'thumbnail': instance.thumbnail,
      'fileName': instance.fileName,
      'fileSize': instance.fileSize,
      'mimeType': instance.mimeType,
      'duration': instance.duration,
    };

_MessageSecurity _$MessageSecurityFromJson(Map<String, dynamic> json) =>
    _MessageSecurity(
      isLocked: json['isLocked'] as bool,
      accessUsers: (json['accessUsers'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      allowDownload: json['allowDownload'] as bool,
      allowShare: json['allowShare'] as bool,
    );

Map<String, dynamic> _$MessageSecurityToJson(_MessageSecurity instance) =>
    <String, dynamic>{
      'isLocked': instance.isLocked,
      'accessUsers': instance.accessUsers,
      'allowDownload': instance.allowDownload,
      'allowShare': instance.allowShare,
    };

_MessageViewControl _$MessageViewControlFromJson(Map<String, dynamic> json) =>
    _MessageViewControl(
      type: json['type'] as String,
      maxViews: (json['maxViews'] as num).toInt(),
      viewedBy: (json['viewedBy'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isOpened: json['isOpened'] as bool,
      openedAt: (json['openedAt'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MessageViewControlToJson(_MessageViewControl instance) =>
    <String, dynamic>{
      'type': instance.type,
      'maxViews': instance.maxViews,
      'viewedBy': instance.viewedBy,
      'isOpened': instance.isOpened,
      'openedAt': instance.openedAt,
    };

_MessageExpiry _$MessageExpiryFromJson(Map<String, dynamic> json) =>
    _MessageExpiry(
      isEnabled: json['isEnabled'] as bool,
      expireAt: (json['expireAt'] as num).toInt(),
    );

Map<String, dynamic> _$MessageExpiryToJson(_MessageExpiry instance) =>
    <String, dynamic>{
      'isEnabled': instance.isEnabled,
      'expireAt': instance.expireAt,
    };

_MessageCallMeta _$MessageCallMetaFromJson(Map<String, dynamic> json) =>
    _MessageCallMeta(
      callType: json['callType'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      status: json['status'] as String?,
    );

Map<String, dynamic> _$MessageCallMetaToJson(_MessageCallMeta instance) =>
    <String, dynamic>{
      'callType': instance.callType,
      'duration': instance.duration,
      'status': instance.status,
    };
