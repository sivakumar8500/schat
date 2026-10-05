import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/injection.dart';

part 'call_history.freezed.dart';
part 'call_history.g.dart';

@freezed
abstract class CallHistoryModel with _$CallHistoryModel {
  const CallHistoryModel._();

  const factory CallHistoryModel({
    @JsonKey(name: '_id') @Default('') String id,
    @JsonKey(name: 'conversation_id') String? conversationId,
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
    @JsonKey(name: 'is_group') @Default(false) bool isGroup,
    @JsonKey(name: 'group_name') String? groupName,
    @JsonKey(name: 'group_picture_url') String? groupPictureUrl,
  }) = _CallHistoryModel;

  bool get isIncoming => direction.toLowerCase() == 'incoming';
  bool get isMissed {
    final s = status.toLowerCase();
    return s == 'missed' ||
        s == 'no_answer' ||
        s == 'noanswer' ||
        s == 'rejected' ||
        s == 'reject' ||
        s == 'busy' ||
        s == 'decline' ||
        s == 'declined' ||
        s == 'cancelled' ||
        s == 'canceled';
  }
  bool get isVideoCall => callType.toLowerCase() == 'video';

  String get displayName {
    if ((isGroup || (groupName != null && groupName!.isNotEmpty)) &&
        groupName != null &&
        groupName!.isNotEmpty) {
      return groupName!;
    }
    if (isIncoming) {
      if (callerName != null && callerName!.isNotEmpty) return callerName!;
      if (receiverName != null && receiverName!.isNotEmpty) return receiverName!;
      return (callerId != null && callerId!.isNotEmpty) ? callerId! : ((receiverId != null && receiverId!.isNotEmpty) ? receiverId! : 'Unknown User');
    } else {
      if (receiverName != null && receiverName!.isNotEmpty) return receiverName!;
      if (callerName != null && callerName!.isNotEmpty) return callerName!;
      return (receiverId != null && receiverId!.isNotEmpty) ? receiverId! : ((callerId != null && callerId!.isNotEmpty) ? callerId! : 'Unknown User');
    }
  }

  String? get displayAvatar {
    if ((isGroup || (groupPictureUrl != null && groupPictureUrl!.isNotEmpty)) &&
        groupPictureUrl != null &&
        groupPictureUrl!.isNotEmpty) {
      return groupPictureUrl;
    }
    if (isIncoming) {
      if (callerAvatar != null && callerAvatar!.isNotEmpty) return callerAvatar;
      if (receiverAvatar != null && receiverAvatar!.isNotEmpty) return receiverAvatar;
    } else {
      if (receiverAvatar != null && receiverAvatar!.isNotEmpty) return receiverAvatar;
      if (callerAvatar != null && callerAvatar!.isNotEmpty) return callerAvatar;
    }
    if (groupPictureUrl != null && groupPictureUrl!.isNotEmpty) {
      return groupPictureUrl;
    }
    return null;
  }

  factory CallHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$CallHistoryModelFromJson(_normalizeCallHistoryJson(json));
}

