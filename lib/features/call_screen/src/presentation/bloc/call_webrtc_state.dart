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
  const CallConnecting({
    required this.conversationId,
    required this.isVideo,
    required this.contactName,
  });
}

/// Callee sees this — ringing/incoming call
class CallRinging extends CallWebRtcState {
  final Map<String, dynamic> incomingEvent;
  final String callerName;
  final bool isVideo;
  const CallRinging({
    required this.incomingEvent,
    required this.callerName,
    required this.isVideo,
  });
}

class CallActive extends CallWebRtcState {
  final String conversationId;
  final bool isVideo;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isVideoOff;
  const CallActive({
    required this.conversationId,
    required this.isVideo,
    this.isMuted = false,
    this.isSpeakerOn = true,
    this.isVideoOff = false,
  });

  CallActive copyWith({
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isVideoOff,
  }) {
    return CallActive(
      conversationId: conversationId,
      isVideo: isVideo,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isVideoOff: isVideoOff ?? this.isVideoOff,
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
