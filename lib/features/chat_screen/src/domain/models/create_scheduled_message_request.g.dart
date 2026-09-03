// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_scheduled_message_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CreateScheduledMessageRequest _$CreateScheduledMessageRequestFromJson(
  Map<String, dynamic> json,
) => _CreateScheduledMessageRequest(
  conversationId: json['conversationId'] as String,
  messageType: json['messageType'] as String? ?? 'text',
  parentMessageId: json['parentMessageId'] as String?,
  content: json['content'] as Map<String, dynamic>? ?? const {},
  security: json['security'] as Map<String, dynamic>? ?? const {},
  viewControl: json['viewControl'] as Map<String, dynamic>? ?? const {},
  expiry: json['expiry'] as Map<String, dynamic>? ?? const {},
  callMeta: json['callMeta'] as Map<String, dynamic>?,
  scheduledAt: json['scheduledAt'] as String,
);

Map<String, dynamic> _$CreateScheduledMessageRequestToJson(
  _CreateScheduledMessageRequest instance,
) => <String, dynamic>{
  'conversationId': instance.conversationId,
  'messageType': instance.messageType,
  'parentMessageId': instance.parentMessageId,
  'content': instance.content,
  'security': instance.security,
  'viewControl': instance.viewControl,
  'expiry': instance.expiry,
  'callMeta': instance.callMeta,
  'scheduledAt': instance.scheduledAt,
};
