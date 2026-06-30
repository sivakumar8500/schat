// mason make bloc --name call_webrtc
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/call_screen/src/domain/web_rtc_service.dart';
import 'package:schat/features/call_screen/src/domain/call_sound_service.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/core/notifications/call_notification_service.dart';
import 'package:schat/features/call_screen/src/presentation/audio_call_page.dart';
import 'package:schat/features/call_screen/src/presentation/video_call_page.dart';
import 'package:schat/features/call_screen/src/presentation/incoming_call_dialog.dart';
import 'package:schat/main.dart';
import 'package:schat/injection.dart';
import 'package:injectable/injectable.dart';
import 'call_webrtc_event.dart';
import 'call_webrtc_state.dart';

@lazySingleton
class CallWebRtcBloc extends Bloc<CallWebRtcEvent, CallWebRtcState> {
  final WebRtcService _webRtcService;
  final ChatSocketRepository _repository;
  final CallSoundService _soundService = getIt<CallSoundService>();
  final CallNotificationService _notificationService = getIt<CallNotificationService>();
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _socketSubscription;

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
    on<SetCallMinimizedEvent>(_onSetMinimized);

    // Listen for calls answered via system UI (CallKit/ConnectionService)
    _notificationSubscription = _notificationService.onCallAnswered.listen((extra) {
      add(AnswerCallEvent(extra));
      _navigateToCallPage(extra);
    });

