// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CallHistoryModel _$CallHistoryModelFromJson(Map<String, dynamic> json) =>
    _CallHistoryModel(
      id: json['_id'] as String? ?? '',
      callerId: json['caller_id'] as String?,
      callerName: json['caller_name'] as String?,
      callerAvatar: json['caller_avatar'] as String?,
      receiverId: json['receiver_id'] as String?,
      receiverName: json['receiver_name'] as String?,
      receiverAvatar: json['receiver_avatar'] as String?,
      callType: json['call_type'] as String? ?? 'audio',
      status: json['status'] as String? ?? 'completed',
      direction: json['direction'] as String? ?? 'incoming',
      createdAt: json['created_at'] as String?,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$CallHistoryModelToJson(_CallHistoryModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'caller_id': instance.callerId,
      'caller_name': instance.callerName,
      'caller_avatar': instance.callerAvatar,
      'receiver_id': instance.receiverId,
      'receiver_name': instance.receiverName,
      'receiver_avatar': instance.receiverAvatar,
      'call_type': instance.callType,
      'status': instance.status,
      'direction': instance.direction,
      'created_at': instance.createdAt,
      'duration': instance.duration,
      'count': instance.count,
    };
