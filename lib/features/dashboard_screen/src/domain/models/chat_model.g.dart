// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatModel _$ChatModelFromJson(Map<String, dynamic> json) => _ChatModel(
  id: json['_id'] as String? ?? '',
  isGroup: json['is_group'] as bool? ?? false,
  groupName: json['group_name'] as String?,
  groupDescription: json['group_description'] as String?,
  createdAt: json['created_at'] as String? ?? '',
  updatedAt: json['updated_at'] as String? ?? '',
  recipient: RecipientModel.fromJson(json['recipient'] as Map<String, dynamic>),
  lastMessage: json['last_message'] == null
      ? null
      : LastMessageModel.fromJson(json['last_message'] as Map<String, dynamic>),
  unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
  isHidden: json['isHidden'] as bool? ?? false,
  isHided: json['isHided'] as bool? ?? false,
  isMuted: json['is_muted'] as bool? ?? false,
  isFavorite: json['is_favorite'] as bool? ?? false,
  themeColor: json['themeColor'] == null
      ? null
      : ThemeColorModel.fromJson(json['themeColor'] as Map<String, dynamic>),
  disappearingTimer: (json['disappearing_timer'] as num?)?.toInt(),
);

Map<String, dynamic> _$ChatModelToJson(_ChatModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'is_group': instance.isGroup,
      'group_name': instance.groupName,
      'group_description': instance.groupDescription,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'recipient': instance.recipient,
      'last_message': instance.lastMessage,
      'unread_count': instance.unreadCount,
      'isHidden': instance.isHidden,
      'isHided': instance.isHided,
      'is_muted': instance.isMuted,
      'is_favorite': instance.isFavorite,
      'themeColor': instance.themeColor,
      'disappearing_timer': instance.disappearingTimer,
    };
