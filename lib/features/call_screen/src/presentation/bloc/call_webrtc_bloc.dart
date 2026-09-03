// mason make bloc --name call_webrtc
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:schat/features/call_screen/src/domain/web_rtc_service.dart';
import 'package:schat/features/call_screen/src/domain/call_sound_service.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/contacts_repository.dart';
import 'package:schat/core/storage/storage_service.dart';
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
  StreamSubscription? _webRtcSignalSubscription;
  Timer? _callTimeoutTimer;
  String? _activeCallMessageId;
  DateTime? _activeCallStart;

  DateTime? get activeCallStart => _activeCallStart;

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
    on  <ToggleSpeakerCallEvent>(_onToggleSpeaker);
    on<SetCallMinimizedEvent>(_onSetMinimized);
    on<HandleRemoteVideoToggleEvent>(_onHandleRemoteVideoToggle);
    on<HandleRemoteMuteUpdateEvent>(_onHandleRemoteMuteUpdate);
    on<RequestCallSwitchEvent>(_onRequestCallSwitch);
    on<HandleCallSwitchRequestedEvent>(_onHandleCallSwitchRequested);
    on<RespondToCallSwitchEvent>(_onRespondToCallSwitch);
    on<HandleCallSwitchRespondedEvent>(_onHandleCallSwitchResponded);
    on<HandleCallErrorEvent>((event, emit) {
      _cancelCallTimeoutTimer();
      _activeCallStart = null;
      emit(CallError(event.error));
    });

    // Listen to WebRTC connection signals (e.g. call ended from ICE failure)
    _webRtcSignalSubscription = _webRtcService.callSignalState.listen((state) {
      if (state == CallSignalState.ended) {
        add(const HandleCallDisconnectedEvent());
      }
    });

    // Listen for calls answered via system UI (CallKit/ConnectionService)
    if (!kIsWeb) {
      _notificationSubscription = _notificationService.onCallAnswered.listen((extra) {
        add(AnswerCallEvent(extra));
        _navigateToCallPage(extra);
      });
    }

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
        case 'call_initiated':
          _activeCallMessageId = (data['message_id'] ?? data['messageId'])?.toString();
          debugPrint('CallWebRtcBloc: Received call_initiated, saved activeCallMessageId: $_activeCallMessageId');
          break;
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
        case 'call_video_toggle':
          add(HandleRemoteVideoToggleEvent(data['isVideoOff'] == true));
          break;
        case 'call_mute_status_updated':
          add(HandleRemoteMuteUpdateEvent(
            isMuted: data['is_muted'] == true,
            muteType: data['mute_type'] ?? 'audio',
          ));
          break;
        case 'call_switch_requested':
          add(HandleCallSwitchRequestedEvent(Map<String, dynamic>.from(data)));
          break;
        case 'call_switch_responded':
          add(HandleCallSwitchRespondedEvent(Map<String, dynamic>.from(data)));
          break;
        case 'error':
          final errorMsg = data['message']?.toString();
          if (errorMsg != null && errorMsg.contains('blocked')) {
            add(HandleCallErrorEvent(errorMsg));
          }
          break;
      }
    });
  }

  void _startCallTimeoutTimer(String conversationId, {required bool isOutgoing}) {
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = Timer(const Duration(seconds: 90), () {
      debugPrint('CallWebRtcBloc: Call unanswered after 90 seconds, auto disconnecting');
      if (isOutgoing) {
        add(HangUpCallEvent(conversationId));
      } else {
        add(RejectCallEvent(conversationId));
      }
    });
  }

  void _cancelCallTimeoutTimer() {
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = null;
  }

  /// Navigates to the call page once the navigator context is ready.
  /// Retries up to 10 times (3 seconds total) when the app is resuming
  /// from a killed/background state and Flutter hasn't fully initialized yet.
  void _navigateToCallPage(Map<String, dynamic> extra) async {
    const maxAttempts = 10;
    const retryDelay = Duration(milliseconds: 300);

    BuildContext? context;
    for (int i = 0; i < maxAttempts; i++) {
      context = navigatorKey.currentContext;
      if (context != null) break;
      await Future.delayed(retryDelay);
    }

    if (context == null) {
      debugPrint('CallWebRtcBloc: Navigator context still null after retries');
      return;
    }

    final isVideo = extra['call_type'] == 'video';
    final callerName = extra['caller_name'] ?? 'Unknown';
    final conversationId = extra['conversation_id'] ?? '';
    final recipientId = extra['recipient_id'] ?? '';
    final callerDetails = extra['caller_details'] ?? extra['callerDetails'];
    String? profilePictureUrl;
    if (callerDetails is Map) {
      profilePictureUrl = callerDetails['profile_picture_url'] ??
          callerDetails['profilePictureUrl'];
    }
    profilePictureUrl ??= extra['caller_profile_picture_url'] ??
        extra['profile_picture_url'] ??
        extra['profilePictureUrl'];

    // Prefer details already resolved in the current state.
    String finalName = callerName;
    String finalRecipient = recipientId;
    String? finalPic = profilePictureUrl;
    if (state is CallActive) {
      finalName = (state as CallActive).contactName;
      finalRecipient = (state as CallActive).recipientId;
      finalPic = (state as CallActive).profilePictureUrl;
    } else if (state is CallConnecting) {
      finalName = (state as CallConnecting).contactName;
      finalRecipient = (state as CallConnecting).recipientId;
      finalPic = (state as CallConnecting).profilePictureUrl;
    }

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: this,
          child: isVideo
              ? VideoCallPage(
                  conversationId: conversationId,
                  contactName: finalName,
                  contactColor: Colors.blue,
                  recipientId: finalRecipient,
                  isOutgoing: false,
                  profilePictureUrl: finalPic,
                  myProfilePictureUrl: getIt<StorageService>().getProfilePic(),
                )
              : AudioCallPage(
                  conversationId: conversationId,
                  contactName: finalName,
                  contactColor: Colors.blue,
                  recipientId: finalRecipient,
                  isOutgoing: false,
                  profilePictureUrl: finalPic,
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
        profilePictureUrl: event.profilePictureUrl,
      ));
      
      // Start back ring early so the caller hears it immediately
      _soundService.playBackRing();

      // Start 90-second unanswered timeout timer
      _startCallTimeoutTimer(event.conversationId, isOutgoing: true);

      final storage = getIt<StorageService>();
      final myName = storage.getUsername();
      final myPic = storage.getProfilePic();

      await _webRtcService.makeCall(
        conversationId: event.conversationId,
        isVideo: event.isVideo,
        repository: _repository,
        callerName: myName,
        profilePictureUrl: myPic,
      );
      debugPrint('CallWebRtcBloc: makeCall completed');
    } catch (e) {
      _cancelCallTimeoutTimer();
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
      _cancelCallTimeoutTimer();
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

      // --- Safe offer decode -------------------------------------------
      // When the app is relaunched from a killed state via CallKit, the
      // `offer` in the extras may have been re-serialized to a JSON string.
      // Decode it back to a Map before passing to WebRTC.
      final Map<String, dynamic> safeEvent =
          Map<String, dynamic>.from(event.incomingEvent);
      final dynamic rawOffer = safeEvent['offer'];
      if (rawOffer is String && rawOffer.isNotEmpty) {
        try {
          safeEvent['offer'] = jsonDecode(rawOffer);
        } catch (e) {
          debugPrint('CallWebRtcBloc: Failed to decode offer JSON: $e');
          safeEvent['offer'] = null;
        }
      }
      // ----------------------------------------------------------------

      final callerDetails = safeEvent['caller_details'] ?? safeEvent['callerDetails'];
      String? profilePic;
      if (callerDetails is Map) {
        profilePic = callerDetails['profile_picture_url'] ??
            callerDetails['profilePictureUrl'];
      }
      profilePic ??= safeEvent['caller_profile_picture_url'] ??
          safeEvent['profile_picture_url'] ??
          safeEvent['profilePictureUrl'];

      emit(CallConnecting(
        conversationId: safeEvent['conversation_id'] ?? '',
        isVideo: safeEvent['call_type'] == 'video',
        contactName: safeEvent['caller_name'] ?? '',
        recipientId: safeEvent['recipient_id'] ?? '',
        isMinimized: false,
        profilePictureUrl: profilePic,
      ));

      await _webRtcService.answerCall(
        incomingEvent: safeEvent,
        repository: _repository,
      );
      _soundService.stopAll();

      final isVideo = safeEvent['call_type'] == 'video';
      final callerName = safeEvent['caller_name'] ?? 'Unknown';
      final recipientId = safeEvent['recipient_id'] ?? '';

      bool speaker = isVideo;
      if (state is CallRinging) {
        speaker = (state as CallRinging).isSpeakerOn;
      }

      await _webRtcService.toggleSpeaker(speaker);

      _activeCallStart = DateTime.now();
      emit(CallActive(
        conversationId: safeEvent['conversation_id'] ?? '',
        contactName: callerName,
        recipientId: recipientId,
        isVideo: isVideo,
        isSpeakerOn: speaker,
        profilePictureUrl: profilePic,
        startedAt: _activeCallStart,
      ));
    } catch (e) {
      debugPrint('CallWebRtcBloc: Error answering call: $e');
      emit(CallError('Failed to answer call: $e'));
    }
  }

  Future<void> _onHangUp(
    HangUpCallEvent event,
    Emitter<CallWebRtcState> emit,
  ) async {
    _cancelCallTimeoutTimer();
    _soundService.stopAll();
    await _webRtcService.endCall(
      conversationId: event.conversationId,
      messageId: event.messageId ?? _activeCallMessageId,
      repository: _repository,
    );
    _activeCallMessageId = null;
    _activeCallStart = null;
    emit(const CallEnded());
  }

  // ─────────────────────────────────────────────
  // REJECT CALL
  // ─────────────────────────────────────────────
  void _onRejectCall(
    RejectCallEvent event,
    Emitter<CallWebRtcState> emit,
  ) {
    _cancelCallTimeoutTimer();
    _soundService.stopAll();
    _webRtcService.rejectCall(
      conversationId: event.conversationId,
      messageId: event.messageId ?? _activeCallMessageId,
      repository: _repository,
    );
    _activeCallMessageId = null;
    _activeCallStart = null;
    emit(const CallEnded());
  }

  // ─────────────────────────────────────────────
  // INCOMING CALL (Socket push to callee)
  // ─────────────────────────────────────────────
  Future<void> _onHandleIncoming(
    HandleIncomingCallEvent event,
    Emitter<CallWebRtcState> emit,
  ) async {
    final callType = event.incomingEvent['call_type'] as String? ?? 'audio';
    final recipientId = event.incomingEvent['recipient_id'] as String? ?? '';
    final callerDetails = event.incomingEvent['caller_details'] ?? event.incomingEvent['callerDetails'];
    String? profilePic;
    if (callerDetails is Map) {
      profilePic = callerDetails['profile_picture_url'] ??
          callerDetails['profilePictureUrl'];
    }
    profilePic ??= event.incomingEvent['caller_profile_picture_url'] ??
        event.incomingEvent['profile_picture_url'] ??
        event.incomingEvent['profilePictureUrl'];

    // Resolve caller name from caller_details
    String callerName = event.incomingEvent['caller_name'] as String? ?? 'Unknown';

    if (callerDetails is Map) {
      final phone = callerDetails['phone_number']?.toString() ?? '';
      final username = callerDetails['username']?.toString() ?? '';
      if (phone.isNotEmpty) {
        final savedName = await _findContactName(phone);
        if (savedName != null) {
          callerName = savedName;
        } else {
          callerName = username.isNotEmpty ? username : phone;
        }
      } else if (username.isNotEmpty) {
        callerName = username;
      }
    }
    
    // Mutate map so all subsequent screens/events have the resolved name
    event.incomingEvent['caller_name'] = callerName;
    
    final conversationId = event.incomingEvent['conversation_id'] ?? event.incomingEvent['conversationId'] ?? '';
    _activeCallMessageId = (event.incomingEvent['message_id'] ?? event.incomingEvent['messageId'])?.toString();
    _startCallTimeoutTimer(conversationId, isOutgoing: false);

    _soundService.playRingtone();
    emit(CallRinging(
      incomingEvent: event.incomingEvent,
      callerName: callerName,
      recipientId: recipientId,
      isVideo: callType == 'video',
      profilePictureUrl: profilePic,
    ));
    debugPrint('CallWebRtcBloc: Incoming call — type=$callType, resolvedCallerName=$callerName');

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
    final callerDetails = incomingEvent['caller_details'] ?? incomingEvent['callerDetails'];
    String? profilePic;
    if (callerDetails is Map) {
      profilePic = callerDetails['profile_picture_url'] ??
          callerDetails['profilePictureUrl'];
    }
    profilePic ??= incomingEvent['caller_profile_picture_url'] ??
        incomingEvent['profile_picture_url'] ??
        incomingEvent['profilePictureUrl'];

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
            profilePictureUrl: profilePic,
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
    _cancelCallTimeoutTimer();
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
      String? profilePic;

      if (currentState is CallConnecting) {
        conversationId = currentState.conversationId;
        contactName = currentState.contactName;
        recipientId = currentState.recipientId;
        isVideo = currentState.isVideo;
        isMinimized = currentState.isMinimized;
        profilePic = currentState.profilePictureUrl;
      } else {
        conversationId = _webRtcService.activeConversationId ?? '';
        contactName = event.event['caller_name'] ?? 'Unknown';
        recipientId = event.event['recipient_id'] ?? '';
        isVideo = event.event['call_type'] == 'video';
        final callerDetails = event.event['caller_details'] ?? event.event['callerDetails'];
        if (callerDetails is Map) {
          profilePic = callerDetails['profile_picture_url'] ??
              callerDetails['profilePictureUrl'];
        }
        profilePic ??= event.event['caller_profile_picture_url'] ??
            event.event['profile_picture_url'] ??
            event.event['profilePictureUrl'];
      }
      
      bool speaker = isVideo;
      if (currentState is CallConnecting) {
        speaker = currentState.isSpeakerOn;
      }
      
      await _webRtcService.toggleSpeaker(speaker);
      
      _activeCallStart = DateTime.now();
      emit(CallActive(
        conversationId: conversationId,
        contactName: contactName,
        recipientId: recipientId,
        isVideo: isVideo,
        isSpeakerOn: speaker,
        isMinimized: isMinimized,
        profilePictureUrl: profilePic,
        startedAt: _activeCallStart,
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
    _activeCallStart = null;
    _cancelCallTimeoutTimer();
    _soundService.stopAll();
    // Dismiss any system/CallKit notification on both platforms
    if (!kIsWeb) {
      try {
        await FlutterCallkitIncoming.endAllCalls();
      } catch (e) {
        debugPrint('CallWebRtcBloc: endAllCalls failed: $e');
      }
    }
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

      // Send signaling to remote peer
      _repository.emit('message', {
        'type': 'call_toggle_mute',
        'conversation_id': current.conversationId,
        'is_muted': newMuted,
        'mute_type': 'audio',
      });

      emit(current.copyWith(isMuted: newMuted));
    }
  }

  void _onToggleCamera(
      ToggleCameraCallEvent event, Emitter<CallWebRtcState> emit) {
    if (state is CallActive) {
      final current = state as CallActive;
      final newVideoOff = !current.isVideoOff;
      _webRtcService.toggleVideo(newVideoOff);
      
      // Send signaling to remote peer
      _repository.emit('message', {
        'type': 'call_toggle_mute',
        'conversation_id': current.conversationId,
        'is_muted': newVideoOff,
        'mute_type': 'video',
      });

      emit(current.copyWith(isVideoOff: newVideoOff));
    }
  }

  void _onHandleRemoteVideoToggle(
      HandleRemoteVideoToggleEvent event, Emitter<CallWebRtcState> emit) {
    if (state is CallActive) {
      emit((state as CallActive).copyWith(isRemoteVideoOff: event.isVideoOff));
    }
  }

  void _onHandleRemoteMuteUpdate(
      HandleRemoteMuteUpdateEvent event, Emitter<CallWebRtcState> emit) {
    if (state is CallActive) {
      final current = state as CallActive;
      if (event.muteType == 'audio') {
        emit(current.copyWith(isRemoteMuted: event.isMuted));
      } else if (event.muteType == 'video') {
        emit(current.copyWith(isRemoteVideoOff: event.isMuted));
      }
    }
  }

  Future<void> _onSwitchCamera(
      SwitchCameraCallEvent event, Emitter<CallWebRtcState> emit) async {
    await _webRtcService.switchCamera();
    if (state is CallActive) {
      final current = state as CallActive;
      emit(current.copyWith(isFrontCamera: !current.isFrontCamera));
    } else if (state is CallConnecting) {
      final current = state as CallConnecting;
      emit(current.copyWith(isFrontCamera: !current.isFrontCamera));
    }
  }

  void _onToggleSpeaker(
      ToggleSpeakerCallEvent event, Emitter<CallWebRtcState> emit) {
    if (state is CallActive) {
      final current = state as CallActive;
      final newSpeakerState = !current.isSpeakerOn;
      _webRtcService.toggleSpeaker(newSpeakerState);
      emit(current.copyWith(isSpeakerOn: newSpeakerState));
    } else if (state is CallConnecting) {
      final current = state as CallConnecting;
      final newSpeakerState = !current.isSpeakerOn;
      _webRtcService.toggleSpeaker(newSpeakerState);
      emit(current.copyWith(isSpeakerOn: newSpeakerState));
    } else if (state is CallRinging) {
      final current = state as CallRinging;
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
    _callTimeoutTimer?.cancel();
    _notificationSubscription?.cancel();
    _socketSubscription?.cancel();
    _webRtcSignalSubscription?.cancel();
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

  Future<String?> _findContactName(String phoneNumber) async {
    try {
      final contacts = await getIt<ContactsRepository>().getContacts();
      final normalizedTarget = phoneNumber.replaceAll(RegExp(r'\D'), '');
      if (normalizedTarget.isEmpty) return null;
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final normalizedPhone = phone.number.replaceAll(RegExp(r'\D'), '');
          if (normalizedPhone.isNotEmpty &&
              (normalizedPhone.endsWith(normalizedTarget) || normalizedTarget.endsWith(normalizedPhone))) {
            if (contact.displayName.isNotEmpty) {
              return contact.displayName;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error finding contact name: $e');
    }
    return null;
  }
  Future<void> _onRequestCallSwitch(
      RequestCallSwitchEvent event, Emitter<CallWebRtcState> emit) async {
    if (state is CallActive) {
      final current = state as CallActive;
      await _webRtcService.requestCallSwitch(
        callType: event.callType,
        repository: _repository,
      );
      // Wait for response
    }
  }

  void _onHandleCallSwitchRequested(
      HandleCallSwitchRequestedEvent event, Emitter<CallWebRtcState> emit) {
    if (state is CallActive) {
      final current = state as CallActive;
      final requestedType = event.event['call_type'] as String?;
      if (requestedType != null) {
        emit(current.copyWith(
          switchRequestedCallType: requestedType,
          switchRequestedEvent: event.event,
        ));
      }
    }
  }

  Future<void> _onRespondToCallSwitch(
      RespondToCallSwitchEvent event, Emitter<CallWebRtcState> emit) async {
    if (state is CallActive) {
      final current = state as CallActive;
      final requestedType = current.switchRequestedCallType;
      
      if (event.accept && requestedType != null) {
        final isVideo = requestedType == 'video';
        await _webRtcService.acceptCallSwitch(
          isVideo: isVideo,
          repository: _repository,
          remoteOfferEvent: current.switchRequestedEvent,
          messageId: _activeCallMessageId,
        );
        emit(current.copyWith(
          isVideo: isVideo,
          clearSwitchRequest: true,
          isVideoOff: !isVideo,
        ));
      } else {
        _webRtcService.rejectCallSwitch(
          repository: _repository,
          messageId: _activeCallMessageId,
        );
        emit(current.copyWith(clearSwitchRequest: true));
      }
    }
  }

  Future<void> _onHandleCallSwitchResponded(
      HandleCallSwitchRespondedEvent event, Emitter<CallWebRtcState> emit) async {
    if (state is CallActive) {
      final current = state as CallActive;
      final response = event.event['response'] as String?;
      if (response == 'accept') {
        final newType = event.event['call_type'] as String?;
        if (newType != null) {
          final isVideo = newType == 'video';
          emit(current.copyWith(
            isVideo: isVideo,
            isVideoOff: !isVideo,
          ));
        }
        await _webRtcService.handleCallSwitchResponded(event.event);
      } else {
        // Switch rejected by remote, just ignore or show toast
      }
    }
  }
}
