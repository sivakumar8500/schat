// mason make bloc --name call_webrtc
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/call_screen/src/domain/web_rtc_service.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'call_webrtc_event.dart';
import 'call_webrtc_state.dart';

class CallWebRtcBloc extends Bloc<CallWebRtcEvent, CallWebRtcState> {
  final WebRtcService _webRtcService;
  final ChatSocketRepository _repository;

  CallWebRtcBloc(this._webRtcService, this._repository)
      : super(const CallIdle()) {
    on<InitiateCallEvent>(_onInitiateCall);
    on<AnswerCallEvent>(_onAnswerCall);
    on<HangUpCallEvent>(_onHangUp);
    on<RejectCallEvent>(_onRejectCall);
    on<HandleIncomingCallEvent>(_onHandleIncoming);
    on<HandleCallAnsweredEvent>(_onHandleCallAnswered);
    on<HandleIceCandidateEvent>(_onHandleIceCandidate);
    on<HandleCallDisconnectedEvent>(_onHandleDisconnected);
    on<ToggleMuteCallEvent>(_onToggleMute);
    on<ToggleCameraCallEvent>(_onToggleCamera);
    on<SwitchCameraCallEvent>(_onSwitchCamera);
    on<ToggleSpeakerCallEvent>(_onToggleSpeaker);
  }

  // ─────────────────────────────────────────────
  // INITIATE CALL (Caller)
  // ─────────────────────────────────────────────
  Future<void> _onInitiateCall(
    InitiateCallEvent event,
    Emitter<CallWebRtcState> emit,
  ) async {
    try {
      emit(CallConnecting(
        conversationId: event.conversationId,
        isVideo: event.isVideo,
        contactName: '',
      ));
      await _webRtcService.makeCall(
        conversationId: event.conversationId,
        isVideo: event.isVideo,
        repository: _repository,
      );
      debugPrint('CallWebRtcBloc: Call initiated');
    } catch (e) {
      debugPrint('CallWebRtcBloc: Error initiating call: $e');
      emit(CallError('Failed to start call: $e'));
    }
  }

  // ─────────────────────────────────────────────
  // ANSWER CALL (Callee)
  // ─────────────────────────────────────────────
  Future<void> _onAnswerCall(
    AnswerCallEvent event,
    Emitter<CallWebRtcState> emit,
  ) async {
    try {
      emit(CallConnecting(
        conversationId: event.incomingEvent['conversation_id'] ?? '',
        isVideo: event.incomingEvent['call_type'] == 'video',
        contactName: '',
      ));
      await _webRtcService.answerCall(
        incomingEvent: event.incomingEvent,
        repository: _repository,
      );
      emit(CallActive(
        conversationId: event.incomingEvent['conversation_id'] ?? '',
        isVideo: event.incomingEvent['call_type'] == 'video',
      ));
    } catch (e) {
      debugPrint('CallWebRtcBloc: Error answering call: $e');
      emit(CallError('Failed to answer call: $e'));
    }
  }

  // ─────────────────────────────────────────────
  // HANG UP
  // ─────────────────────────────────────────────
  Future<void> _onHangUp(
    HangUpCallEvent event,
    Emitter<CallWebRtcState> emit,
  ) async {
    await _webRtcService.endCall(
      conversationId: event.conversationId,
      repository: _repository,
    );
    emit(const CallEnded());
  }

  // ─────────────────────────────────────────────
  // REJECT CALL
  // ─────────────────────────────────────────────
  void _onRejectCall(
    RejectCallEvent event,
    Emitter<CallWebRtcState> emit,
  ) {
    _webRtcService.rejectCall(
      conversationId: event.conversationId,
      repository: _repository,
    );
    emit(const CallEnded());
  }

  // ─────────────────────────────────────────────
  // INCOMING CALL (Socket push to callee)
  // ─────────────────────────────────────────────
  void _onHandleIncoming(
    HandleIncomingCallEvent event,
    Emitter<CallWebRtcState> emit,
  ) {
    final callType = event.incomingEvent['call_type'] as String? ?? 'audio';
    emit(CallRinging(
      incomingEvent: event.incomingEvent,
      callerName: event.incomingEvent['caller_name'] as String? ?? 'Unknown',
      isVideo: callType == 'video',
    ));
    debugPrint('CallWebRtcBloc: Incoming call — type=$callType');
  }

  // ─────────────────────────────────────────────
  // CALL ANSWERED (Socket push to caller)
  // ─────────────────────────────────────────────
  Future<void> _onHandleCallAnswered(
    HandleCallAnsweredEvent event,
    Emitter<CallWebRtcState> emit,
  ) async {
    await _webRtcService.handleCallAnswered(event.event);
    final response = event.event['response'] as String?;
    if (response == 'accept') {
      final currentState = state;
      final conversationId = (currentState is CallConnecting)
          ? currentState.conversationId
          : _webRtcService.activeConversationId ?? '';
      final isVideo = (currentState is CallConnecting) ? currentState.isVideo : false;
      emit(CallActive(conversationId: conversationId, isVideo: isVideo));
    } else {
      emit(CallRejected(reason: response == 'busy' ? 'User is busy' : 'Call declined'));
    }
  }

  // ─────────────────────────────────────────────
  // ICE CANDIDATE (Socket push — both sides)
  // ─────────────────────────────────────────────
  Future<void> _onHandleIceCandidate(
    HandleIceCandidateEvent event,
    Emitter<CallWebRtcState> emit,
  ) async {
    await _webRtcService.handleRemoteIceCandidate(event.event);
  }

  // ─────────────────────────────────────────────
  // REMOTE DISCONNECTED
  // ─────────────────────────────────────────────
  Future<void> _onHandleDisconnected(
    HandleCallDisconnectedEvent event,
    Emitter<CallWebRtcState> emit,
  ) async {
    await _webRtcService.cleanup();
    emit(const CallEnded(reason: 'The other party ended the call'));
  }

  // ─────────────────────────────────────────────
  // TOGGLES
  // ─────────────────────────────────────────────
  void _onToggleMute(ToggleMuteCallEvent event, Emitter<CallWebRtcState> emit) {
    if (state is CallActive) {
      final current = state as CallActive;
      final newMuted = !current.isMuted;
      _webRtcService.toggleMute(newMuted);
      emit(current.copyWith(isMuted: newMuted));
    }
  }

  void _onToggleCamera(
      ToggleCameraCallEvent event, Emitter<CallWebRtcState> emit) {
    if (state is CallActive) {
      final current = state as CallActive;
      final newVideoOff = !current.isVideoOff;
      _webRtcService.toggleVideo(newVideoOff);
      emit(current.copyWith(isVideoOff: newVideoOff));
    }
  }

  Future<void> _onSwitchCamera(
      SwitchCameraCallEvent event, Emitter<CallWebRtcState> emit) async {
    await _webRtcService.switchCamera();
  }

  void _onToggleSpeaker(
      ToggleSpeakerCallEvent event, Emitter<CallWebRtcState> emit) {
    if (state is CallActive) {
      final current = state as CallActive;
      emit(current.copyWith(isSpeakerOn: !current.isSpeakerOn));
    }
  }

  @override
  Future<void> close() {
    _webRtcService.cleanup();
    return super.close();
  }
}
