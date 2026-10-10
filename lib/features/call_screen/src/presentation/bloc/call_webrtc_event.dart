import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';

abstract class CallWebRtcEvent {
  const CallWebRtcEvent();
}

/// Caller initiates an outgoing call
class InitiateCallEvent extends CallWebRtcEvent {
  final String conversationId;
  final bool isVideo;
  final String contactName;
  final String recipientId;
  final String? profilePictureUrl;
  final bool isGroup;
  final String? groupName;
  final List<UserModel> extraParticipants;

  const InitiateCallEvent({
    required this.conversationId,
    required this.isVideo,
    this.contactName = '',
    this.recipientId = '',
    this.profilePictureUrl,
    this.isGroup = false,
    this.groupName,
    this.extraParticipants = const [],
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
  final String? messageId;
  const HangUpCallEvent(this.conversationId, {this.messageId});
}

/// Either side rejects incoming call
class RejectCallEvent extends CallWebRtcEvent {
  final String conversationId;
  final String? messageId;
  const RejectCallEvent(this.conversationId, {this.messageId});
}

/// Socket pushed a call_incoming event — callee shows ringing UI
class HandleIncomingCallEvent extends CallWebRtcEvent {
  final Map<String, dynamic> incomingEvent;
  const HandleIncomingCallEvent(this.incomingEvent);
}

/// User clicked notification banner — open full-screen incoming call window with Accept & Decline
class ShowIncomingCallUiEvent extends CallWebRtcEvent {
  final Map<String, dynamic> incomingEvent;
  const ShowIncomingCallUiEvent(this.incomingEvent);
}

/// Socket pushed call_answered — caller finishes handshake
class HandleCallAnsweredEvent extends CallWebRtcEvent {
  final Map<String, dynamic> event;
  const HandleCallAnsweredEvent(this.event);
}

/// Socket pushed call_participant_joined in group call
class HandleCallParticipantJoinedEvent extends CallWebRtcEvent {
  final Map<String, dynamic> event;
  const HandleCallParticipantJoinedEvent(this.event);
}

/// Socket pushed call_participant_left in group call
class HandleCallParticipantLeftEvent extends CallWebRtcEvent {
  final Map<String, dynamic> event;
  const HandleCallParticipantLeftEvent(this.event);
}

/// Remote user is busy on another call
class HandleCallBusyEvent extends CallWebRtcEvent {
  final String contactName;
  const HandleCallBusyEvent(this.contactName);
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

/// Set system PiP mode (Android / iOS native PiP)
class SetSystemPipModeEvent extends CallWebRtcEvent {
  final bool isSystemPip;
  const SetSystemPipModeEvent(this.isSystemPip);
}

/// Remote party toggled their video
class HandleRemoteVideoToggleEvent extends CallWebRtcEvent {
  final bool isVideoOff;
  const HandleRemoteVideoToggleEvent(this.isVideoOff);
}

/// Remote party updated their mute status (audio or video)
class HandleRemoteMuteUpdateEvent extends CallWebRtcEvent {
  final String? userId;
  final bool isMuted;
  final String muteType;
  const HandleRemoteMuteUpdateEvent({
    this.userId,
    required this.isMuted,
    required this.muteType,
  });
}

class HandleCallErrorEvent extends CallWebRtcEvent {
  final String error;
  const HandleCallErrorEvent(this.error);
}

class RequestCallSwitchEvent extends CallWebRtcEvent {
  final String callType;
  const RequestCallSwitchEvent(this.callType);
}

class HandleCallSwitchRequestedEvent extends CallWebRtcEvent {
  final Map<String, dynamic> event;
  const HandleCallSwitchRequestedEvent(this.event);
}

class RespondToCallSwitchEvent extends CallWebRtcEvent {
  final bool accept;
  const RespondToCallSwitchEvent(this.accept);
}

class HandleCallSwitchRespondedEvent extends CallWebRtcEvent {
  final Map<String, dynamic> event;
  const HandleCallSwitchRespondedEvent(this.event);
}

/// Event to add new participants into the ongoing call
class AddParticipantsCallEvent extends CallWebRtcEvent {
  final List<UserModel> users;
  const AddParticipantsCallEvent(this.users);
}

/// Event to re-invite / recall a disconnected or timed out participant in group call
class ReinviteParticipantCallEvent extends CallWebRtcEvent {
  final UserModel user;
  const ReinviteParticipantCallEvent(this.user);
}

/// Dispatched when a participant's 60-second connection timer expires
class HandleParticipantTimeoutEvent extends CallWebRtcEvent {
  final String userId;
  const HandleParticipantTimeoutEvent(this.userId);
}

/// Dispatched when returning from a phone call interruption or app resume to reacquire mic/camera and restore media transmission
class ReacquireMediaEvent extends CallWebRtcEvent {
  const ReacquireMediaEvent();
}
