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
  const CallConnecting({
    required this.conversationId,
    required this.isVideo,
    required this.contactName,
    this.recipientId = '',
    this.isMinimized = false,
  });

  CallConnecting copyWith({
    String? contactName,
    String? recipientId,
    bool? isMinimized,
  }) {
    return CallConnecting(
      conversationId: conversationId,
      isVideo: isVideo,
      contactName: contactName ?? this.contactName,
      recipientId: recipientId ?? this.recipientId,
      isMinimized: isMinimized ?? this.isMinimized,
    );
  }
}

/// Callee sees this — ringing/incoming call
class CallRinging extends CallWebRtcState {
  final Map<String, dynamic> incomingEvent;
  final String callerName;
  final String recipientId;
  final bool isVideo;
  const CallRinging({
    required this.incomingEvent,
    required this.callerName,
    required this.recipientId,
    required this.isVideo,
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
  final bool isMinimized;
  const CallActive({
    required this.conversationId,
    required this.contactName,
    required this.recipientId,
    required this.isVideo,
    this.isMuted = false,
    this.isSpeakerOn = true,
    this.isVideoOff = false,
    this.isMinimized = false,
  });

  CallActive copyWith({
    String? contactName,
    String? recipientId,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isVideoOff,
    bool? isMinimized,
  }) {
    return CallActive(
      conversationId: conversationId,
      contactName: contactName ?? this.contactName,
      recipientId: recipientId ?? this.recipientId,
      isVideo: isVideo,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isVideoOff: isVideoOff ?? this.isVideoOff,
      isMinimized: isMinimized ?? this.isMinimized,
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