Map<String, dynamic> _normalizeCallHistoryJson(Map<String, dynamic> json) {
  final normalized = Map<String, dynamic>.from(json);
  normalized['_id'] = (json['id'] ?? json['_id'] ?? json['call_id'] ?? json['message_id'] ?? json['messageId'])?.toString() ?? '';
  normalized['conversation_id'] = (json['conversation_id'] ?? json['conversationId'])?.toString();
  
  // Group fields
  final isGroupVal = json['is_group'] ?? json['isGroup'];
  normalized['is_group'] = (isGroupVal == true || isGroupVal == 1 || isGroupVal == 'true');
  normalized['group_name'] = (json['group_name'] ?? json['groupName'])?.toString();
  normalized['group_picture_url'] = (json['group_picture_url'] ?? json['groupPictureUrl'])?.toString();

  // Extract participant name/avatar/id/phone
  final otherParticipant = json['otherParticipant'] ?? json['other_participant'] ?? json['recipient'] ?? json['recipient_details'] ?? json['receiver'];
  String? participantName;
  String? participantAvatar;
  String? participantId;
  if (otherParticipant != null && otherParticipant is Map) {
    participantName = (otherParticipant['contactName'] ?? otherParticipant['contact_name'])?.toString();
    if (participantName == null || participantName.isEmpty) {
      participantName = otherParticipant['name']?.toString();
    }
    if (participantName == null || participantName.isEmpty) {
      participantName = otherParticipant['username']?.toString();
    }
    if (participantName == null || participantName.isEmpty) {
      participantName = otherParticipant['first_name']?.toString();
    }
    if (participantName == null || participantName.isEmpty) {
      participantName = (otherParticipant['phone_number'] ?? otherParticipant['phoneNumber'])?.toString();
    }
    participantAvatar = (otherParticipant['profile_picture_url'] ?? otherParticipant['profilePictureUrl'] ?? otherParticipant['avatar'])?.toString();
    participantId = otherParticipant['id']?.toString();
  }

  // Determine direction
  String? direction = (json['direction'] ?? json['call_direction'])?.toString();
  if (direction == null || direction.isEmpty) {
    if (json['is_incoming'] == true || json['isIncoming'] == true) {
      direction = 'incoming';
    } else if (json['is_outgoing'] == true || json['isOutgoing'] == true) {
      direction = 'outgoing';
    } else {
      try {
        final myId = getIt<StorageService>().getUserId()?.toString();
        final senderId = (json['senderId'] ?? json['sender_id'] ?? json['caller_id'] ?? json['callerId'])?.toString();
        if (senderId != null && myId != null && senderId.isNotEmpty && myId.isNotEmpty) {
          direction = (senderId == myId) ? 'outgoing' : 'incoming';
        }
      } catch (_) {}
    }
  }
  normalized['direction'] = direction ?? 'incoming';
  final bool isOutgoing = normalized['direction'] == 'outgoing';

  if (isOutgoing) {
    // Outgoing call: current user is caller, otherParticipant is receiver
    final resolvedCallerName = json['caller_name'] ?? json['callerName'] ?? json['sender_name'] ?? json['from_user_name'];
    normalized['caller_name'] = resolvedCallerName?.toString();
    normalized['caller_avatar'] = (json['caller_avatar'] ?? json['callerAvatar'] ?? json['sender_avatar'])?.toString();
    normalized['caller_id'] = (json['caller_id'] ?? json['callerId'] ?? json['sender_id'] ?? json['senderId'])?.toString();

    final resolvedReceiverName = json['receiver_name'] ?? json['receiverName'] ?? json['recipient_name'] ?? json['to_user_name'] ?? participantName;
    normalized['receiver_name'] = (resolvedReceiverName ?? participantName)?.toString();
    normalized['receiver_avatar'] = (json['receiver_avatar'] ?? json['receiverAvatar'] ?? json['recipient_avatar'] ?? participantAvatar)?.toString();
    normalized['receiver_id'] = (json['receiver_id'] ?? json['receiverId'] ?? json['to_user_id'] ?? json['recipient_id'] ?? participantId)?.toString();
  } else {
    // Incoming call: otherParticipant is caller, current user is receiver
    final resolvedCallerName = json['caller_name'] ?? json['callerName'] ?? json['sender_name'] ?? json['from_user_name'] ?? json['name'] ?? participantName;
    normalized['caller_name'] = (resolvedCallerName ?? participantName)?.toString();
    normalized['caller_avatar'] = (json['caller_avatar'] ?? json['callerAvatar'] ?? json['sender_avatar'] ?? participantAvatar)?.toString();
    normalized['caller_id'] = (json['caller_id'] ?? json['callerId'] ?? json['from_user_id'] ?? json['sender_id'] ?? json['senderId'] ?? participantId)?.toString();

    final resolvedReceiverName = json['receiver_name'] ?? json['receiverName'] ?? json['recipient_name'] ?? json['to_user_name'];
    normalized['receiver_name'] = resolvedReceiverName?.toString();
    normalized['receiver_avatar'] = (json['receiver_avatar'] ?? json['receiverAvatar'] ?? json['recipient_avatar'])?.toString();
    normalized['receiver_id'] = (json['receiver_id'] ?? json['receiverId'] ?? json['to_user_id'] ?? json['recipient_id'])?.toString();
  }
  
  // Call type & status
  dynamic rawCallMeta = json['callMeta'] ?? json['call_meta'];
  String? metaCallType;
  String? metaStatus;
  int? metaDuration;
  if (rawCallMeta is Map) {
    metaCallType = (rawCallMeta['callType'] ?? rawCallMeta['call_type'])?.toString();
    metaStatus = rawCallMeta['status']?.toString();
    metaDuration = int.tryParse((rawCallMeta['duration'] ?? rawCallMeta['duration_seconds'])?.toString() ?? '');
  }

  normalized['call_type'] = (metaCallType ?? json['call_type'] ?? json['callType'] ?? json['type'] ?? json['media_type'])?.toString() ?? 'audio';
  normalized['status'] = (metaStatus ?? json['status'] ?? json['call_status'] ?? json['callStatus'])?.toString() ?? 'completed';
      
  final createdAtRaw = json['created_at'] ?? json['createdAt'] ?? json['timestamp'] ?? json['started_at'] ?? json['time'];
  if (createdAtRaw is int) {
    // Unix timestamp in seconds
    normalized['created_at'] = DateTime.fromMillisecondsSinceEpoch(createdAtRaw * 1000).toIso8601String();
  } else if (createdAtRaw is num) {
    normalized['created_at'] = DateTime.fromMillisecondsSinceEpoch((createdAtRaw * 1000).toInt()).toIso8601String();
  } else {
    normalized['created_at'] = createdAtRaw?.toString();
  }
  
  final rawDur = metaDuration ?? json['duration'];
  normalized['duration'] = rawDur is int ? rawDur : (int.tryParse(rawDur?.toString() ?? '') ?? 0);
  return normalized;
}

