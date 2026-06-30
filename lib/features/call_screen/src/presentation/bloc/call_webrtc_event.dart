// mason make bloc --name call_webrtc

abstract class CallWebRtcEvent {
  const CallWebRtcEvent();
}

/// Caller initiates an outgoing call
class InitiateCallEvent extends CallWebRtcEvent {
  final String conversationId;
  final bool isVideo;
  final String contactName;
  const InitiateCallEvent({
    required this.conversationId,
    required this.isVideo,
    this.contactName = '',
  });
}

/// Callee answers an incoming call
class AnswerCallEvent extends CallWebRtcEvent {
  final Map<String, dynamic> incomingEvent;
  const AnswerCallEvent(this.incomingEvent);
}

/// Either side hangs up
class HangUpCallEvent extends CallWebRtcEvent {
  final String conversationId;
  const HangUpCallEvent(this.conversationId);
}

/// Either side rejects incoming call
class RejectCallEvent extends CallWebRtcEvent {
  final String conversationId;
  const RejectCallEvent(this.conversationId);
}

/// Socket pushed a call_incoming event — callee shows ringing UI
class HandleIncomingCallEvent extends CallWebRtcEvent {
  final Map<String, dynamic> incomingEvent;
  const HandleIncomingCallEvent(this.incomingEvent);
}

/// Socket pushed call_answered — caller finishes handshake
class HandleCallAnsweredEvent extends CallWebRtcEvent {
  final Map<String, dynamic> event;
  const HandleCallAnsweredEvent(this.event);
}

/// Socket pushed ice_candidate_received — both sides
class HandleIceCandidateEvent extends CallWebRtcEvent {
  final Map<String, dynamic> event;
  const HandleIceCandidateEvent(this.event);
}

/// Remote party disconnected
class HandleCallDisconnectedEvent extends CallWebRtcEvent {
  const HandleCallDisconnectedEvent();
}

/// Toggle microphone mute
class ToggleMuteCallEvent extends CallWebRtcEvent {
  const ToggleMuteCallEvent();
}

/// Toggle video on/off
class ToggleCameraCallEvent extends CallWebRtcEvent {
  const ToggleCameraCallEvent();
}

/// Switch front/back camera
class SwitchCameraCallEvent extends CallWebRtcEvent {
  const SwitchCameraCallEvent();
}

/// Toggle speaker
class ToggleSpeakerCallEvent extends CallWebRtcEvent {
  const ToggleSpeakerCallEvent();
}

/// Set minimized status
class SetCallMinimizedEvent extends CallWebRtcEvent {
  final bool isMinimized;
  const SetCallMinimizedEvent(this.isMinimized);
}
