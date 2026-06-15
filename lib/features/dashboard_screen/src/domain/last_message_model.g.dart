// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'last_message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LastMessageModel _$LastMessageModelFromJson(Map<String, dynamic> json) =>
    _LastMessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      mediaUrl: json['media_url'] as String?,
      mediaType: json['media_type'] as String?,
      isDeleted: json['is_deleted'] as bool,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$LastMessageModelToJson(_LastMessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversation_id': instance.conversationId,
      'sender_id': instance.senderId,
      'content': instance.content,
      'media_url': instance.mediaUrl,
      'media_type': instance.mediaType,
      'is_deleted': instance.isDeleted,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