    // Listen to socket messages for call signaling
    _socketSubscription = _repository.onMessage.listen((data) {
      if (data is! Map) return;
      final type = data['type'];
      final conversationId = data['conversation_id'] ?? data['conversationId'];
      
      // Filter signaling by active conversation if applicable
      final activeId = _webRtcService.activeConversationId;
      if (activeId != null && conversationId != null && activeId != conversationId) {
        debugPrint('CallWebRtcBloc: Ignoring signaling for different conversation: $conversationId');
        return;
      }

      switch (type) {
        case 'call_initiate':
        case 'call_incoming':
          add(HandleIncomingCallEvent(Map<String, dynamic>.from(data)));
          break;
        case 'call_response':
        case 'call_answered':
          add(HandleCallAnsweredEvent(Map<String, dynamic>.from(data)));
          break;
        case 'ice_candidate':
        case 'ice_candidate_received':
          add(HandleIceCandidateEvent(Map<String, dynamic>.from(data)));
          break;
        case 'call_hangup':
        case 'call_disconnected':
          add(const HandleCallDisconnectedEvent());
          break;
      }
    });
  }

  void _navigateToCallPage(Map<String, dynamic> extra) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final isVideo = extra['call_type'] == 'video';
    final callerName = extra['caller_name'] ?? 'Unknown';
    final conversationId = extra['conversation_id'] ?? '';
    final recipientId = extra['recipient_id'] ?? '';

    // If we're already in a call state, prefer those details
    String finalName = callerName;
    String finalRecipient = recipientId;
    if (state is CallActive) {
      finalName = (state as CallActive).contactName;
      finalRecipient = (state as CallActive).recipientId;
    } else if (state is CallConnecting) {
      finalName = (state as CallConnecting).contactName;
      finalRecipient = (state as CallConnecting).recipientId;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: this,
          child: isVideo
              ? VideoCallPage(
                  conversationId: conversationId,
                  contactName: finalName,
                  contactColor: Colors.blue, // Default color
                  recipientId: finalRecipient,
                  isOutgoing: false,
                )
              : AudioCallPage(
                  conversationId: conversationId,
                  contactName: finalName,
                  contactColor: Colors.blue,
                  recipientId: finalRecipient,
                  isOutgoing: false,
                ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // INITIATE CALL (Caller)
  // ─────────────────────────────────────────────
  Future<void> _onInitiateCall(
    InitiateCallEvent event,
    Emitter<CallWebRtcState> emit,
  ) async {
    try {
      debugPrint('CallWebRtcBloc: _onInitiateCall started');
      emit(CallConnecting(
        conversationId: event.conversationId,
        isVideo: event.isVideo,
        contactName: event.contactName,
        recipientId: '', 
        isMinimized: false,
      ));
      
      // Start back ring early so the caller hears it immediately
      _soundService.playBackRing();

      await _webRtcService.makeCall(
        conversationId: event.conversationId,
        isVideo: event.isVideo,
        repository: _repository,
      );
      debugPrint('CallWebRtcBloc: makeCall completed');
    } catch (e) {
      _soundService.stopAll();
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
      // Ensure socket is connected (especially important for background/terminated launches)
      if (!_repository.isConnected) {
        _repository.connect();
        
        // Wait up to 5 seconds for connection
        int attempts = 0;
        while (!_repository.isConnected && attempts < 10) {
          await Future.delayed(const Duration(milliseconds: 500));
          attempts++;
        }
        
        if (!_repository.isConnected) {
          debugPrint('CallWebRtcBloc: Failed to connect to socket in time');
          emit(const CallError('Socket connection failed'));
          return;
        }
      }

      emit(CallConnecting(
        conversationId: event.incomingEvent['conversation_id'] ?? '',
        isVideo: event.incomingEvent['call_type'] == 'video',
        contactName: event.incomingEvent['caller_name'] ?? '',
        recipientId: event.incomingEvent['recipient_id'] ?? '',
        isMinimized: false,
      ));
      await _webRtcService.answerCall(
        incomingEvent: event.incomingEvent,
        repository: _repository,
      );
      _soundService.stopAll();
      
      final isVideo = event.incomingEvent['call_type'] == 'video';
      final callerName = event.incomingEvent['caller_name'] ?? 'Unknown';
      final recipientId = event.incomingEvent['recipient_id'] ?? '';
      
      // For audio calls, start on earpiece (speaker false), for video start on speaker
      await _webRtcService.toggleSpeaker(isVideo);

      emit(CallActive(
        conversationId: event.incomingEvent['conversation_id'] ?? '',
        contactName: callerName,
        recipientId: recipientId,
        isVideo: isVideo,
        isSpeakerOn: isVideo,
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
    _soundService.stopAll();
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
    _soundService.stopAll();
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
    final callerName = event.incomingEvent['caller_name'] as String? ?? 'Unknown';
    final recipientId = event.incomingEvent['recipient_id'] as String? ?? '';
    
    _soundService.playRingtone();
    emit(CallRinging(
      incomingEvent: event.incomingEvent,
      callerName: callerName,
      recipientId: recipientId,
      isVideo: callType == 'video',
    ));
    debugPrint('CallWebRtcBloc: Incoming call — type=$callType');

    // Show the incoming call dialog globally
    _showIncomingCallDialog(event.incomingEvent);
  }

  void _showIncomingCallDialog(Map<String, dynamic> incomingEvent) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('CallWebRtcBloc: Navigator context null, falling back to CallKit');
      _notificationService.showIncomingCall(incomingEvent);
      return;
    }

    final callerName = incomingEvent['caller_name'] ?? 'Unknown';
    final isVideo = incomingEvent['call_type'] == 'video';
    final conversationId = incomingEvent['conversation_id'] ?? '';
    final recipientId = incomingEvent['recipient_id'] ?? '';

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => BlocProvider.value(
          value: this,
          child: IncomingCallDialog(
            incomingEvent: incomingEvent,
            callerName: callerName,
            callerColor: Colors.blue, // Default color for global dialog
            isVideo: isVideo,
            conversationId: conversationId,
            recipientId: recipientId,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CALL ANSWERED (Socket push to caller)
  // ─────────────────────────────────────────────
  Future<void> _onHandleCallAnswered(
    HandleCallAnsweredEvent event,
    Emitter<CallWebRtcState> emit,
  ) async {
    await _webRtcService.handleCallAnswered(event.event);
    _soundService.stopAll();
    final response = event.event['response'] as String?;
    if (response == 'accept') {
      final currentState = state;
      String conversationId = '';
      String contactName = '';
      String recipientId = '';
      bool isVideo = false;
      bool isMinimized = false;

      if (currentState is CallConnecting) {
        conversationId = currentState.conversationId;
        contactName = currentState.contactName;
        recipientId = currentState.recipientId;
        isVideo = currentState.isVideo;
        isMinimized = currentState.isMinimized;
      } else {
        conversationId = _webRtcService.activeConversationId ?? '';
        contactName = event.event['caller_name'] ?? 'Unknown';
        recipientId = event.event['recipient_id'] ?? '';
        isVideo = event.event['call_type'] == 'video';
      }
      
      // Initialize speaker state based on call type
      await _webRtcService.toggleSpeaker(isVideo);
      
      emit(CallActive(
        conversationId: conversationId, 
        contactName: contactName,
        recipientId: recipientId,
        isVideo: isVideo,
        isSpeakerOn: isVideo,
        isMinimized: isMinimized,
      ));
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
    _soundService.stopAll();
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
      final newSpeakerState = !current.isSpeakerOn;
      _webRtcService.toggleSpeaker(newSpeakerState);
      emit(current.copyWith(isSpeakerOn: newSpeakerState));
    }
  }

  void _onSetMinimized(
      SetCallMinimizedEvent event, Emitter<CallWebRtcState> emit) {
    if (state is CallActive) {
      emit((state as CallActive).copyWith(isMinimized: event.isMinimized));
    } else if (state is CallConnecting) {
      emit((state as CallConnecting).copyWith(isMinimized: event.isMinimized));
    }
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    _socketSubscription?.cancel();
    _webRtcService.cleanup();
    return super.close();
  }

  bool isCallActiveFor(String conversationId) {
    final currentState = state;
    if (currentState is CallActive) {
      return currentState.conversationId == conversationId;
    }
    if (currentState is CallConnecting) {
      return currentState.conversationId == conversationId;
    }
    return false;
  }
}
