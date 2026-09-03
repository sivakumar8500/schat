import 'package:freezed_annotation/freezed_annotation.dart';

part 'call_history.freezed.dart';
part 'call_history.g.dart';

@freezed
abstract class CallHistoryModel with _$CallHistoryModel {
  const CallHistoryModel._();

  const factory CallHistoryModel({
    @JsonKey(name: '_id') @Default('') String id,
    @JsonKey(name: 'caller_id') String? callerId,
    @JsonKey(name: 'caller_name') String? callerName,
    @JsonKey(name: 'caller_avatar') String? callerAvatar,
    @JsonKey(name: 'receiver_id') String? receiverId,
    @JsonKey(name: 'receiver_name') String? receiverName,
    @JsonKey(name: 'receiver_avatar') String? receiverAvatar,
    @JsonKey(name: 'call_type') @Default('audio') String callType,
    @JsonKey(name: 'status') @Default('completed') String status,
    @JsonKey(name: 'direction') @Default('incoming') String direction,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'duration') @Default(0) int duration,
    @JsonKey(name: 'count') @Default(1) int count,
  }) = _CallHistoryModel;

  bool get isIncoming => direction.toLowerCase() == 'incoming';
  bool get isMissed =>
      status.toLowerCase() == 'missed' ||
      status.toLowerCase() == 'no_answer' ||
      status.toLowerCase() == 'rejected';
  bool get isVideoCall => callType.toLowerCase() == 'video';

  String get displayName {
    if (callerName != null && callerName!.isNotEmpty) {
      return callerName!;
    }
    if (receiverName != null && receiverName!.isNotEmpty) {
      return receiverName!;
    }
    return callerId ?? receiverId ?? 'Unknown User';
  }

  String? get displayAvatar {
    if (callerAvatar != null && callerAvatar!.isNotEmpty) {
      return callerAvatar;
    }
    if (receiverAvatar != null && receiverAvatar!.isNotEmpty) {
      return receiverAvatar;
    }
    return null;
  }

  factory CallHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$CallHistoryModelFromJson(_normalizeCallHistoryJson(json));
}

Map<String, dynamic> _normalizeCallHistoryJson(Map<String, dynamic> json) {
  final normalized = Map<String, dynamic>.from(json);
  normalized['_id'] = (json['id'] ?? json['_id'] ?? json['call_id'] ?? json['message_id'])?.toString() ?? '';
  normalized['caller_id'] = (json['caller_id'] ?? json['callerId'] ?? json['from_user_id'] ?? json['sender_id'] ?? json['senderId'])?.toString();
  
  // Extract participant name/avatar
  final otherParticipant = json['otherParticipant'] ?? json['other_participant'];
  String? participantName;
  String? participantAvatar;
  if (otherParticipant != null && otherParticipant is Map) {
    participantName = otherParticipant['username']?.toString();
    if (participantName == null || participantName.isEmpty) {
      participantName = otherParticipant['contactName']?.toString();
    }
    if (participantName == null || participantName.isEmpty) {
      participantName = otherParticipant['first_name']?.toString();
    }
    participantAvatar = otherParticipant['profile_picture_url']?.toString();
  }
  
  // Ensure we fallback to participantName if the primary keys are null
  final resolvedCallerName = json['caller_name'] ?? json['callerName'] ?? json['sender_name'] ?? json['from_user_name'] ?? json['name'];
  normalized['caller_name'] = (resolvedCallerName ?? participantName)?.toString();
  
  final resolvedCallerAvatar = json['caller_avatar'] ?? json['callerAvatar'] ?? json['sender_avatar'];
  normalized['caller_avatar'] = (resolvedCallerAvatar ?? participantAvatar)?.toString();
  
  normalized['receiver_id'] = (json['receiver_id'] ?? json['receiverId'] ?? json['to_user_id'] ?? json['recipient_id'])?.toString();
  
  final resolvedReceiverName = json['receiver_name'] ?? json['receiverName'] ?? json['recipient_name'] ?? json['to_user_name'];
  normalized['receiver_name'] = (resolvedReceiverName ?? participantName)?.toString();
  
  final resolvedReceiverAvatar = json['receiver_avatar'] ?? json['receiverAvatar'] ?? json['recipient_avatar'];
  normalized['receiver_avatar'] = (resolvedReceiverAvatar ?? participantAvatar)?.toString();
  
  normalized['call_type'] = (json['call_type'] ?? json['callType'] ?? json['type'] ?? json['media_type'])?.toString() ?? 'audio';
  normalized['status'] = (json['status'] ?? json['call_status'] ?? json['callStatus'])?.toString() ?? 'completed';
  normalized['direction'] = (json['direction'] ?? json['call_direction'])?.toString() ??
      ((json['is_incoming'] == true || json['isIncoming'] == true) ? 'incoming' : 'outgoing');
      
  final createdAtRaw = json['created_at'] ?? json['createdAt'] ?? json['timestamp'] ?? json['started_at'] ?? json['time'];
  if (createdAtRaw is int) {
    // Unix timestamp in seconds
    normalized['created_at'] = DateTime.fromMillisecondsSinceEpoch(createdAtRaw * 1000).toIso8601String();
  } else {
    normalized['created_at'] = createdAtRaw?.toString();
  }
  
  normalized['duration'] = json['duration'] is int ? json['duration'] : (int.tryParse(json['duration']?.toString() ?? '') ?? 0);
  return normalized;
}

