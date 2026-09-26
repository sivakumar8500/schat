import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';

abstract class CallWebRtcState {
  const CallWebRtcState();
}

class CallIdle extends CallWebRtcState {
  const CallIdle();
}

class CallConnecting extends CallWebRtcState {
  final String conversationId;
  final bool isVideo;
  final String contactName;
  final String recipientId;
  final bool isMinimized;
  final bool isSystemPip;
  final String? profilePictureUrl;
  final bool isSpeakerOn;
  final bool isFrontCamera;
  final List<UserModel> extraParticipants;

  const CallConnecting({
    required this.conversationId,
    required this.isVideo,
    required this.contactName,
    this.recipientId = '',
    this.isMinimized = false,
    this.isSystemPip = false,
    this.profilePictureUrl,
    bool? isSpeakerOn,
    this.isFrontCamera = true,
    this.extraParticipants = const [],
  }) : isSpeakerOn = isSpeakerOn ?? isVideo;

  CallConnecting copyWith({
    String? contactName,
    String? recipientId,
    bool? isMinimized,
    bool? isSystemPip,
    String? profilePictureUrl,
    bool? isSpeakerOn,
    bool? isFrontCamera,
    List<UserModel>? extraParticipants,
  }) {
    return CallConnecting(
      conversationId: conversationId,
      isVideo: isVideo,
      contactName: contactName ?? this.contactName,
      recipientId: recipientId ?? this.recipientId,
      isMinimized: isMinimized ?? this.isMinimized,
      isSystemPip: isSystemPip ?? this.isSystemPip,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      extraParticipants: extraParticipants ?? this.extraParticipants,
    );
  }
}

/// Callee sees this — ringing/incoming call
class CallRinging extends CallWebRtcState {
  final Map<String, dynamic> incomingEvent;
  final String callerName;
  final String recipientId;
  final bool isVideo;
  final String? profilePictureUrl;
  final bool isSpeakerOn;
  final bool isFrontCamera;
  final List<UserModel> extraParticipants;

  const CallRinging({
    required this.incomingEvent,
    required this.callerName,
    required this.recipientId,
    required this.isVideo,
    this.profilePictureUrl,
    bool? isSpeakerOn,
    this.isFrontCamera = true,
    this.extraParticipants = const [],
  }) : isSpeakerOn = isSpeakerOn ?? isVideo;
  
  CallRinging copyWith({
    bool? isSpeakerOn,
    bool? isFrontCamera,
    List<UserModel>? extraParticipants,
  }) {
    return CallRinging(
      incomingEvent: incomingEvent,
      callerName: callerName,
      recipientId: recipientId,
      isVideo: isVideo,
      profilePictureUrl: profilePictureUrl,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      extraParticipants: extraParticipants ?? this.extraParticipants,
    );
  }
}

class CallActive extends CallWebRtcState {
  final String conversationId;
  final String contactName;
  final String recipientId;
  final bool isVideo;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isVideoOff;
  final bool isRemoteVideoOff;
  final bool isRemoteMuted;
  final bool isFrontCamera;
  final bool isMinimized;
  final bool isSystemPip;
  final String? profilePictureUrl;
  final DateTime? startedAt;
  final String? switchRequestedCallType;
  final Map<String, dynamic>? switchRequestedEvent;
  final List<UserModel> extraParticipants;

  const CallActive({
    required this.conversationId,
    required this.contactName,
    required this.recipientId,
    required this.isVideo,
    this.isMuted = false,
    this.isVideoOff = false,
    this.isFrontCamera = true,
    this.isRemoteMuted = false,
    this.isRemoteVideoOff = false,
    this.isSpeakerOn = false,
    this.isMinimized = false,
    this.isSystemPip = false,
    this.profilePictureUrl,
    this.startedAt,
    this.switchRequestedCallType,
    this.switchRequestedEvent,
    this.extraParticipants = const [],
  });

  CallActive copyWith({
    bool? isMuted,
    bool? isVideoOff,
    bool? isFrontCamera,
    bool? isRemoteMuted,
    bool? isRemoteVideoOff,
    bool? isSpeakerOn,
    bool? isMinimized,
    bool? isSystemPip,
    bool? isVideo,
    String? switchRequestedCallType,
    Map<String, dynamic>? switchRequestedEvent,
    bool clearSwitchRequest = false,
    List<UserModel>? extraParticipants,
  }) {
    return CallActive(
      conversationId: conversationId,
      contactName: contactName,
      recipientId: recipientId,
      isVideo: isVideo ?? this.isVideo,
      isMuted: isMuted ?? this.isMuted,
      isVideoOff: isVideoOff ?? this.isVideoOff,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      isRemoteMuted: isRemoteMuted ?? this.isRemoteMuted,
      isRemoteVideoOff: isRemoteVideoOff ?? this.isRemoteVideoOff,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isMinimized: isMinimized ?? this.isMinimized,
      isSystemPip: isSystemPip ?? this.isSystemPip,
      profilePictureUrl: profilePictureUrl,
      startedAt: startedAt,
      switchRequestedCallType: clearSwitchRequest ? null : (switchRequestedCallType ?? this.switchRequestedCallType),
      switchRequestedEvent: clearSwitchRequest ? null : (switchRequestedEvent ?? this.switchRequestedEvent),
      extraParticipants: extraParticipants ?? this.extraParticipants,
    );
  }

  List<Object?> get props => [
        conversationId,
        contactName,
        recipientId,
        isVideo,
        isMuted,
        isVideoOff,
        isFrontCamera,
        isRemoteMuted,
        isRemoteVideoOff,
        isSpeakerOn,
        isMinimized,
        isSystemPip,
        profilePictureUrl,
        startedAt,
        switchRequestedCallType,
        switchRequestedEvent,
        extraParticipants,
      ];
}

class CallEnded extends CallWebRtcState {
  final String? reason;
  const CallEnded({this.reason});
}

class CallRejected extends CallWebRtcState {
  final String reason;
  const CallRejected({this.reason = 'Call declined'});
}

class CallError extends CallWebRtcState {
  final String message;
  const CallError(this.message);
}
