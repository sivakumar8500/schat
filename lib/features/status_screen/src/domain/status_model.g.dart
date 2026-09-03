// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StatusItemModel _$StatusItemModelFromJson(Map<String, dynamic> json) =>
    _StatusItemModel(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      statusType: json['statusType'] as String?,
      text: json['textContent'] as String?,
      imagePath: json['mediaUrl'] as String?,
      timestamp: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      viewers:
          (json['viewers'] as List<dynamic>?)
              ?.map(
                (e) => StatusViewerModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      privacyType: json['privacyType'] as String?,
      privacyUserIds: (json['privacyUserIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$StatusItemModelToJson(_StatusItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'statusType': instance.statusType,
      'textContent': instance.text,
      'mediaUrl': instance.imagePath,
      'createdAt': instance.timestamp.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'viewCount': instance.viewCount,
      'viewers': instance.viewers,
      'privacyType': instance.privacyType,
      'privacyUserIds': instance.privacyUserIds,
    };

_StatusViewerModel _$StatusViewerModelFromJson(Map<String, dynamic> json) =>
    _StatusViewerModel(
      viewerId: json['viewerId'] as String,
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      viewedAt: (json['viewedAt'] as num?)?.toInt(),
    );

Map<String, dynamic> _$StatusViewerModelToJson(_StatusViewerModel instance) =>
    <String, dynamic>{
      'viewerId': instance.viewerId,
      'username': instance.username,
      'displayName': instance.displayName,
      'viewedAt': instance.viewedAt,
    };

_StatusContactModel _$StatusContactModelFromJson(Map<String, dynamic> json) =>
    _StatusContactModel(
      contactId: json['userId'] as String,
      name: json['displayName'] as String? ?? 'User',
      username: json['username'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      statuses:
          (json['statuses'] as List<dynamic>?)
              ?.map((e) => StatusItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$StatusContactModelToJson(_StatusContactModel instance) =>
    <String, dynamic>{
      'userId': instance.contactId,
      'displayName': instance.name,
      'username': instance.username,
      'profilePictureUrl': instance.profilePictureUrl,
      'statuses': instance.statuses,
    };
