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
import 'package:schat/main.dart';
import 'package:schat/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/features/call_screen/src/domain/models/ongoing_group_call.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_history_cubit.dart';
import 'package:schat/core/services/phone_call_state_service.dart';
import 'call_webrtc_event.dart';
import 'call_webrtc_state.dart';

@lazySingleton
class CallWebRtcBloc extends Bloc<CallWebRtcEvent, CallWebRtcState> with WidgetsBindingObserver {
  static const MethodChannel _pipChannel = MethodChannel('com.sdpi.schat/pip');
  static final ValueNotifier<bool> isCallScreenMountedNotifier = ValueNotifier<bool>(false);
  static bool get isCallScreenMounted => isCallScreenMountedNotifier.value;
  static set isCallScreenMounted(bool value) {
    if (isCallScreenMountedNotifier.value != value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isCallScreenMountedNotifier.value != value) {
          isCallScreenMountedNotifier.value = value;
        }
      });
    }
  }
  final WebRtcService _webRtcService;
  final ChatSocketRepository _repository;
  final CallSoundService _soundService = getIt<CallSoundService>();
  final CallNotificationService _notificationService = getIt<CallNotificationService>();
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _socketSubscription;
  StreamSubscription? _webRtcSignalSubscription;
  StreamSubscription? _phoneCallEndedSubscription;
  Timer? _callTimeoutTimer;
  String? _activeCallMessageId;
  DateTime? _activeCallStart;
  final Map<String, OngoingGroupCall> _ongoingGroupCalls = {};

  // Cached active/connecting call metadata to prevent state loss or 'Unknown' details
  String _cachedConversationId = '';
  String _cachedContactName = '';
  String _cachedRecipientId = '';
  bool _cachedIsVideo = false;
  bool _cachedIsGroup = false;
  String? _cachedGroupName;
  String? _cachedProfilePictureUrl;
  List<UserModel> _cachedExtraParticipants = [];
  Map<String, dynamic>? _cachedIncomingEvent;

  DateTime? get activeCallStart => _activeCallStart;
  Map<String, OngoingGroupCall> get ongoingGroupCalls => Map.unmodifiable(_ongoingGroupCalls);
  String get cachedContactName => _cachedContactName;
  String get cachedConversationId => _cachedConversationId;
  String get cachedRecipientId => _cachedRecipientId;
  bool get cachedIsVideo => _cachedIsVideo;
  bool get cachedIsGroup => _cachedIsGroup;
  String? get cachedGroupName => _cachedGroupName;
  String? get cachedProfilePictureUrl => _cachedProfilePictureUrl;
  List<UserModel> get cachedExtraParticipants => List.unmodifiable(_cachedExtraParticipants);

  void dismissOngoingGroupCall(String conversationId) {
    _ongoingGroupCalls.remove(conversationId);
  }

  void _updateCallActive(bool active) {
    try {
      if (active) {
        WakelockPlus.enable().catchError((e) {
          debugPrint('CallWebRtcBloc: Wakelock enable error: $e');
        });
      } else {
        WakelockPlus.disable().catchError((e) {
          debugPrint('CallWebRtcBloc: Wakelock disable error: $e');
        });
      }
    } catch (e) {
      debugPrint('CallWebRtcBloc: Wakelock error: $e');
    }
    try {
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        _pipChannel.invokeMethod('setCallActive', {'isActive': active}).catchError((e) {
          debugPrint('CallWebRtcBloc: PipChannel invoke error: $e');
        });
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.resumed && state is CallActive) {
      debugPrint('CallWebRtcBloc: App resumed in CallActive - triggering ReacquireMediaEvent');
      add(const ReacquireMediaEvent());
    }
  }

  CallWebRtcBloc(this._webRtcService, this._repository)
      : super(const CallIdle()) {
    WidgetsBinding.instance.addObserver(this);

    on<InitiateCallEvent>(_onInitiateCall);
    on<AnswerCallEvent>(_onAnswerCall);
    on<HangUpCallEvent>(_onHangUp);
    on<RejectCallEvent>(_onRejectCall);
    on<HandleIncomingCallEvent>(_onHandleIncoming);
    on<ShowIncomingCallUiEvent>(_onShowIncomingCallUi);
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
    on<ReacquireMediaEvent>(_onReacquireMedia);
    on<HandleCallErrorEvent>((event, emit) {
      _cancelCallTimeoutTimer();
      _cancelAllParticipantTimers();
      _activeCallStart = null;
      emit(CallError(event.error));
    });

    // Listen for phone call ended events to recover media tracks immediately
    _phoneCallEndedSubscription = PhoneCallStateService.onPhoneCallEnded.listen((_) {
      debugPrint('CallWebRtcBloc: Native phone call ended received');
      if (state is CallActive) {
        add(const ReacquireMediaEvent());
      }
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
    _socketSubscription = _repository.onMessage.listen((data) async {
      if (data is! Map) return;
      final type = data['type'];
      final conversationId = data['conversation_id'] ?? data['conversationId'];
      
      // Filter signaling by active conversation if applicable
      final activeId = _webRtcService.activeConversationId;
      final isIncomingCallSignal = type == 'call_initiate' ||
          type == 'call_incoming' ||
          type == 'incoming_call' ||
          type == 'call' ||
          type == 'call_offer';

      if (activeId != null && conversationId != null && activeId != conversationId && !isIncomingCallSignal) {
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
        case 'incoming_call':
        case 'call':
          final convoId = (data['conversation_id'] ?? data['conversationId'])?.toString();
          final isGroupVal = data['is_group'] ?? data['isGroup'];
          final bool isGroup = isGroupVal == true || isGroupVal == 1 || isGroupVal == 'true';
          if (isGroup && convoId != null && convoId.isNotEmpty) {
            final isVideo = data['call_type'] == 'video' || data['callType'] == 'video';
            final groupName = (data['group_name'] ?? data['groupName'] ?? data['caller_name'] ?? data['callerName'] ?? 'Group Call').toString();
            final profilePic = (data['profile_picture_url'] ?? data['profilePictureUrl'] ?? data['caller_profile_picture_url'])?.toString();
            final callerId = (data['sender_id'] ?? data['senderId'] ?? data['caller_id'] ?? data['callerId'])?.toString();
            final extractedParts = _extractParticipantsFromEvent(Map<String, dynamic>.from(data), callerName: groupName, profilePic: profilePic);
            final connectedIds = <String>{};
            if (callerId != null && callerId.isNotEmpty) connectedIds.add(callerId);
            final existing = _ongoingGroupCalls[convoId];
            if (existing != null) {
              _ongoingGroupCalls[convoId] = existing.copyWith(
                groupName: groupName.isNotEmpty ? groupName : existing.groupName,
                isVideo: isVideo,
                profilePictureUrl: profilePic ?? existing.profilePictureUrl,
                participants: {...existing.participants, ...extractedParts}.toList(),
                connectedParticipantIds: {...existing.connectedParticipantIds, ...connectedIds},
              );
            } else {
              _ongoingGroupCalls[convoId] = OngoingGroupCall(
                conversationId: convoId,
                groupName: groupName,
                isVideo: isVideo,
                profilePictureUrl: profilePic,
                participants: extractedParts,
                connectedParticipantIds: connectedIds,
                startedAt: DateTime.now(),
              );
            }
          }

          final senderId = (data['sender_id'] ?? data['senderId'] ?? data['caller_id'] ?? data['callerId'] ?? data['user_id'] ?? data['userId'] ?? data['from'])?.toString();
          final myId = getIt<StorageService>().getUserId()?.toString();
          if (senderId != null && myId != null && senderId == myId) {
            debugPrint('CallWebRtcBloc: Ignoring incoming call event from self (myId=$myId, senderId=$senderId)');
            return;
          }
          if (state is CallConnecting) {
            debugPrint('CallWebRtcBloc: Currently making an outgoing call, ignoring incoming call socket event');
            return;
          }
          if (state is CallActive && isGroup && convoId != null && (state as CallActive).conversationId == convoId) {
            debugPrint('CallWebRtcBloc: Already in active call for this group ($convoId). Handling joining peer $senderId directly.');
            final offerMap = data['offer'];
            if (offerMap is Map && senderId != null && senderId.isNotEmpty) {
              _webRtcService.handlePeerOffer(
                peerId: senderId,
                conversationId: convoId,
                offerMap: Map<String, dynamic>.from(offerMap),
                repository: _repository,
                isVideo: (state as CallActive).isVideo,
              );
            }
            add(HandleCallParticipantJoinedEvent(Map<String, dynamic>.from(data)));
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
        case 'call_offer':
        case 'peer_offer':
          final offerSenderId = (data['sender_id'] ?? data['senderId'] ?? data['from'] ?? data['user_id'] ?? data['caller_id'])?.toString() ?? '';
          final targetUserId = (data['target_user_id'] ?? data['targetUserId'] ?? data['recipient_id'] ?? data['recipientId'])?.toString() ?? '';
          final currentMyId = getIt<StorageService>().getUserId()?.toString() ?? '';
          final currentConvoId = (data['conversation_id'] ?? data['conversationId'] ?? _webRtcService.activeConversationId)?.toString() ?? '';
          final offerMap = data['offer'];
          if (offerSenderId.isNotEmpty && offerSenderId != currentMyId && (targetUserId.isEmpty || targetUserId == currentMyId) && offerMap is Map) {
            final isVideoCall = (state is CallActive && (state as CallActive).isVideo) ||
                (state is CallConnecting && (state as CallConnecting).isVideo) ||
                (state is CallRinging && (state as CallRinging).isVideo);
            if (_webRtcService.peerConnection != null && _webRtcService.peerConnections.isEmpty) {
              await _webRtcService.handleOfferForActiveCall(
                offerMap: Map<String, dynamic>.from(offerMap),
                targetUserId: offerSenderId,
                conversationId: currentConvoId,
                repository: _repository,
                isVideo: isVideoCall,
              );
            } else {
              await _webRtcService.handlePeerOffer(
                peerId: offerSenderId,
                conversationId: currentConvoId,
                offerMap: Map<String, dynamic>.from(offerMap),
                repository: _repository,
                isVideo: isVideoCall,
              );
            }
          }
          break;
        case 'call_answer':
        case 'peer_answer':
          final answerSenderId = (data['sender_id'] ?? data['senderId'] ?? data['from'] ?? data['user_id'])?.toString() ?? '';
          final answerTargetUserId = (data['target_user_id'] ?? data['targetUserId'] ?? data['recipient_id'] ?? data['recipientId'])?.toString() ?? '';
          final mySelfId = getIt<StorageService>().getUserId()?.toString() ?? '';
          final answerMap = data['answer'];
          if (answerSenderId.isNotEmpty && answerSenderId != mySelfId && (answerTargetUserId.isEmpty || answerTargetUserId == mySelfId) && answerMap is Map) {
            if (_webRtcService.peerConnection != null && _webRtcService.peerConnections.isEmpty) {
              await _webRtcService.handleCallAnswered(Map<String, dynamic>.from(data), repository: _repository);
            } else {
              await _webRtcService.handlePeerAnswer(
                peerId: answerSenderId,
                answerMap: Map<String, dynamic>.from(answerMap),
              );
            }
          }
          break;
        case 'ice_candidate':
        case 'ice_candidate_received':
          add(HandleIceCandidateEvent(Map<String, dynamic>.from(data)));
          break;
        case 'call_hangup':
        case 'call_disconnected':
        case 'call_disconnect':
        case 'call_ended':
        case 'call_end':
        case 'call_canceled':
        case 'call_cancelled':
        case 'call_cancel':
        case 'call_rejected':
        case 'call_reject':
        case 'call_timeout':
        case 'call_missed':
        case 'missed_call':
          final isGroup = data['is_group'] == true || data['isGroup'] == true;
          final partId = (data['participant_id'] ?? data['sender_id'] ?? data['senderId'] ?? data['user_id'])?.toString();
          if (isGroup && partId != null && partId.isNotEmpty) {
            add(HandleCallParticipantLeftEvent(Map<String, dynamic>.from(data)));
          } else {
            add(const HandleCallDisconnectedEvent());
          }
          break;
        case 'call_video_toggle':
          add(HandleRemoteVideoToggleEvent(data['isVideoOff'] == true));
          break;
        case 'call_mute_status_updated':
          add(HandleRemoteMuteUpdateEvent(
            userId: (data['userId'] ?? data['user_id'] ?? data['sender_id'] ?? data['senderId'])?.toString(),
            isMuted: data['is_muted'] == true || data['isMuted'] == true,
            muteType: (data['mute_type'] ?? data['trackType'] ?? 'audio').toString(),
          ));
          break;
        case 'call_switch_requested':
          add(HandleCallSwitchRequestedEvent(Map<String, dynamic>.from(data)));
          break;
        case 'call_switch_responded':
          add(HandleCallSwitchRespondedEvent(Map<String, dynamic>.from(data)));
          break;
        case 'call_media_restored':
          debugPrint('CallWebRtcBloc: Remote peer restored media after interruption - synchronizing streams');
          if (state is CallActive && _webRtcService.currentRemoteStream != null) {
            _webRtcService.remoteRenderer.srcObject = _webRtcService.currentRemoteStream;
          }
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
  /// Retries up to 15 times (4.5 seconds total) when the app is resuming
  /// from a killed/background state and Flutter hasn't fully initialized yet.
  void navigateToCallPage(Map<String, dynamic> extra) => _navigateToCallPage(extra);

  void _navigateToCallPage(Map<String, dynamic> extra) async {
    add(const SetCallMinimizedEvent(false));
    if (CallWebRtcBloc.isCallScreenMounted) {
      debugPrint('CallWebRtcBloc: Call screen is already mounted, skipping navigation');
      return;
    }

    const maxAttempts = 15;
    const retryDelay = Duration(milliseconds: 300);

    BuildContext? context;
    for (int i = 0; i < maxAttempts; i++) {
      if (CallWebRtcBloc.isCallScreenMounted) {
        debugPrint('CallWebRtcBloc: Call screen became mounted during retry loop');
        return;
      }
      context = navigatorKey.currentContext;
      if (context != null && navigatorKey.currentState != null) break;
      await Future.delayed(retryDelay);
    }

    if (CallWebRtcBloc.isCallScreenMounted) {
      debugPrint('CallWebRtcBloc: Call screen is already mounted after retries');
      return;
    }

    final navState = navigatorKey.currentState;
    if (navState == null && context == null) {
      debugPrint('CallWebRtcBloc: Navigator state/context still null after retries');
      return;
    }

    final isVideo = extra['call_type'] == 'video' || extra['callType'] == 'video';
    final callerName = extra['caller_name'] ?? extra['callerName'] ?? 'Unknown';
    final conversationId = extra['conversation_id'] ?? extra['conversationId'] ?? '';
    final recipientId = extra['recipient_id'] ?? extra['recipientId'] ?? '';
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

    final extraParticipants = (state is CallActive)
        ? (state as CallActive).extraParticipants
        : (state is CallConnecting
            ? (state as CallConnecting).extraParticipants
            : (state is CallRinging ? (state as CallRinging).extraParticipants : <UserModel>[]));

    final route = MaterialPageRoute(
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
                extraParticipants: extraParticipants,
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
                extraParticipants: extraParticipants,
              ),
      ),
    );

    if (navState != null) {
      navState.push(route);
    } else if (context != null && context.mounted) {
      Navigator.of(context).push(route);
    }
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

      // Prevent starting a call if user is already in another call (cellular or VoIP)
      final bool isPhoneActive = await PhoneCallStateService.isPhoneCallActive();
      if (isPhoneActive || state is CallActive || state is CallConnecting || state is CallRinging) {
        debugPrint('CallWebRtcBloc: Cannot start call while already in another call (cellularActive=$isPhoneActive, state=$state)');
        emit(const CallError('Cannot start call while on another call'));
        return;
      }
      
      _cachedConversationId = event.conversationId;
      _cachedContactName = event.contactName;
      _cachedRecipientId = event.recipientId;
      _cachedIsVideo = event.isVideo;
      _cachedIsGroup = event.isGroup;
      _cachedGroupName = event.groupName;
      _cachedProfilePictureUrl = event.profilePictureUrl;
      _cachedExtraParticipants = List.from(event.extraParticipants);

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
        recipientId: event.recipientId, 
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
        recipientId: event.recipientId,
        repository: _repository,
        callerName: myName,
        profilePictureUrl: myPic,
        isGroup: event.isGroup,
        groupName: event.groupName,
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

  bool _isAnsweringCall = false;

  // ─────────────────────────────────────────────
  // ANSWER CALL (Callee)
  // ─────────────────────────────────────────────
  Future<void> _onAnswerCall(
    AnswerCallEvent event,
    Emitter<CallWebRtcState> emit,
  ) async {
    if (_isAnsweringCall || state is CallActive || state is CallConnecting) {
      debugPrint('CallWebRtcBloc: Already answering or in active/connecting call (state=$state). Ignoring duplicate AnswerCallEvent.');
      return;
    }
    _isAnsweringCall = true;

    try {
      _cancelCallTimeoutTimer();
      _notificationService.cancelNotificationBannerOnly();
      // Ensure socket is connected (especially important for background/terminated launches)
      if (!_repository.isConnected) {
        _repository.connect();

        int attempts = 0;
        while (!_repository.isConnected && attempts < 6) {
          await Future.delayed(const Duration(milliseconds: 500));
          attempts++;
        }
      }

      // --- Safe offer decode -------------------------------------------
      final Map<String, dynamic> safeEvent =
          Map<String, dynamic>.from(event.incomingEvent);
      
      // If safeEvent doesn't have an offer, check if current state is CallRinging and merge
      if ((safeEvent['offer'] == null || safeEvent['offer'] == '') && state is CallRinging) {
        final ringingOffer = (state as CallRinging).incomingEvent['offer'] ?? (state as CallRinging).incomingEvent['sdp'];
        if (ringingOffer != null) {
          safeEvent['offer'] = ringingOffer;
        }
      }
      if ((safeEvent['offer'] == null || safeEvent['offer'] == '') && _cachedIncomingEvent != null) {
        final cachedOffer = _cachedIncomingEvent!['offer'] ?? _cachedIncomingEvent!['sdp'];
        if (cachedOffer != null) {
          safeEvent['offer'] = cachedOffer;
        }
      }

      final dynamic rawOffer = safeEvent['offer'];
      if (rawOffer is String && rawOffer.isNotEmpty) {
        final trimmed = rawOffer.trim();
        if (trimmed.startsWith('{')) {
          try {
            safeEvent['offer'] = jsonDecode(trimmed);
          } catch (e) {
            debugPrint('CallWebRtcBloc: Failed to decode offer JSON: $e');
          }
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

      final isVideo = safeEvent['call_type'] == 'video' || safeEvent['callType'] == 'video';
      final callerName = (safeEvent['caller_name'] ?? safeEvent['callerName'] ?? 'Unknown').toString();
      final recipientId = (safeEvent['recipient_id'] ?? safeEvent['recipientId'] ?? '').toString();
      final isGroupVal = safeEvent['is_group'] ?? safeEvent['isGroup'];
      final bool isGroup = isGroupVal == true || isGroupVal == 1 || isGroupVal == 'true';
      final String? groupName = (safeEvent['group_name'] ?? safeEvent['groupName'])?.toString();
      final convoId = (safeEvent['conversation_id'] ?? safeEvent['conversationId'] ?? '').toString();

      final extraPartsFromState = state is CallRinging
          ? (state as CallRinging).extraParticipants
          : (state is CallConnecting ? (state as CallConnecting).extraParticipants : <UserModel>[]);

      final extraParticipants = extraPartsFromState.isNotEmpty
          ? extraPartsFromState
          : _extractParticipantsFromEvent(
              safeEvent,
              callerName: callerName,
              profilePic: profilePic,
              callerDetails: callerDetails,
            );

      final callerId = (safeEvent['sender_id'] ?? safeEvent['senderId'] ?? safeEvent['caller_id'] ?? safeEvent['callerId'])?.toString() ?? '';
      final connectedSet = <String>{};
      if (callerId.isNotEmpty) {
        connectedSet.add(callerId);
      }
      bool ringingSpeaker = isVideo;
      if (state is CallRinging) {
        connectedSet.addAll((state as CallRinging).connectedParticipantIds);
        ringingSpeaker = (state as CallRinging).isSpeakerOn;
      }

      // Cache all metadata
      _cachedConversationId = convoId;
      _cachedContactName = callerName;
      _cachedRecipientId = recipientId;
      _cachedIsVideo = isVideo;
      _cachedIsGroup = isGroup;
      _cachedGroupName = groupName;
      _cachedProfilePictureUrl = profilePic;
      _cachedExtraParticipants = List.from(extraParticipants);

      if (isGroup && convoId.isNotEmpty) {
        _ongoingGroupCalls[convoId] = OngoingGroupCall(
          conversationId: convoId,
          groupName: groupName ?? callerName,
          isVideo: isVideo,
          profilePictureUrl: profilePic,
          participants: extraParticipants,
          connectedParticipantIds: connectedSet,
          startedAt: DateTime.now(),
        );
      }

      emit(CallConnecting(
        conversationId: convoId,
        isVideo: isVideo,
        contactName: callerName,
        recipientId: recipientId,
        isMinimized: false,
        profilePictureUrl: profilePic,
        isGroup: isGroup,
        groupName: groupName,
        extraParticipants: extraParticipants,
        connectedParticipantIds: connectedSet,
      ));

      await _webRtcService.answerCall(
        incomingEvent: safeEvent,
        repository: _repository,
      );
      _soundService.stopAll();

      await _webRtcService.toggleSpeaker(ringingSpeaker);

      _activeCallStart = DateTime.now();
      emit(CallActive(
        conversationId: convoId,
        contactName: callerName,
        recipientId: recipientId,
        isVideo: isVideo,
        isSpeakerOn: ringingSpeaker,
        profilePictureUrl: profilePic,
        isGroup: isGroup,
        groupName: groupName,
        extraParticipants: extraParticipants,
        connectedParticipantIds: connectedSet,
        startedAt: _activeCallStart,
      ));

      if (isGroup && convoId.isNotEmpty) {
        final myId = getIt<StorageService>().getUserId()?.toString() ?? '';
        final myName = getIt<StorageService>().getUsername() ?? '';
        final myPic = getIt<StorageService>().getProfilePic();
        _repository.emit('message', {
          'type': 'call_participant_joined',
          'conversation_id': convoId,
          'user_id': myId,
          'participant_id': myId,
          'sender_id': myId,
          'senderId': myId,
          'user': {
            'id': myId,
            'name': myName,
            'username': myName,
            'profile_picture_url': myPic,
          },
          'is_group': true,
          'isGroup': true,
        });

        // Fallback: If existing peers do not initiate an offer within 2.5s, initiate offer to ensure connection
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (state is CallActive) {
            for (final p in extraParticipants) {
              if (p.id.isNotEmpty && p.id != myId && p.id != callerId) {
                _webRtcService.createOfferForPeer(
                  peerId: p.id,
                  conversationId: convoId,
                  repository: _repository,
                );
              }
            }
          }
        });
      }

      try {
        getIt<CallHistoryCubit>().fetchCallHistory();
      } catch (_) {}

      if (!CallWebRtcBloc.isCallScreenMounted) {
        _navigateToCallPage(safeEvent);
      }
    } catch (e) {
      debugPrint('CallWebRtcBloc: Error answering call: $e');
      emit(CallError('Failed to answer call: $e'));
    } finally {
      _isAnsweringCall = false;
    }
  }

  Future<void> _onHangUp(
    HangUpCallEvent event,
    Emitter<CallWebRtcState> emit,
  ) async {
    _cancelCallTimeoutTimer();
    _soundService.stopAll();
    _notificationService.dismissAllIncomingCalls();

    final currentState = state;
    final isGroupCall = (currentState is CallActive && currentState.isGroup) ||
        (currentState is CallConnecting && currentState.isGroup);

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
      if (remainingConnected.isNotEmpty) {
        _ongoingGroupCalls[convoId] = OngoingGroupCall(
          conversationId: convoId,
          groupName: gName,
          isVideo: isVid,
          profilePictureUrl: pPic,
          participants: parts,
          connectedParticipantIds: remainingConnected,
          startedAt: (currentState is CallActive ? currentState.startedAt : null) ?? DateTime.now(),
        );
      } else {
        _ongoingGroupCalls.remove(convoId);
      }

      // Inform other group members that only this participant has left
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
    try {
      getIt<CallHistoryCubit>().fetchCallHistory();
    } catch (_) {}
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
    _notificationService.dismissAllIncomingCalls();
    _webRtcService.rejectCall(
      conversationId: event.conversationId,
      messageId: event.messageId ?? _activeCallMessageId,
      repository: _repository,
    );
    _activeCallMessageId = null;
    _activeCallStart = null;
    emit(const CallEnded());
    try {
      getIt<CallHistoryCubit>().fetchCallHistory();
    } catch (_) {}
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

    final currentState = state;
    if (currentState is CallConnecting) {
      if (currentState.conversationId.isNotEmpty && currentState.conversationId != incomingConvoId) {
        debugPrint('CallWebRtcBloc: User is currently initiating an outgoing call. Replying busy to $senderId for $incomingConvoId');
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
    }

    // 1. Busy check: if user is already in an ongoing/connecting call from another chat or on a cellular call
    String currentConvoId = '';
    if (currentState is CallActive) {
      currentConvoId = currentState.conversationId;
    } else if (currentState is CallConnecting) {
      currentConvoId = currentState.conversationId;
    } else if (currentState is CallRinging) {
      currentConvoId = (currentState.incomingEvent['conversation_id'] ?? currentState.incomingEvent['conversationId'] ?? '').toString();
    }

    // If we are ALREADY ringing for this same conversation, ignore duplicate event (FCM/socket duplicate)
    if (currentState is CallRinging && currentConvoId.isNotEmpty && currentConvoId == incomingConvoId) {
      debugPrint('CallWebRtcBloc: Already ringing for conversation $incomingConvoId, ignoring duplicate event');
      return;
    }

    final bool isBusyInSchat = (currentState is CallActive &&
            currentConvoId.isNotEmpty &&
            currentConvoId != incomingConvoId) ||
        (currentState is CallConnecting &&
            currentConvoId.isNotEmpty &&
            currentConvoId != incomingConvoId) ||
        (currentState is CallRinging &&
            currentConvoId.isNotEmpty &&
            currentConvoId != incomingConvoId);

    final bool isBusyInCellular = await PhoneCallStateService.isPhoneCallActive();

    if (isBusyInSchat || isBusyInCellular) {
      debugPrint('CallWebRtcBloc: User is already busy on another call (schatBusy=$isBusyInSchat, cellularBusy=$isBusyInCellular). Replying busy to $senderId for $incomingConvoId');
      _soundService.stopAll();
      _notificationService.dismissAllIncomingCalls();
      _repository.emit('message', {
        'type': 'call_response',
        'conversation_id': incomingConvoId,
        'recipient_id': senderId,
        'response': 'busy',
        'reason': 'busy',
        'message': 'Currently other person in call',
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

    final callerId = (event.incomingEvent['sender_id'] ?? event.incomingEvent['senderId'] ?? event.incomingEvent['caller_id'] ?? event.incomingEvent['callerId'])?.toString() ?? '';
    final extraParts = _extractParticipantsFromEvent(
      event.incomingEvent,
      callerName: callerName,
      profilePic: profilePic,
      callerDetails: callerDetails,
    );
    final connectedSet = callerId.isNotEmpty ? {callerId} : <String>{};

    // Cache metadata
    _cachedConversationId = incomingConvoId;
    _cachedContactName = callerName;
    _cachedRecipientId = recipientId;
    _cachedIsVideo = callType == 'video';
    _cachedIsGroup = isGroup;
    _cachedGroupName = groupName;
    _cachedProfilePictureUrl = profilePic;
    _cachedExtraParticipants = List.from(extraParts);
    _cachedIncomingEvent = Map<String, dynamic>.from(event.incomingEvent);

    _soundService.playRingtone();
    emit(CallRinging(
      incomingEvent: event.incomingEvent,
      callerName: callerName,
      recipientId: recipientId,
      isVideo: callType == 'video',
      profilePictureUrl: profilePic,
      isGroup: isGroup,
      groupName: groupName,
      extraParticipants: extraParts,
      connectedParticipantIds: connectedSet,
    ));
    debugPrint('CallWebRtcBloc: Incoming call — type=$callType, isGroup=$isGroup, resolvedCallerName=$callerName, extraParts=${extraParts.length}');

    // Always trigger CallNotificationService (Heads-up notification + CallKit)
    _notificationService.showIncomingCall(event.incomingEvent);
  }

  List<UserModel> _extractParticipantsFromEvent(
    Map<String, dynamic> event, {
    String? callerName,
    String? profilePic,
    dynamic callerDetails,
  }) {
    final rawParts = event['participants'] ?? event['extra_participants'] ?? event['extraParticipants'];
    final List<UserModel> parts = [];
    final myId = getIt<StorageService>().getUserId()?.toString().toLowerCase();
    final callerId = (event['sender_id'] ?? event['senderId'] ?? event['caller_id'] ?? event['callerId'])?.toString() ?? '';

    // Always include caller in the participants list for group calls
    if (callerId.isNotEmpty && callerId.toLowerCase() != myId) {
      parts.add(UserModel(
        id: callerId,
        username: callerDetails is Map ? (callerDetails['username']?.toString() ?? '') : '',
        contactName: callerName ?? (callerDetails is Map ? (callerDetails['name'] ?? callerDetails['username'] ?? '') : '') ?? 'Caller',
        phoneNumber: callerDetails is Map ? (callerDetails['phone_number']?.toString() ?? '') : '',
        profilePictureUrl: profilePic ?? (callerDetails is Map ? (callerDetails['profile_picture_url'] ?? callerDetails['profilePictureUrl']) : null),
      ));
    }

    if (rawParts is List) {
      for (final p in rawParts) {
        if (p is Map) {
          final pid = (p['id'] ?? p['user_id'])?.toString() ?? '';
          if (pid.isNotEmpty && pid.toLowerCase() != myId) {
            final existingIndex = parts.indexWhere((u) => u.id.toLowerCase() == pid.toLowerCase());
            final userModel = UserModel(
              id: pid,
              username: p['username']?.toString() ?? '',
              contactName: p['name']?.toString() ?? p['display_name']?.toString() ?? p['username']?.toString() ?? '',
              phoneNumber: p['phone_number']?.toString() ?? '',
              profilePictureUrl: (p['profile_picture_url'] ?? p['profilePictureUrl'] ?? p['avatar'])?.toString(),
            );
            if (existingIndex >= 0) {
              parts[existingIndex] = userModel;
            } else {
              parts.add(userModel);
            }
          }
        }
      }
    }
    return parts;
  }

  void _onShowIncomingCallUi(
    ShowIncomingCallUiEvent event,
    Emitter<CallWebRtcState> emit,
  ) {
    debugPrint('CallWebRtcBloc: User tapped notification banner to open incoming call UI');
    final currentState = state;
    if (currentState is CallActive || currentState is CallConnecting || currentState is CallRinging) {
      debugPrint('CallWebRtcBloc: Call already active, connecting, or ringing — ignoring UI request');
      return;
    }
    if (currentState is CallIdle || currentState is CallEnded) {
      add(HandleIncomingCallEvent(event.incomingEvent));
    }
  }

  // ─────────────────────────────────────────────
  // CALL ANSWERED (Socket push to caller)
  // ─────────────────────────────────────────────
  Future<void> _onHandleCallAnswered(
    HandleCallAnsweredEvent event,
    Emitter<CallWebRtcState> emit,
  ) async {
    final String type = (event.event['type'] ?? '').toString().toLowerCase();
    final String response = (event.event['response'] ?? event.event['action'] ?? event.event['status'] ?? '').toString().toLowerCase();
    final bool hasAnswer = event.event['answer'] != null || event.event['sdp'] != null;
    final bool isAccept = response == 'accept' || response == 'accepted' || response == 'answer' || response == 'answered' || type == 'call_answered' || (response.isEmpty && hasAnswer);
    final bool isReject = response == 'reject' || response == 'rejected' || response == 'decline' || response == 'declined' || response == 'cancel' || response == 'canceled';
    final bool isBusy = response == 'busy';

    debugPrint('CallWebRtcBloc: _onHandleCallAnswered triggered (type=$type, response=$response, isAccept=$isAccept, isReject=$isReject, isBusy=$isBusy)');

    // 1. Busy response handling
    if (isBusy) {
      final convoId = (event.event['conversation_id'] ?? event.event['conversationId'])?.toString() ?? '';
      if (_cachedConversationId.isNotEmpty && convoId.isNotEmpty && _cachedConversationId != convoId) {
        debugPrint('CallWebRtcBloc: Ignoring busy response for different conversation $convoId');
        return;
      }
      if (state is! CallConnecting && state is! CallRinging) {
        debugPrint('CallWebRtcBloc: Ignoring busy response as we are not connecting/ringing');
        return;
      }
      _cancelCallTimeoutTimer();
      _soundService.stopAll();
      final calleeName = event.event['caller_name'] ?? _cachedContactName;
      final displayName = calleeName.isNotEmpty && calleeName != 'Unknown' ? calleeName : 'User';
      emit(CallRejected(reason: '$displayName is currently in another call'));
      return;
    }

    // 2. Reject response handling
    if (isReject) {
      final currentState = state;
      final senderId = (event.event['sender_id'] ?? event.event['senderId'] ?? event.event['participant_id'])?.toString() ?? '';
      if (currentState is CallActive && currentState.isGroup) {
        debugPrint('CallWebRtcBloc: A group participant declined the call, keeping active group call intact');
        if (senderId.isNotEmpty) {
          _participantTimeoutTimers[senderId]?.cancel();
          final updatedDisconnected = {...currentState.disconnectedParticipantIds, senderId};
          emit(currentState.copyWith(disconnectedParticipantIds: updatedDisconnected));
        }
        return;
      }
      if (currentState is CallConnecting && currentState.isGroup) {
        debugPrint('CallWebRtcBloc: A group participant declined while connecting');
        if (senderId.isNotEmpty) {
          _participantTimeoutTimers[senderId]?.cancel();
          final updatedDisconnected = {...currentState.disconnectedParticipantIds, senderId};
          emit(currentState.copyWith(disconnectedParticipantIds: updatedDisconnected));
        }
        return;
      }
      final convoId = (event.event['conversation_id'] ?? event.event['conversationId'])?.toString() ?? '';
      if (convoId.isNotEmpty) {
        _ongoingGroupCalls.remove(convoId);
      }
      _cancelCallTimeoutTimer();
      _cancelAllParticipantTimers();
      _soundService.stopAll();
      emit(const CallRejected(reason: 'Call declined'));
      return;
    }

    // 3. Accept response handling
    if (isAccept) {
      // If we are currently still in CallRinging (we haven't answered yet),
      // another member in the group answered. We must NOT dismiss our ringing window!
      if (state is CallRinging) {
        debugPrint('CallWebRtcBloc: Another participant answered group call. Retaining CallRinging state.');
        return;
      }

      _cancelCallTimeoutTimer();
      await _webRtcService.handleCallAnswered(event.event, repository: _repository);
      _soundService.stopAll();

      final currentState = state;
      String conversationId = _cachedConversationId.isNotEmpty ? _cachedConversationId : (_webRtcService.activeConversationId ?? '');
      String contactName = _cachedContactName.isNotEmpty ? _cachedContactName : 'User';
      String recipientId = _cachedRecipientId;
      bool isVideo = _cachedIsVideo;
      bool isMinimized = false;
      bool isGroup = _cachedIsGroup;
      String? groupName = _cachedGroupName;
      List<UserModel> extraParticipants = List.from(_cachedExtraParticipants);
      String? profilePic = _cachedProfilePictureUrl;

      final connectedSet = <String>{};
      final disconnectedSet = <String>{};
      if (currentState is CallConnecting) {
        if (currentState.conversationId.isNotEmpty) conversationId = currentState.conversationId;
        if (currentState.contactName.isNotEmpty && currentState.contactName != 'Unknown') contactName = currentState.contactName;
        if (currentState.recipientId.isNotEmpty) recipientId = currentState.recipientId;
        isVideo = currentState.isVideo;
        isMinimized = currentState.isMinimized;
        profilePic = currentState.profilePictureUrl ?? profilePic;
        isGroup = currentState.isGroup;
        groupName = currentState.groupName ?? groupName;
        if (currentState.extraParticipants.isNotEmpty) extraParticipants = currentState.extraParticipants;
        connectedSet.addAll(currentState.connectedParticipantIds);
        disconnectedSet.addAll(currentState.disconnectedParticipantIds);
      } else if (currentState is CallActive) {
        if (currentState.conversationId.isNotEmpty) conversationId = currentState.conversationId;
        if (currentState.contactName.isNotEmpty && currentState.contactName != 'Unknown') contactName = currentState.contactName;
        if (currentState.recipientId.isNotEmpty) recipientId = currentState.recipientId;
        isVideo = currentState.isVideo;
        isMinimized = currentState.isMinimized;
        profilePic = currentState.profilePictureUrl ?? profilePic;
        isGroup = currentState.isGroup;
        groupName = currentState.groupName ?? groupName;
        if (currentState.extraParticipants.isNotEmpty) extraParticipants = currentState.extraParticipants;
        connectedSet.addAll(currentState.connectedParticipantIds);
        disconnectedSet.addAll(currentState.disconnectedParticipantIds);
      } else {
        if (event.event['conversation_id'] != null) {
          conversationId = event.event['conversation_id'].toString();
        }
        final eventCallerName = event.event['caller_name'] ?? event.event['callerName'];
        if (eventCallerName != null && eventCallerName.toString().isNotEmpty && eventCallerName.toString() != 'Unknown') {
          contactName = eventCallerName.toString();
        }
        final eventRecipientId = event.event['recipient_id'] ?? event.event['recipientId'];
        if (eventRecipientId != null && eventRecipientId.toString().isNotEmpty) {
          recipientId = eventRecipientId.toString();
        }
        if (event.event['call_type'] != null || event.event['callType'] != null) {
          isVideo = (event.event['call_type'] ?? event.event['callType']) == 'video';
        }
        if (event.event['is_group'] != null || event.event['isGroup'] != null) {
          isGroup = event.event['is_group'] == true || event.event['isGroup'] == true;
        }
        final gName = (event.event['group_name'] ?? event.event['groupName'])?.toString();
        if (gName != null && gName.isNotEmpty) {
          groupName = gName;
        }
        final callerDetails = event.event['caller_details'] ?? event.event['callerDetails'];
        if (callerDetails is Map) {
          profilePic = callerDetails['profile_picture_url'] ?? callerDetails['profilePictureUrl'] ?? profilePic;
        }
        profilePic ??= event.event['caller_profile_picture_url'] ??
            event.event['profile_picture_url'] ??
            event.event['profilePictureUrl'];
      }

      // Update cached values
      _cachedConversationId = conversationId;
      _cachedContactName = contactName;
      _cachedRecipientId = recipientId;
      _cachedIsVideo = isVideo;
      _cachedIsGroup = isGroup;
      _cachedGroupName = groupName;
      _cachedProfilePictureUrl = profilePic;
      _cachedExtraParticipants = List.from(extraParticipants);
      
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
      
      if (isGroup && conversationId.isNotEmpty && senderId.isNotEmpty) {
        _repository.emit('message', {
          'type': 'call_participant_joined',
          'conversation_id': conversationId,
          'user_id': senderId,
          'participant_id': senderId,
          'sender_id': senderId,
          'user': {
            'id': senderId,
            'name': contactName,
            'username': contactName,
            'profile_picture_url': profilePic,
          },
          'connected_participant_ids': connectedSet.toList(),
          'extra_participants': extraParticipants.map((u) => {
            'id': u.id,
            'name': u.displayName,
            'username': u.username,
            'profile_picture_url': u.profilePictureUrl,
          }).toList(),
          'is_group': true,
          'isGroup': true,
        });
      }

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
    debugPrint('CallWebRtcBloc: Participant joined event: ${event.event} (currentState=$state)');
    if (state is! CallRinging) {
      _soundService.stopAll();
      _cancelCallTimeoutTimer();
    }

    if (event.event['answer'] != null) {
      try {
        await _webRtcService.handleCallAnswered(event.event, repository: _repository);
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
      final pid = (event.event['participant_id'] ?? event.event['user_id'] ?? event.event['sender_id'] ?? event.event['senderId'] ?? event.event['from'])?.toString() ?? '';
      final name = (event.event['name'] ?? event.event['display_name'] ?? event.event['caller_name'] ?? event.event['callerName'] ?? event.event['username'])?.toString() ?? '';
      if (pid.isNotEmpty) {
        user = UserModel(
          id: pid,
          username: (event.event['username'] ?? name).toString(),
          contactName: name.isNotEmpty ? name : 'Participant',
          phoneNumber: (event.event['phone_number'] ?? event.event['phoneNumber'] ?? '').toString(),
          profilePictureUrl: (event.event['profile_picture_url'] ?? event.event['profilePictureUrl'] ?? event.event['avatar'] ?? event.event['caller_profile_picture_url'])?.toString(),
        );
      }
    }

    if (user != null && ((user.contactName?.isEmpty ?? true) || user.contactName == 'Unknown' || user.contactName == 'Participant')) {
      if (user.phoneNumber.isNotEmpty) {
        final saved = await _findContactName(user.phoneNumber);
        if (saved != null && saved.isNotEmpty) {
          user = user.copyWith(contactName: saved);
        }
      }
    }

    if (user == null || user.id.isEmpty) return;
    _participantTimeoutTimers[user.id]?.cancel();
    final myId = getIt<StorageService>().getUserId();
    if (user.id == myId) return;

    final rawConnected = event.event['connected_participant_ids'] ?? event.event['connectedParticipantIds'];
    final Set<String> extraConnected = {};
    if (rawConnected is List) {
      for (final id in rawConnected) {
        if (id != null && id.toString().isNotEmpty) extraConnected.add(id.toString());
      }
    }

    final rawExtraList = event.event['extra_participants'] ?? event.event['extraParticipants'];
    final List<UserModel> moreExtra = [];
    if (rawExtraList is List) {
      for (final p in rawExtraList) {
        if (p is Map) {
          final pid = (p['id'] ?? p['user_id'])?.toString() ?? '';
          if (pid.isNotEmpty && pid.toLowerCase() != myId?.toLowerCase()) {
            moreExtra.add(UserModel(
              id: pid,
              username: p['username']?.toString() ?? '',
              contactName: p['name']?.toString() ?? p['username']?.toString() ?? '',
              phoneNumber: p['phone_number']?.toString() ?? '',
              profilePictureUrl: (p['profile_picture_url'] ?? p['profilePictureUrl'])?.toString(),
            ));
          }
        }
      }
    }

    final convoId = (event.event['conversation_id'] ?? event.event['conversationId'])?.toString() ?? '';
    final isGroupVal = event.event['is_group'] ?? event.event['isGroup'];
    final bool isGroup = isGroupVal == true || isGroupVal == 1 || isGroupVal == 'true' || _ongoingGroupCalls.containsKey(convoId);

    if (convoId.isNotEmpty && isGroup) {
      final currentOngoing = _ongoingGroupCalls[convoId] ?? OngoingGroupCall(
        conversationId: convoId,
        groupName: (event.event['group_name'] ?? event.event['groupName'] ?? 'Group Call').toString(),
        isVideo: event.event['call_type'] == 'video' || event.event['callType'] == 'video',
        profilePictureUrl: (event.event['profile_picture_url'] ?? event.event['profilePictureUrl'])?.toString(),
        participants: [],
        connectedParticipantIds: {},
        startedAt: DateTime.now(),
      );
      final validUser = user;
      final updatedOngoingParts = currentOngoing.participants.map((u) {
        if (u.id.toLowerCase() == validUser.id.toLowerCase()) {
          return u.copyWith(
            profilePictureUrl: (u.profilePictureUrl != null && u.profilePictureUrl!.isNotEmpty)
                ? u.profilePictureUrl
                : validUser.profilePictureUrl,
            contactName: u.displayName.isNotEmpty ? u.displayName : validUser.displayName,
          );
        }
        return u;
      }).toList();
      if (!currentOngoing.participants.any((u) => u.id.toLowerCase() == validUser.id.toLowerCase())) {
        updatedOngoingParts.add(validUser);
      }
      for (final m in moreExtra) {
        if (!updatedOngoingParts.any((u) => u.id.toLowerCase() == m.id.toLowerCase())) {
          updatedOngoingParts.add(m);
        }
      }
      final updatedOngoingConnected = {
        ...currentOngoing.connectedParticipantIds,
        validUser.id,
        ...extraConnected,
      };
      _ongoingGroupCalls[convoId] = currentOngoing.copyWith(
        participants: updatedOngoingParts,
        connectedParticipantIds: updatedOngoingConnected,
      );
      if (state is CallIdle) {
        emit(const CallIdle());
      }
    }

    if (state is CallRinging) {
      debugPrint('CallWebRtcBloc: User ${user.id} joined group call. Local user is still in CallRinging, keeping ringtone active.');
      final current = state as CallRinging;
      final updatedConnected = {...current.connectedParticipantIds, user.id, ...extraConnected};
      emit(current.copyWith(
        connectedParticipantIds: updatedConnected,
      ));
      return;
    }

    // In group calls, initiate a direct WebRTC peer offer to connect audio/video with the joining user
    if (convoId.isNotEmpty && user.id.isNotEmpty && (state is CallActive || state is CallConnecting)) {
      final isVideoCall = (state is CallActive && (state as CallActive).isVideo) ||
          (state is CallConnecting && (state as CallConnecting).isVideo);
      _webRtcService.createOfferForPeer(
        peerId: user.id,
        conversationId: convoId,
        repository: _repository,
        isVideo: isVideoCall,
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
      for (final m in moreExtra) {
        if (!updatedList.any((u) => u.id.toLowerCase() == m.id.toLowerCase())) {
          updatedList.add(m);
        }
      }
      final updatedConnected = {...current.connectedParticipantIds, user.id, ...extraConnected};
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
      for (final m in moreExtra) {
        if (!updatedList.any((u) => u.id.toLowerCase() == m.id.toLowerCase())) {
          updatedList.add(m);
        }
      }
      final updatedConnected = {...current.connectedParticipantIds, user.id, ...extraConnected};
      final updatedDisconnected = current.disconnectedParticipantIds.where((id) => id != user!.id).toSet();
      _activeCallStart ??= DateTime.now();
      emit(CallActive(
        conversationId: current.conversationId,
        contactName: current.contactName,
        recipientId: current.recipientId,
        isVideo: current.isVideo,
        isSpeakerOn: current.isSpeakerOn,
        isMinimized: isCallScreenMounted ? false : current.isMinimized,
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
      for (final m in moreExtra) {
        if (!updatedList.any((u) => u.id.toLowerCase() == m.id.toLowerCase())) {
          updatedList.add(m);
        }
      }
      final updatedConnected = {...current.connectedParticipantIds, user.id, ...extraConnected};
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
    _webRtcService.removePeer(userId);
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
      if (state is CallIdle) {
        emit(const CallIdle());
      }
    }

    final isGroup = event.event['is_group'] == true || event.event['isGroup'] == true;
    final currentState = state;
    final bool isCallGroup = (currentState is CallActive && currentState.isGroup) ||
        (currentState is CallConnecting && currentState.isGroup) ||
        (currentState is CallRinging && currentState.isGroup);

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
        debugPrint('CallWebRtcBloc: All remote participants left, auto-cutting call for ${current.conversationId}');
        _ongoingGroupCalls.remove(current.conversationId);
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
      if (updatedConnected.isEmpty && (current.extraParticipants.isEmpty || current.extraParticipants.every((p) => updatedDisconnected.contains(p.id)))) {
        debugPrint('CallWebRtcBloc: All participants left/rejected during CallConnecting, ending call');
        _ongoingGroupCalls.remove(current.conversationId);
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
    if (currentState is CallActive && currentState.isGroup && currentState.connectedParticipantIds.isNotEmpty) {
      debugPrint('CallWebRtcBloc: Remote party disconnected from group call. Remaining in call.');
      return;
    }

    _activeCallStart = null;
    _cancelCallTimeoutTimer();
    _cancelAllParticipantTimers();
    _soundService.stopAll();
    _notificationService.dismissAllIncomingCalls();
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
    try {
      getIt<CallHistoryCubit>().fetchCallHistory();
    } catch (_) {}
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
      final uid = event.userId;
      if (event.muteType == 'audio') {
        final updatedMuted = Set<String>.from(current.mutedParticipantIds);
        if (uid != null && uid.isNotEmpty) {
          if (event.isMuted) {
            updatedMuted.add(uid);
          } else {
            updatedMuted.remove(uid);
          }
        }
        emit(current.copyWith(
          isRemoteMuted: event.isMuted,
          mutedParticipantIds: updatedMuted,
        ));
      } else if (event.muteType == 'video') {
        final updatedVideoOff = Set<String>.from(current.videoOffParticipantIds);
        if (uid != null && uid.isNotEmpty) {
          if (event.isMuted) {
            updatedVideoOff.add(uid);
          } else {
            updatedVideoOff.remove(uid);
          }
        }
        emit(current.copyWith(
          isRemoteVideoOff: event.isMuted,
          videoOffParticipantIds: updatedVideoOff,
        ));
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
    WidgetsBinding.instance.removeObserver(this);
    _phoneCallEndedSubscription?.cancel();
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

  Future<void> _onAddParticipants(
      AddParticipantsCallEvent event, Emitter<CallWebRtcState> emit) async {
    if (event.users.isEmpty) return;

    final currentState = state;
    if (currentState is! CallActive && currentState is! CallConnecting) return;

    final bool isVideo = currentState is CallActive
        ? currentState.isVideo
        : (currentState as CallConnecting).isVideo;
    final String conversationId = currentState is CallActive
        ? currentState.conversationId
        : (currentState as CallConnecting).conversationId;
    final String contactName = currentState is CallActive
        ? currentState.contactName
        : (currentState as CallConnecting).contactName;
    final String? groupName = currentState is CallActive
        ? currentState.groupName
        : (currentState as CallConnecting).groupName;
    final List<UserModel> currentExtra = currentState is CallActive
        ? currentState.extraParticipants
        : (currentState as CallConnecting).extraParticipants;
    final String recipientId = currentState is CallActive
        ? currentState.recipientId
        : (currentState as CallConnecting).recipientId;

    final existingIds = currentExtra.map((u) => u.id).toSet();
    if (recipientId.isNotEmpty) existingIds.add(recipientId);
    final newUsers =
        event.users.where((u) => !existingIds.contains(u.id)).toList();
    if (newUsers.isEmpty) return;

    final updated = [...currentExtra, ...newUsers];
    if (currentState is CallActive) {
      emit(currentState.copyWith(extraParticipants: updated, isGroup: true));
    } else if (currentState is CallConnecting) {
      emit(currentState.copyWith(extraParticipants: updated, isGroup: true));
    }

    final offerData = await _webRtcService.getCurrentOrNewOffer(isVideo: isVideo);

    for (final user in newUsers) {
      _startParticipantTimeout(user.id, conversationId: conversationId);
      _repository.emit('message', {
        'type': 'call_initiate',
        'conversation_id': conversationId,
        'recipient_id': user.id,
        'recipientId': user.id,
        'call_type': isVideo ? 'video' : 'audio',
        'caller_name': contactName,
        'is_group': true,
        'isGroup': true,
        'group_name': ?groupName,
        'groupName': ?groupName,
        'offer': ?offerData,
      });
    }
  }

  Future<void> _onReinviteParticipant(
    ReinviteParticipantCallEvent event,
    Emitter<CallWebRtcState> emit,
  ) async {
    final user = event.user;
    if (user.id.isEmpty) return;

    final currentState = state;
    if (currentState is! CallActive && currentState is! CallConnecting) return;

    final String convoId = currentState is CallActive
        ? currentState.conversationId
        : (currentState as CallConnecting).conversationId;
    final bool isVid = currentState is CallActive
        ? currentState.isVideo
        : (currentState as CallConnecting).isVideo;
    final String cName = currentState is CallActive
        ? currentState.contactName
        : (currentState as CallConnecting).contactName;
    final String? gName = currentState is CallActive
        ? currentState.groupName
        : (currentState as CallConnecting).groupName;
    final Set<String> discSet = currentState is CallActive
        ? currentState.disconnectedParticipantIds
        : (currentState as CallConnecting).disconnectedParticipantIds;
    final List<UserModel> extraList = currentState is CallActive
        ? currentState.extraParticipants
        : (currentState as CallConnecting).extraParticipants;

    final updatedDisconnected =
        discSet.where((id) => id != user.id).toSet();
    final existingIds = extraList.map((u) => u.id).toSet();
    final updatedList = existingIds.contains(user.id)
        ? extraList
        : [...extraList, user];

    if (currentState is CallActive) {
      emit(currentState.copyWith(
        disconnectedParticipantIds: updatedDisconnected,
        extraParticipants: updatedList,
        isGroup: true,
      ));
    } else if (currentState is CallConnecting) {
      emit(currentState.copyWith(
        disconnectedParticipantIds: updatedDisconnected,
        extraParticipants: updatedList,
        isGroup: true,
      ));
    }

    final offerData = await _webRtcService.getCurrentOrNewOffer(isVideo: isVid);

    if (convoId.isNotEmpty) {
      _startParticipantTimeout(user.id, conversationId: convoId);
      _repository.emit('message', {
        'type': 'call_initiate',
        'conversation_id': convoId,
        'recipient_id': user.id,
        'recipientId': user.id,
        'call_type': isVid ? 'video' : 'audio',
        'caller_name': cName,
        'is_group': true,
        'isGroup': true,
        'group_name': ?gName,
        'groupName': ?gName,
        'offer': ?offerData,
      });
    }
  }

  Future<void> _onReacquireMedia(
    ReacquireMediaEvent event,
    Emitter<CallWebRtcState> emit,
  ) async {
    if (state is! CallActive) return;
    final active = state as CallActive;
    debugPrint('CallWebRtcBloc: Executing _onReacquireMedia for conversation ${active.conversationId}');
    await _webRtcService.reacquireMediaAfterInterruption(
      isVideo: active.isVideo,
      repository: _repository,
      isSpeakerOn: active.isSpeakerOn,
    );
  }
}

