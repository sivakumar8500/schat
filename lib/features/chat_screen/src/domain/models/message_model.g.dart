// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MessageModel _$MessageModelFromJson(Map<String, dynamic> json) =>
    _MessageModel(
      id: json['id'] as String,
      text: json['text'] as String,
      time: json['time'] as String,
      isMe: json['isMe'] as bool,
      isRead: json['isRead'] as bool? ?? false,
      type: json['type'] as String? ?? 'text',
      attachmentPath: json['attachmentPath'] as String?,
      attachmentName: json['attachmentName'] as String?,
    );

Map<String, dynamic> _$MessageModelToJson(_MessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'time': instance.time,
      'isMe': instance.isMe,
      'isRead': instance.isRead,
      'type': instance.type,
      'attachmentPath': instance.attachmentPath,
      'attachmentName': instance.attachmentName,
    };
