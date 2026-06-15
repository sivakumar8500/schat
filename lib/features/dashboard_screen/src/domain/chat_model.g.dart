// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatModel _$ChatModelFromJson(Map<String, dynamic> json) => _ChatModel(
  id: json['id'] as String,
  isGroup: json['is_group'] as bool,
  groupName: json['group_name'] as String?,
  groupDescription: json['group_description'] as String?,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
  recipient: RecipientModel.fromJson(json['recipient'] as Map<String, dynamic>),
  lastMessage: json['last_message'] == null
      ? null
      : LastMessageModel.fromJson(json['last_message'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ChatModelToJson(_ChatModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'is_group': instance.isGroup,
      'group_name': instance.groupName,
      'group_description': instance.groupDescription,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'recipient': instance.recipient,
      'last_message': instance.lastMessage,
    };
