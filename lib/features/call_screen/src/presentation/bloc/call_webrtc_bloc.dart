// mason make bloc --name call_webrtc
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
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
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/features/call_screen/src/domain/models/ongoing_group_call.dart';
import 'call_webrtc_event.dart';
import 'call_webrtc_state.dart';

@lazySingleton
class CallWebRtcBloc extends Bloc<CallWebRtcEvent, CallWebRtcState> {
  static const MethodChannel _pipChannel = MethodChannel('com.sdpi.schat/pip');
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
  final Map<String, OngoingGroupCall> _ongoingGroupCalls = {};

  DateTime? get activeCallStart => _activeCallStart;
  Map<String, OngoingGroupCall> get ongoingGroupCalls => Map.unmodifiable(_ongoingGroupCalls);

  void dismissOngoingGroupCall(String conversationId) {
    _ongoingGroupCalls.remove(conversationId);
  }

  void _updateCallActive(bool active) {
    try {
      if (active) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    } catch (e) {
      debugPrint('CallWebRtcBloc: Wakelock error: $e');
    }
    try {
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        _pipChannel.invokeMethod('setCallActive', {'isActive': active});
      }
    } catch (e) {
      debugPrint('CallWebRtcBloc: PipChannel error: $e');
    }
  }

  @override
  void onChange(Change<CallWebRtcState> change) {
    super.onChange(change);
    final next = change.nextState;
    if (next is CallActive || next is CallConnecting || next is CallRinging) {
      _updateCallActive(true);
    } else if (next is CallEnded || next is CallError || next is CallIdle || next is CallRejected) {
      _updateCallActive(false);
    }
  }

  CallWebRtcBloc(this._webRtcService, this._repository)
      : super(const CallIdle()) {
    on<InitiateCallEvent>(_onInitiateCall);
    on<AnswerCallEvent>(_onAnswerCall);
    on<HangUpCallEvent>(_onHangUp);
    on<RejectCallEvent>(_onRejectCall);
    on<HandleIncomingCallEvent>(_onHandleIncoming);
    on<HandleCallAnsweredEvent>(_onHandleCallAnswered);
    on<HandleCallParticipantJoinedEvent>(_onHandleCallParticipantJoined);
    on<HandleCallParticipantLeftEvent>(_onHandleCallParticipantLeft);
    on<HandleIceCandidateEvent>(_onHandleIceCandidate);
    on<HandleCallDisconnectedEvent>(_onHandleDisconnected);
    on<ToggleMuteCallEvent>(_onToggleMute);
    on<ToggleCameraCallEvent>(_onToggleCamera);
    on<SwitchCameraCallEvent>(_onSwitchCamera);
    on<ToggleSpeakerCallEvent>(_onToggleSpeaker);
    on<SetCallMinimizedEvent>(_onSetMinimized);
    on<SetSystemPipModeEvent>(_onSetSystemPipMode);
    on<HandleRemoteVideoToggleEvent>(_onHandleRemoteVideoToggle);
    on<HandleRemoteMuteUpdateEvent>(_onHandleRemoteMuteUpdate);
    on<RequestCallSwitchEvent>(_onRequestCallSwitch);
    on<HandleCallSwitchRequestedEvent>(_onHandleCallSwitchRequested);
    on<RespondToCallSwitchEvent>(_onRespondToCallSwitch);
    on<HandleCallSwitchRespondedEvent>(_onHandleCallSwitchResponded);
    on<AddParticipantsCallEvent>(_onAddParticipants);
    on<ReinviteParticipantCallEvent>(_onReinviteParticipant);
    on<HandleParticipantTimeoutEvent>(_onHandleParticipantTimeout);
    on<HandleCallErrorEvent>((event, emit) {
      _cancelCallTimeoutTimer();
      _cancelAllParticipantTimers();
      _activeCallStart = null;
      emit(CallError(event.error));
    });

    // Listen to PiP state changes from native platform
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      _pipChannel.setMethodCallHandler((call) async {
        if (call.method == 'onPipModeChanged') {
          final bool isInPip = call.arguments?['isInPip'] ?? false;
          add(SetSystemPipModeEvent(isInPip));
          if (!isInPip) {
            add(const SetCallMinimizedEvent(false));
          }
        }
      });
    }

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
      if (activeId != null && conversationId != null && activeId != conversationId && type != 'call_initiate' && type != 'call_incoming') {
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
          final senderId = (data['sender_id'] ?? data['senderId'])?.toString();
          final myId = getIt<StorageService>().getUserId();
          if (senderId != null && myId != null && senderId == myId) {
            debugPrint('CallWebRtcBloc: Ignoring incoming call event from self');
            return;
          }
          add(HandleIncomingCallEvent(Map<String, dynamic>.from(data)));
          break;
        case 'call_response':
        case 'call_answered':
          add(HandleCallAnsweredEvent(Map<String, dynamic>.from(data)));
          break;
        case 'call_participant_joined':
          add(HandleCallParticipantJoinedEvent(Map<String, dynamic>.from(data)));
          break;
        case 'call_participant_left':
          add(HandleCallParticipantLeftEvent(Map<String, dynamic>.from(data)));
          break;
        case 'ice_candidate':
        case 'ice_candidate_received':
          add(HandleIceCandidateEvent(Map<String, dynamic>.from(data)));
          break;
        case 'call_hangup':
        case 'call_disconnected':
        case 'call_ended':
        case 'call_canceled':
        case 'call_cancelled':
        case 'call_rejected':
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

  final Map<String, Timer> _participantTimeoutTimers = {};

  void _startParticipantTimeout(String userId, {required String conversationId}) {
    _participantTimeoutTimers[userId]?.cancel();
    _participantTimeoutTimers[userId] = Timer(const Duration(seconds: 60), () {
      debugPrint('CallWebRtcBloc: 60s timeout reached for participant $userId in group call');
      add(HandleParticipantTimeoutEvent(userId));
    });
  }

  void _onHandleParticipantTimeout(
    HandleParticipantTimeoutEvent event,
    Emitter<CallWebRtcState> emit,
  ) {
    final userId = event.userId;
    final currentState = state;
    if (currentState is CallActive) {
      if (!currentState.connectedParticipantIds.contains(userId)) {
        final updatedDisconnected = {...currentState.disconnectedParticipantIds, userId};
        emit(currentState.copyWith(disconnectedParticipantIds: updatedDisconnected));
      }
    } else if (currentState is CallConnecting) {
      if (!currentState.connectedParticipantIds.contains(userId)) {
        final updatedDisconnected = {...currentState.disconnectedParticipantIds, userId};
        emit(currentState.copyWith(disconnectedParticipantIds: updatedDisconnected));
      }
    }
  }

  void _cancelAllParticipantTimers() {
    for (final timer in _participantTimeoutTimers.values) {
      timer.cancel();
    }
    _participantTimeoutTimers.clear();
  }

  void _startCallTimeoutTimer(String conversationId, {required bool isOutgoing}) {
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = Timer(const Duration(seconds: 60), () {
      debugPrint('CallWebRtcBloc: Call unanswered after 60 seconds, auto disconnecting');
      final currentState = state;
      if (currentState is CallActive && (currentState.isGroup || currentState.extraParticipants.isNotEmpty)) {
        if (currentState.connectedParticipantIds.isNotEmpty) {
          // If some participants are connected in the group call, keep call alive
          return;
        }
      }
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

    final isGroup = extra['is_group'] == true || extra['isGroup'] == true;
    final groupName = (extra['group_name'] ?? extra['groupName'])?.toString();
    if (isGroup && groupName != null && groupName.isNotEmpty && (state is! CallActive && state is! CallConnecting)) {
      finalName = groupName;
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
                  isGroup: isGroup,
                  groupName: groupName,
                )
              : AudioCallPage(
                  conversationId: conversationId,
                  contactName: finalName,
                  contactColor: Colors.blue,
                  recipientId: finalRecipient,
                  isOutgoing: false,
                  profilePictureUrl: finalPic,
                  myProfilePictureUrl: getIt<StorageService>().getProfilePic(),
                  isGroup: isGroup,
                  groupName: groupName,
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
      debugPrint('CallWebRtcBloc: _onInitiateCall started (isGroup=${event.isGroup})');
      
      if (event.isGroup) {
        _ongoingGroupCalls[event.conversationId] = OngoingGroupCall(
          conversationId: event.conversationId,
          groupName: event.groupName ?? event.contactName,
          isVideo: event.isVideo,
          profilePictureUrl: event.profilePictureUrl,
          participants: event.extraParticipants,
          connectedParticipantIds: const {},
          startedAt: DateTime.now(),
        );
      }

      emit(CallConnecting(
        conversationId: event.conversationId,
        isVideo: event.isVideo,
        contactName: event.contactName,
        recipientId: '', 
        isMinimized: false,
        profilePictureUrl: event.profilePictureUrl,
        isGroup: event.isGroup,
        groupName: event.groupName,
        extraParticipants: event.extraParticipants,
      ));
      
      // Start back ring early so the caller hears it immediately
      _soundService.playBackRing();

      // Start 90-second unanswered timeout timer
      _startCallTimeoutTimer(event.conversationId, isOutgoing: true);

      if (event.isGroup) {
        for (final participant in event.extraParticipants) {
          _startParticipantTimeout(participant.id, conversationId: event.conversationId);
        }
      }

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
      _cancelAllParticipantTimers();
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

      final bool isGroup = safeEvent['is_group'] == true;
      final String? groupName = safeEvent['group_name']?.toString();
      final convoId = safeEvent['conversation_id'] ?? '';

      if (isGroup && convoId.isNotEmpty) {
        _ongoingGroupCalls[convoId] = OngoingGroupCall(
          conversationId: convoId,
          groupName: groupName ?? safeEvent['caller_name'] ?? 'Group Call',
          isVideo: safeEvent['call_type'] == 'video',
          profilePictureUrl: profilePic,
          participants: const [],
          connectedParticipantIds: const {},
          startedAt: DateTime.now(),
        );
      }

      emit(CallConnecting(
        conversationId: convoId,
        isVideo: safeEvent['call_type'] == 'video',
        contactName: safeEvent['caller_name'] ?? '',
        recipientId: safeEvent['recipient_id'] ?? '',
        isMinimized: false,
        profilePictureUrl: profilePic,
        isGroup: isGroup,
        groupName: groupName,
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
        conversationId: convoId,
        contactName: callerName,
        recipientId: recipientId,
        isVideo: isVideo,
        isSpeakerOn: speaker,
        profilePictureUrl: profilePic,
        isGroup: isGroup,
        groupName: groupName,
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

    final currentState = state;
    final isGroupCall = (currentState is CallActive && (currentState.isGroup || currentState.extraParticipants.isNotEmpty)) ||
        (currentState is CallConnecting && (currentState.isGroup || currentState.extraParticipants.isNotEmpty));

    if (isGroupCall) {
      _cancelAllParticipantTimers();
      final myId = getIt<StorageService>().getUserId() ?? '';
      final String convoId = currentState is CallActive
          ? currentState.conversationId
          : (currentState as CallConnecting).conversationId;
      final String gName = currentState is CallActive
          ? (currentState.groupName ?? currentState.contactName)
          : ((currentState as CallConnecting).groupName ?? currentState.contactName);
      final bool isVid = currentState is CallActive ? currentState.isVideo : (currentState as CallConnecting).isVideo;
      final String? pPic = currentState is CallActive ? currentState.profilePictureUrl : (currentState as CallConnecting).profilePictureUrl;
      final List<UserModel> parts = currentState is CallActive ? currentState.extraParticipants : (currentState as CallConnecting).extraParticipants;
      final Set<String> connected = currentState is CallActive ? currentState.connectedParticipantIds : (currentState as CallConnecting).connectedParticipantIds;

      final remainingConnected = connected.where((id) => id != myId).toSet();
      
      // Update ongoing group call record so user can rejoin anytime under Calls tab
      _ongoingGroupCalls[convoId] = OngoingGroupCall(
        conversationId: convoId,
        groupName: gName,
        isVideo: isVid,
        profilePictureUrl: pPic,
        participants: parts,
        connectedParticipantIds: remainingConnected,
        startedAt: (currentState is CallActive ? currentState.startedAt : null) ?? DateTime.now(),
      );

      // Inform other group members that only this participant has left
      _repository.emit('message', {
        'type': 'call_hangup',
        'conversation_id': event.conversationId,
        'participant_id': myId,
        'sender_id': myId,
        'is_group': true,
        'isGroup': true,
      });
      _repository.emit('message', {
        'type': 'call_participant_left',
        'conversation_id': event.conversationId,
        'participant_id': myId,
        'sender_id': myId,
        'is_group': true,
        'isGroup': true,
      });

      await _webRtcService.cleanup();
      _activeCallMessageId = null;
      _activeCallStart = null;
      emit(const CallEnded());
      return;
    }

    _cancelAllParticipantTimers();
    await _webRtcService.endCall(
      conversationId: event.conversationId,
      messageId: event.messageId ?? _activeCallMessageId,
      repository: _repository,
    );
    _ongoingGroupCalls.remove(event.conversationId);
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
    _cancelAllParticipantTimers();
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
    final incomingConvoId = (event.incomingEvent['conversation_id'] ?? event.incomingEvent['conversationId'])?.toString() ?? '';
    final senderId = (event.incomingEvent['sender_id'] ?? event.incomingEvent['senderId'])?.toString() ?? '';
    final isGroup = event.incomingEvent['is_group'] == true || event.incomingEvent['isGroup'] == true;
    final groupName = (event.incomingEvent['group_name'] ?? event.incomingEvent['groupName'])?.toString();

    // 1. Busy check: if user is already in an ongoing/connecting call from a DIFFERENT conversation
    final currentState = state;
    String currentConvoId = '';
    if (currentState is CallActive) {
      currentConvoId = currentState.conversationId;
    } else if (currentState is CallConnecting) {
      currentConvoId = currentState.conversationId;
    }

    if ((currentState is CallActive || currentState is CallConnecting) &&
        currentConvoId.isNotEmpty &&
        currentConvoId != incomingConvoId) {
      debugPrint('CallWebRtcBloc: User is already busy in call ($currentConvoId). Replying busy to $senderId for $incomingConvoId');
      _repository.emit('message', {
        'type': 'call_response',
        'conversation_id': incomingConvoId,
        'recipient_id': senderId,
        'response': 'busy',
        'reason': 'busy',
        'caller_name': getIt<StorageService>().getUsername(),
      });
      return;
    }

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
    
    _activeCallMessageId = (event.incomingEvent['message_id'] ?? event.incomingEvent['messageId'])?.toString();
    _startCallTimeoutTimer(incomingConvoId, isOutgoing: false);

    _soundService.playRingtone();
    emit(CallRinging(
      incomingEvent: event.incomingEvent,
      callerName: callerName,
      recipientId: recipientId,
      isVideo: callType == 'video',
      profilePictureUrl: profilePic,
      isGroup: isGroup,
      groupName: groupName,
    ));
    debugPrint('CallWebRtcBloc: Incoming call — type=$callType, isGroup=$isGroup, resolvedCallerName=$callerName');

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
            callerColor: Colors.blue,
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
    final response = event.event['response'] as String?;
    
    // 1. Busy response handling
    if (response == 'busy') {
      _cancelCallTimeoutTimer();
      _soundService.stopAll();
      final calleeName = event.event['caller_name'] ?? 'User';
      emit(CallRejected(reason: '$calleeName is currently in another call'));
      return;
    }

    // 2. Reject response handling
    if (response == 'reject') {
      final currentState = state;
      final senderId = (event.event['sender_id'] ?? event.event['senderId'] ?? event.event['participant_id'])?.toString() ?? '';
      if (currentState is CallActive && (currentState.isGroup || currentState.extraParticipants.isNotEmpty)) {
        debugPrint('CallWebRtcBloc: A group participant declined the call, keeping active group call intact');
        if (senderId.isNotEmpty) {
          _participantTimeoutTimers[senderId]?.cancel();
          final updatedDisconnected = {...currentState.disconnectedParticipantIds, senderId};
          emit(currentState.copyWith(disconnectedParticipantIds: updatedDisconnected));
        }
        return;
      }
      if (currentState is CallConnecting && (currentState.isGroup || currentState.extraParticipants.isNotEmpty)) {
        debugPrint('CallWebRtcBloc: A group participant declined while connecting');
        if (senderId.isNotEmpty) {
          _participantTimeoutTimers[senderId]?.cancel();
          final updatedDisconnected = {...currentState.disconnectedParticipantIds, senderId};
          emit(currentState.copyWith(disconnectedParticipantIds: updatedDisconnected));
        }
        return;
      }
      _cancelCallTimeoutTimer();
      _cancelAllParticipantTimers();
      _soundService.stopAll();
      emit(const CallRejected(reason: 'Call declined'));
      return;
    }

    // 3. Accept response handling
    if (response == 'accept') {
      // If we are currently still in CallRinging (we haven't answered yet),
      // another member in the group answered. We must NOT dismiss our ringing window!
      if (state is CallRinging) {
        debugPrint('CallWebRtcBloc: Another participant answered group call. Retaining CallRinging state.');
        return;
      }

      _cancelCallTimeoutTimer();
      await _webRtcService.handleCallAnswered(event.event);
      _soundService.stopAll();

      final currentState = state;
      String conversationId = '';
      String contactName = '';
      String recipientId = '';
      bool isVideo = false;
      bool isMinimized = false;
      bool isGroup = false;
      String? groupName;
      List<UserModel> extraParticipants = [];
      String? profilePic;

      final connectedSet = <String>{};
      final disconnectedSet = <String>{};
      if (currentState is CallConnecting) {
        conversationId = currentState.conversationId;
        contactName = currentState.contactName;
        recipientId = currentState.recipientId;
        isVideo = currentState.isVideo;
        isMinimized = currentState.isMinimized;
        profilePic = currentState.profilePictureUrl;
        isGroup = currentState.isGroup;
        groupName = currentState.groupName;
        extraParticipants = currentState.extraParticipants;
        connectedSet.addAll(currentState.connectedParticipantIds);
        disconnectedSet.addAll(currentState.disconnectedParticipantIds);
      } else if (currentState is CallActive) {
        conversationId = currentState.conversationId;
        contactName = currentState.contactName;
        recipientId = currentState.recipientId;
        isVideo = currentState.isVideo;
        isMinimized = currentState.isMinimized;
        profilePic = currentState.profilePictureUrl;
        isGroup = currentState.isGroup;
        groupName = currentState.groupName;
        extraParticipants = currentState.extraParticipants;
        connectedSet.addAll(currentState.connectedParticipantIds);
        disconnectedSet.addAll(currentState.disconnectedParticipantIds);
      } else {
        conversationId = _webRtcService.activeConversationId ?? '';
        contactName = event.event['caller_name'] ?? 'Unknown';
        recipientId = event.event['recipient_id'] ?? '';
        isVideo = event.event['call_type'] == 'video';
        isGroup = event.event['is_group'] == true || event.event['isGroup'] == true;
        groupName = (event.event['group_name'] ?? event.event['groupName'])?.toString();
        final callerDetails = event.event['caller_details'] ?? event.event['callerDetails'];
        if (callerDetails is Map) {
          profilePic = callerDetails['profile_picture_url'] ??
              callerDetails['profilePictureUrl'];
        }
        profilePic ??= event.event['caller_profile_picture_url'] ??
            event.event['profile_picture_url'] ??
            event.event['profilePictureUrl'];
      }
      
      final senderId = (event.event['sender_id'] ?? event.event['senderId'] ?? event.event['participant_id'] ?? recipientId)?.toString() ?? '';
      if (senderId.isNotEmpty) {
        _participantTimeoutTimers[senderId]?.cancel();
        connectedSet.add(senderId);
        disconnectedSet.remove(senderId);
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
        isGroup: isGroup,
        groupName: groupName,
        extraParticipants: extraParticipants,
        connectedParticipantIds: connectedSet,
        disconnectedParticipantIds: disconnectedSet,
        profilePictureUrl: profilePic,
        startedAt: _activeCallStart,
      ));
    }
  }

  Future<void> _onHandleCallParticipantJoined(
    HandleCallParticipantJoinedEvent event,
    Emitter<CallWebRtcState> emit,
  ) async {
    debugPrint('CallWebRtcBloc: Participant joined event: ${event.event}');
    _soundService.stopAll();
    _cancelCallTimeoutTimer();

    if (event.event['answer'] != null) {
      try {
        await _webRtcService.handleCallAnswered(event.event);
      } catch (e) {
        debugPrint('CallWebRtcBloc: Error handling WebRTC answer in participant joined: $e');
      }
    }

    final rawUser = event.event['user'] ?? event.event['user_details'] ?? event.event['userDetails'];
    UserModel? user;
    if (rawUser is Map) {
      user = UserModel(
        id: (rawUser['id'] ?? rawUser['user_id'])?.toString() ?? '',
        username: rawUser['username']?.toString() ?? '',
        contactName: rawUser['name']?.toString() ?? rawUser['display_name']?.toString() ?? rawUser['username']?.toString() ?? '',
        phoneNumber: rawUser['phone_number']?.toString() ?? '',
        profilePictureUrl: (rawUser['profile_picture_url'] ?? rawUser['profilePictureUrl'] ?? rawUser['avatar'] ?? rawUser['caller_profile_picture_url'])?.toString(),
      );
    } else {
      final pid = (event.event['participant_id'] ?? event.event['user_id'] ?? event.event['sender_id'])?.toString() ?? '';
      if (pid.isNotEmpty) {
        user = UserModel(
          id: pid,
          username: event.event['username']?.toString() ?? '',
          contactName: event.event['name']?.toString() ?? event.event['display_name']?.toString() ?? event.event['caller_name']?.toString() ?? '',
          phoneNumber: '',
          profilePictureUrl: (event.event['profile_picture_url'] ?? event.event['profilePictureUrl'] ?? event.event['avatar'] ?? event.event['caller_profile_picture_url'])?.toString(),
        );
      }
    }

    if (user == null || user.id.isEmpty) return;
    _participantTimeoutTimers[user.id]?.cancel();
    final myId = getIt<StorageService>().getUserId();
    if (user.id == myId) return;

    final convoId = (event.event['conversation_id'] ?? event.event['conversationId'])?.toString() ?? '';
    if (convoId.isNotEmpty && _ongoingGroupCalls.containsKey(convoId)) {
      final currentOngoing = _ongoingGroupCalls[convoId]!;
      final updatedOngoingParts = currentOngoing.participants.map((u) {
        if (u.id.toLowerCase() == user!.id.toLowerCase()) {
          return u.copyWith(
            profilePictureUrl: (u.profilePictureUrl != null && u.profilePictureUrl!.isNotEmpty)
                ? u.profilePictureUrl
                : user.profilePictureUrl,
            contactName: u.displayName.isNotEmpty ? u.displayName : user.displayName,
          );
        }
        return u;
      }).toList();
      if (!currentOngoing.participants.any((u) => u.id.toLowerCase() == user!.id.toLowerCase())) {
        updatedOngoingParts.add(user);
      }
      final updatedOngoingConnected = {...currentOngoing.connectedParticipantIds, user.id};
      _ongoingGroupCalls[convoId] = currentOngoing.copyWith(
        participants: updatedOngoingParts,
        connectedParticipantIds: updatedOngoingConnected,
      );
    }

    if (state is CallActive) {
      final current = state as CallActive;
      final existingIds = current.extraParticipants.map((u) => u.id.toLowerCase()).toSet();
      final updatedList = current.extraParticipants.map((u) {
        if (u.id.toLowerCase() == user!.id.toLowerCase()) {
          return u.copyWith(
            profilePictureUrl: (u.profilePictureUrl != null && u.profilePictureUrl!.isNotEmpty)
                ? u.profilePictureUrl
                : user.profilePictureUrl,
            contactName: u.displayName.isNotEmpty ? u.displayName : user.displayName,
          );
        }
        return u;
      }).toList();
      if (!existingIds.contains(user.id.toLowerCase())) {
        updatedList.add(user);
      }
      final updatedConnected = {...current.connectedParticipantIds, user.id};
      final updatedDisconnected = current.disconnectedParticipantIds.where((id) => id != user!.id).toSet();
      emit(current.copyWith(
        extraParticipants: updatedList,
        connectedParticipantIds: updatedConnected,
        disconnectedParticipantIds: updatedDisconnected,
        isGroup: true,
      ));
    } else if (state is CallConnecting) {
      final current = state as CallConnecting;
      final existingIds = current.extraParticipants.map((u) => u.id.toLowerCase()).toSet();
      final updatedList = current.extraParticipants.map((u) {
        if (u.id.toLowerCase() == user!.id.toLowerCase()) {
          return u.copyWith(
            profilePictureUrl: (u.profilePictureUrl != null && u.profilePictureUrl!.isNotEmpty)
                ? u.profilePictureUrl
                : user.profilePictureUrl,
            contactName: u.displayName.isNotEmpty ? u.displayName : user.displayName,
          );
        }
        return u;
      }).toList();
      if (!existingIds.contains(user.id.toLowerCase())) {
        updatedList.add(user);
      }
      final updatedConnected = {...current.connectedParticipantIds, user.id};
      final updatedDisconnected = current.disconnectedParticipantIds.where((id) => id != user!.id).toSet();
      _activeCallStart ??= DateTime.now();
      emit(CallActive(
        conversationId: current.conversationId,
        contactName: current.contactName,
        recipientId: current.recipientId,
        isVideo: current.isVideo,
        isSpeakerOn: current.isSpeakerOn,
        isMinimized: current.isMinimized,
        isGroup: true,
        groupName: current.groupName,
        extraParticipants: updatedList,
        connectedParticipantIds: updatedConnected,
        disconnectedParticipantIds: updatedDisconnected,
        profilePictureUrl: current.profilePictureUrl,
        startedAt: _activeCallStart,
      ));
    } else if (state is CallRinging) {
      final current = state as CallRinging;
      final existingIds = current.extraParticipants.map((u) => u.id.toLowerCase()).toSet();
      final updatedList = current.extraParticipants.map((u) {
        if (u.id.toLowerCase() == user!.id.toLowerCase()) {
          return u.copyWith(
            profilePictureUrl: (u.profilePictureUrl != null && u.profilePictureUrl!.isNotEmpty)
                ? u.profilePictureUrl
                : user.profilePictureUrl,
            contactName: u.displayName.isNotEmpty ? u.displayName : user.displayName,
          );
        }
        return u;
      }).toList();
      if (!existingIds.contains(user.id.toLowerCase())) {
        updatedList.add(user);
      }
      final updatedConnected = {...current.connectedParticipantIds, user.id};
      final updatedDisconnected = current.disconnectedParticipantIds.where((id) => id != user!.id).toSet();
      emit(current.copyWith(
        extraParticipants: updatedList,
        connectedParticipantIds: updatedConnected,
        disconnectedParticipantIds: updatedDisconnected,
        isGroup: true,
      ));
    }
  }

  void _onHandleCallParticipantLeft(
    HandleCallParticipantLeftEvent event,
    Emitter<CallWebRtcState> emit,
  ) {
    debugPrint('CallWebRtcBloc: Participant left event: ${event.event}');
    final userId = (event.event['participant_id'] ?? event.event['user_id'] ?? event.event['sender_id'] ?? (event.event['user'] is Map ? event.event['user']['id'] : null))?.toString();
    if (userId == null || userId.isEmpty) return;

    _participantTimeoutTimers[userId]?.cancel();
    final convoId = (event.event['conversation_id'] ?? event.event['conversationId'])?.toString() ?? '';
    if (convoId.isNotEmpty && _ongoingGroupCalls.containsKey(convoId)) {
      final currentOngoing = _ongoingGroupCalls[convoId]!;
      final updatedOngoingConnected = currentOngoing.connectedParticipantIds
          .where((id) => id.toLowerCase() != userId.toLowerCase())
          .toSet();
      if (updatedOngoingConnected.isEmpty) {
        _ongoingGroupCalls.remove(convoId);
      } else {
        _ongoingGroupCalls[convoId] = currentOngoing.copyWith(
          connectedParticipantIds: updatedOngoingConnected,
        );
      }
    }

    final isGroup = event.event['is_group'] == true || event.event['isGroup'] == true;
    final currentState = state;
    final bool isCallGroup = (currentState is CallActive && (currentState.isGroup || currentState.extraParticipants.isNotEmpty)) ||
        (currentState is CallConnecting && (currentState.isGroup || currentState.extraParticipants.isNotEmpty)) ||
        (currentState is CallRinging && (currentState.isGroup || currentState.extraParticipants.isNotEmpty));

    // If this is a 1-to-1 call, ANY participant leaving or hanging up means the call is terminated!
    if (!isCallGroup && !isGroup) {
      debugPrint('CallWebRtcBloc: 1-to-1 call participant left ($userId). Ending call.');
      add(const HandleCallDisconnectedEvent());
      return;
    }

    if (state is CallActive) {
      final current = state as CallActive;
      final updatedConnected = current.connectedParticipantIds
          .where((id) => id.toLowerCase() != userId.toLowerCase())
          .toSet();
      final updatedDisconnected = {...current.disconnectedParticipantIds, userId};

      if (updatedConnected.isEmpty) {
        debugPrint('CallWebRtcBloc: All participants left, auto-cutting call for ${current.conversationId}');
        add(HangUpCallEvent(current.conversationId));
        return;
      }

      emit(current.copyWith(
        connectedParticipantIds: updatedConnected,
        disconnectedParticipantIds: updatedDisconnected,
      ));
    } else if (state is CallConnecting) {
      final current = state as CallConnecting;
      final updatedConnected = current.connectedParticipantIds
          .where((id) => id.toLowerCase() != userId.toLowerCase())
          .toSet();
      final updatedDisconnected = {...current.disconnectedParticipantIds, userId};
      if (updatedConnected.isEmpty && current.extraParticipants.isNotEmpty && current.extraParticipants.every((p) => updatedDisconnected.contains(p.id))) {
        debugPrint('CallWebRtcBloc: All participants left/rejected during CallConnecting, ending call');
        add(HangUpCallEvent(current.conversationId));
        return;
      }
      emit(current.copyWith(
        connectedParticipantIds: updatedConnected,
        disconnectedParticipantIds: updatedDisconnected,
      ));
    } else if (state is CallRinging) {
      final current = state as CallRinging;
      final updatedConnected = current.connectedParticipantIds
          .where((id) => id.toLowerCase() != userId.toLowerCase())
          .toSet();
      final updatedDisconnected = {...current.disconnectedParticipantIds, userId};
      emit(current.copyWith(
        connectedParticipantIds: updatedConnected,
        disconnectedParticipantIds: updatedDisconnected,
      ));
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
    final currentState = state;
    // If it's a group call and other participants are still present, keep call alive
    if (currentState is CallActive && (currentState.isGroup || currentState.extraParticipants.length > 1) && currentState.connectedParticipantIds.isNotEmpty) {
      debugPrint('CallWebRtcBloc: Remote party disconnected from group call. Remaining in call.');
      return;
    }

    _activeCallStart = null;
    _cancelCallTimeoutTimer();
    _cancelAllParticipantTimers();
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
    emit(const CallEnded(reason: 'The call has ended'));
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

  void _onSetSystemPipMode(
      SetSystemPipModeEvent event, Emitter<CallWebRtcState> emit) {
    if (state is CallActive) {
      emit((state as CallActive).copyWith(isSystemPip: event.isSystemPip));
    } else if (state is CallConnecting) {
      emit((state as CallConnecting).copyWith(isSystemPip: event.isSystemPip));
    }
  }

  @override
  Future<void> close() {
    _callTimeoutTimer?.cancel();
    _cancelAllParticipantTimers();
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
          isMinimized: false,
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
      final isAccepted = event.event['accepted'] == true ||
          event.event['status'] == 'accepted' ||
          response == 'accept' ||
          response == 'accepted';
      if (isAccepted) {
        final newType = (event.event['call_type'] ?? event.event['callType']) as String? ?? 'video';
        final isVideo = newType == 'video';
        emit(current.copyWith(
          isVideo: isVideo,
          isMinimized: false,
          isVideoOff: !isVideo,
        ));
        await _webRtcService.handleCallSwitchResponded(event.event);
      } else {
        debugPrint('CallWebRtcBloc: Switch to video was rejected by remote');
      }
    }
  }

  void _onAddParticipants(
      AddParticipantsCallEvent event, Emitter<CallWebRtcState> emit) {
    if (event.users.isEmpty) return;

    if (state is CallActive) {
      final current = state as CallActive;
      final existingIds = current.extraParticipants.map((u) => u.id).toSet();
      existingIds.add(current.recipientId);
      final newUsers =
          event.users.where((u) => !existingIds.contains(u.id)).toList();
      if (newUsers.isEmpty) return;

      final updated = [...current.extraParticipants, ...newUsers];
      emit(current.copyWith(extraParticipants: updated));

      for (final user in newUsers) {
        _startParticipantTimeout(user.id, conversationId: current.conversationId);
        _repository.emit('message', {
          'type': 'call_initiate',
          'conversation_id': current.conversationId,
          'recipient_id': user.id,
          'recipientId': user.id,
          'call_type': current.isVideo ? 'video' : 'audio',
          'caller_name': current.contactName,
        });
      }
    } else if (state is CallConnecting) {
      final current = state as CallConnecting;
      final existingIds = current.extraParticipants.map((u) => u.id).toSet();
      existingIds.add(current.recipientId);
      final newUsers =
          event.users.where((u) => !existingIds.contains(u.id)).toList();
      if (newUsers.isEmpty) return;

      final updated = [...current.extraParticipants, ...newUsers];
      emit(current.copyWith(extraParticipants: updated));

      for (final user in newUsers) {
        _startParticipantTimeout(user.id, conversationId: current.conversationId);
        _repository.emit('message', {
          'type': 'call_initiate',
          'conversation_id': current.conversationId,
          'recipient_id': user.id,
          'recipientId': user.id,
          'call_type': current.isVideo ? 'video' : 'audio',
          'caller_name': current.contactName,
        });
      }
    }
  }

  void _onReinviteParticipant(
    ReinviteParticipantCallEvent event,
    Emitter<CallWebRtcState> emit,
  ) {
    final user = event.user;
    if (user.id.isEmpty) return;

    final currentState = state;
    String convoId = '';
    bool isVid = false;
    String cName = '';

    if (currentState is CallActive) {
      convoId = currentState.conversationId;
      isVid = currentState.isVideo;
      cName = currentState.contactName;

      final updatedDisconnected =
          currentState.disconnectedParticipantIds.where((id) => id != user.id).toSet();
      final existingIds = currentState.extraParticipants.map((u) => u.id).toSet();
      final updatedList = existingIds.contains(user.id)
          ? currentState.extraParticipants
          : [...currentState.extraParticipants, user];

      emit(currentState.copyWith(
        disconnectedParticipantIds: updatedDisconnected,
        extraParticipants: updatedList,
      ));
    } else if (currentState is CallConnecting) {
      convoId = currentState.conversationId;
      isVid = currentState.isVideo;
      cName = currentState.contactName;

      final updatedDisconnected =
          currentState.disconnectedParticipantIds.where((id) => id != user.id).toSet();
      final existingIds = currentState.extraParticipants.map((u) => u.id).toSet();
      final updatedList = existingIds.contains(user.id)
          ? currentState.extraParticipants
          : [...currentState.extraParticipants, user];

      emit(currentState.copyWith(
        disconnectedParticipantIds: updatedDisconnected,
        extraParticipants: updatedList,
      ));
    }

    if (convoId.isNotEmpty) {
      _startParticipantTimeout(user.id, conversationId: convoId);
      _repository.emit('message', {
        'type': 'call_initiate',
        'conversation_id': convoId,
        'recipient_id': user.id,
        'recipientId': user.id,
        'call_type': isVid ? 'video' : 'audio',
        'caller_name': cName,
      });
    }
  }
}

