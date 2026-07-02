// mason make bloc --name call_webrtc

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
  final String? profilePictureUrl;
  const CallConnecting({
    required this.conversationId,
    required this.isVideo,
    required this.contactName,
    this.recipientId = '',
    this.isMinimized = false,
    this.profilePictureUrl,
  });

  CallConnecting copyWith({
    String? contactName,
    String? recipientId,
    bool? isMinimized,
    String? profilePictureUrl,
  }) {
    return CallConnecting(
      conversationId: conversationId,
      isVideo: isVideo,
      contactName: contactName ?? this.contactName,
      recipientId: recipientId ?? this.recipientId,
      isMinimized: isMinimized ?? this.isMinimized,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
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
  const CallRinging({
    required this.incomingEvent,
    required this.callerName,
    required this.recipientId,
    required this.isVideo,
    this.profilePictureUrl,
  });
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
  final bool isMinimized;
  final String? profilePictureUrl;
  const CallActive({
    required this.conversationId,
    required this.contactName,
    required this.recipientId,
    required this.isVideo,
    this.isMuted = false,
    this.isSpeakerOn = true,
    this.isVideoOff = false,
    this.isRemoteVideoOff = false,
    this.isRemoteMuted = false,
    this.isMinimized = false,
    this.profilePictureUrl,
  });

  CallActive copyWith({
    String? contactName,
    String? recipientId,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isVideoOff,
    bool? isRemoteVideoOff,
    bool? isRemoteMuted,
    bool? isMinimized,
    String? profilePictureUrl,
  }) {
    return CallActive(
      conversationId: conversationId,
      contactName: contactName ?? this.contactName,
      recipientId: recipientId ?? this.recipientId,
      isVideo: isVideo,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isVideoOff: isVideoOff ?? this.isVideoOff,
      isRemoteVideoOff: isRemoteVideoOff ?? this.isRemoteVideoOff,
      isRemoteMuted: isRemoteMuted ?? this.isRemoteMuted,
      isMinimized: isMinimized ?? this.isMinimized,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }
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
