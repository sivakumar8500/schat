import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_bloc.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_event.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_state.dart';
import 'package:schat/features/call_screen/src/domain/call_sound_service.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_endpoints.dart';
import 'package:schat/core/services/phone_call_state_service.dart';

@pragma('vm:entry-point')
void callNotificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('CallNotificationService: Background notification action tapped: ${notificationResponse.actionId}');
  CallNotificationService.handleBackgroundNotificationAction(notificationResponse);
}

@pragma('vm:entry-point')
@lazySingleton
class CallNotificationService {
  final ApiService _apiService;
  final StorageService _storageService;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final Uuid _uuid = const Uuid();
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const String _callChannelId = 'schat_calls_channel_v5';
  static const String _callChannelName = 'Incoming Calls';

  CallNotificationService(this._apiService, this._storageService);

  // Stream to notify the app when a call is answered from CallKit or Notification
  final _answerCallController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onCallAnswered => _answerCallController.stream;

  static bool _isLocalNotificationsInitialized = false;

  /// Formatted call notification logger for clean debugging
  static void printCallLog({
    required String stage,
    String? callType,
    String? callerName,
    String? conversationId,
    List<String>? availableButtons,
    String? actionClicked,
    Map<String, dynamic>? payload,
    dynamic exception,
    StackTrace? stackTrace,
    String? note,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('\n**************************************************');
    buffer.writeln('📞 CALL NOTIFICATION LOG: $stage');
    buffer.writeln('--------------------------------------------------');
    if (callerName != null && callerName.isNotEmpty) {
      buffer.writeln('👤 Caller Name      : $callerName');
    }
    if (callType != null && callType.isNotEmpty) {
      buffer.writeln('📱 Call Type        : $callType');
    }
    if (conversationId != null && conversationId.isNotEmpty) {
      buffer.writeln('💬 Conversation ID  : $conversationId');
    }
    if (availableButtons != null && availableButtons.isNotEmpty) {
      buffer.writeln('🔘 Available Buttons: [ ${availableButtons.join(' , ')} ]');
    }
    if (actionClicked != null && actionClicked.isNotEmpty) {
      buffer.writeln('👉 Action Clicked   : $actionClicked');
    }
    if (note != null && note.isNotEmpty) {
      buffer.writeln('ℹ️ Note             : $note');
    }
    if (payload != null && payload.isNotEmpty) {
      buffer.writeln('📦 Payload Data     : $payload');
    }
    if (exception != null) {
      buffer.writeln('⚠️ EXCEPTION DETECTED:');
      buffer.writeln('   $exception');
      if (stackTrace != null) {
        buffer.writeln('   $stackTrace');
      }
    } else {
      buffer.writeln('✅ Exception        : None');
    }
    buffer.writeln('**************************************************\n');
    print(buffer.toString());
  }

  static Future<void> _ensureLocalNotificationsInitialized() async {
    if (_isLocalNotificationsInitialized) return;

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
    final initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'CALL_CATEGORY',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              'decline_call',
              'Decline',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.destructive,
              },
            ),
            DarwinNotificationAction.plain(
              'answer_call',
              'Accept',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
          options: <DarwinNotificationCategoryOption>{
            DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
            DarwinNotificationCategoryOption.allowAnnouncement,
          },
        ),
        DarwinNotificationCategory(
          'call_category',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              'decline_call',
              'Decline',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.destructive,
              },
            ),
            DarwinNotificationAction.plain(
              'answer_call',
              'Accept',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
          options: <DarwinNotificationCategoryOption>{
            DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
            DarwinNotificationCategoryOption.allowAnnouncement,
          },
        ),
      ],
    );

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: callNotificationTapBackground,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      const callChannel = AndroidNotificationChannel(
        _callChannelId,
        _callChannelName,
        description: 'Incoming video and audio calls with Decline and Accept actions',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );
      await androidPlugin.createNotificationChannel(callChannel);
      try {
        await androidPlugin.requestNotificationsPermission();
      } catch (_) {}
    }

    _isLocalNotificationsInitialized = true;
  }

  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('CallNotificationService: Skipping initialization on Web');
      return;
    }

    await _ensureLocalNotificationsInitialized();

    // Handle background actions from CallKit
    FlutterCallkitIncoming.onEvent.listen(_onCallKitEvent);

    // Check for any active accepted calls on cold launch
    try {
      final dynamic activeCalls = await FlutterCallkitIncoming.activeCalls();
      if (activeCalls is List && activeCalls.isNotEmpty) {
        debugPrint('CallNotificationService: Found ${activeCalls.length} active calls on cold launch');
        for (final dynamic call in activeCalls) {
          Map<String, dynamic>? extra;
          bool isAccepted = false;
          if (call is CallKitParams) {
            extra = call.extra != null ? Map<String, dynamic>.from(call.extra!) : null;
            isAccepted = (call as dynamic).isAccepted == true;
          } else if (call is Map) {
            final rawExtra = call['extra'];
            if (rawExtra is Map) {
              extra = Map<String, dynamic>.from(rawExtra);
            }
            isAccepted = call['isAccepted'] == true || call['accepted'] == true;
          }
          if (isAccepted && extra != null && extra.isNotEmpty) {
            printCallLog(
              stage: 'COLD LAUNCH ACTIVE CALL DETECTED',
              callerName: extra['caller_name']?.toString() ?? extra['name']?.toString(),
              callType: extra['call_type']?.toString(),
              conversationId: extra['conversation_id']?.toString(),
              actionClicked: 'Auto-accepted from CallKit cold launch',
              payload: extra,
            );
            dismissAllIncomingCalls();
            final normalised = _normaliseExtra(extra);
            _answerCallController.add(normalised);
            getIt<CallWebRtcBloc>().add(AnswerCallEvent(normalised));
          }
        }
      }
    } catch (e, st) {
      printCallLog(
        stage: 'ERROR CHECKING ACTIVE CALLS ON LAUNCH',
        exception: e,
        stackTrace: st,
      );
    }

    // Listen for foreground FCM messages.
    FirebaseMessaging.onMessage.listen((message) {
      final data = message.data;
      final type = (data['type'] ?? data['action'] ?? data['event'] ?? '').toString().toLowerCase();
      final callerInfo = _extractCallerInfo(data);
      final isCall = type == 'call_initiate' ||
          type == 'call_incoming' ||
          type == 'incoming_call' ||
          type == 'call' ||
          type == 'call_offer' ||
          data.containsKey('offer') ||
          data.containsKey('call_type');

      if (isCall) {
        printCallLog(
          stage: 'FOREGROUND NOTIFICATION RECEIVED (CALL)',
          callerName: callerInfo.name,
          callType: data['call_type']?.toString() ?? 'audio',
          conversationId: data['conversation_id']?.toString(),
          availableButtons: ['Accept (Green)', 'Decline (Red)'],
          payload: data,
          note: 'App in foreground: triggering internal incoming call dialog & WebRTC signaling',
        );

        try {
          final webrtcBloc = getIt<CallWebRtcBloc>();
          if (webrtcBloc.state is! CallActive && webrtcBloc.state is! CallConnecting) {
            webrtcBloc.add(HandleIncomingCallEvent(Map<String, dynamic>.from(data)));
          }
        } catch (e, st) {
          printCallLog(
            stage: 'ERROR IN FOREGROUND CALL HANDLER',
            callerName: callerInfo.name,
            conversationId: data['conversation_id']?.toString(),
            exception: e,
            stackTrace: st,
          );
        }
      } else if (type == 'call_hangup' ||
                 type == 'call_ended' ||
                 type == 'call_end' ||
                 type == 'call_cancel' ||
                 type == 'call_canceled' ||
                 type == 'call_cancelled' ||
                 type == 'call_disconnected' ||
                 type == 'call_disconnect' ||
                 type == 'call_rejected' ||
                 type == 'call_reject' ||
                 type == 'call_timeout' ||
                 type == 'call_missed' ||
                 type == 'missed_call') {
        printCallLog(
          stage: 'FOREGROUND CALL TERMINATED / CANCELLED',
          callerName: callerInfo.name,
          conversationId: data['conversation_id']?.toString(),
          payload: data,
          note: 'Event type: $type. Dismissing notifications & CallKit.',
        );
        dismissAllIncomingCalls();
        try {
          getIt<CallSoundService>().stopAll();
          getIt<CallWebRtcBloc>().add(const HandleCallDisconnectedEvent());
        } catch (e, st) {
          printCallLog(
            stage: 'ERROR STOPPING CALL ON FCM CANCEL',
            exception: e,
            stackTrace: st,
          );
        }
      }
    });
  }

  /// Public method to register device (called on login/auth state change)
  Future<void> registerDevice() async {
    if (kIsWeb) return;
    try {
      if (Platform.isIOS) {
        try {
          String? apnsToken = await _fcm.getAPNSToken();
          if (apnsToken == null) {
            await Future.delayed(const Duration(milliseconds: 1000));
            apnsToken = await _fcm.getAPNSToken();
          }
        } catch (_) {}
      }
      final token = await _fcm.getToken();
      if (token != null) {
        await _registerDeviceWithToken(token);
      } else {
        debugPrint('CallNotificationService: Failed to get FCM token for manual registration');
      }
      
      // Listen to token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint('FCM TOKEN REFRESHED: $newToken');
        _registerDeviceWithToken(newToken);
      });
    } catch (e) {
      debugPrint('CallNotificationService: Error fetching FCM token: $e');
    }
  }

  /// Registers the device token on the server
  Future<void> _registerDeviceWithToken(String token) async {
    final deviceId = _storageService.getOrGenerateDeviceId();
    String deviceType = 'unknown';
    if (kIsWeb) {
      deviceType = 'web';
    } else if (Platform.isAndroid) {
      deviceType = 'android';
    } else if (Platform.isIOS) {
      deviceType = 'ios';
    }

    debugPrint('CallNotificationService: Registering device: id=$deviceId, type=$deviceType, token=$token');

    final result = await _apiService.post<dynamic>(
      CommonEndpoints.registerDevice,
      data: {
        'device_id': deviceId,
        'deviceId': deviceId,
        'push_token': token,
        'pushToken': token,
        'fcm_token': token,
        'fcmToken': token,
        'token': token,
        'device_type': deviceType,
        'platform': deviceType,
      },
    );

    result.when(
      success: (_) {
        debugPrint('CallNotificationService: Device registered successfully');
      },
      failure: (message, statusCode) {
        debugPrint('CallNotificationService: Failed to register device: $message (status: $statusCode)');
      },
    );
  }

  static String _resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final base = CommonEndpoints.baseUrl.endsWith('/')
        ? CommonEndpoints.baseUrl.substring(0, CommonEndpoints.baseUrl.length - 1)
        : CommonEndpoints.baseUrl;
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$base$path';
  }

  static ({String name, String avatar}) _extractCallerInfo(Map<String, dynamic> data) {
    final dynamic callerDetailsRaw = data['caller_details'] ?? data['callerDetails'];
    final dynamic callerDetails = _tryParseJson(callerDetailsRaw);

    String name = (data['caller_name'] ??
            data['callerName'] ??
            data['name'] ??
            data['username'] ??
            '')
        .toString()
        .trim();

    String avatar = (data['caller_profile_picture_url'] ??
            data['profile_picture_url'] ??
            data['profilePictureUrl'] ??
            data['avatar'] ??
            '')
        .toString()
        .trim();

    if (callerDetails is Map) {
      if (name.isEmpty || name == 'Unknown' || name == 'null') {
        name = (callerDetails['name'] ??
                callerDetails['username'] ??
                callerDetails['phone_number'] ??
                callerDetails['phoneNumber'] ??
                '')
            .toString()
            .trim();
      }
      if (avatar.isEmpty || avatar == 'null') {
        avatar = (callerDetails['profile_picture_url'] ??
                callerDetails['profilePictureUrl'] ??
                callerDetails['avatar'] ??
                '')
            .toString()
            .trim();
      }
    }

    if (name.isEmpty || name == 'null') {
      name = 'Unknown';
    }

    final resolvedAvatar = _resolveImageUrl(avatar);
    return (name: name, avatar: resolvedAvatar);
  }

  static DateTime? _lastCallKitShowTime;

  /// Displays the incoming call heads-up notification and CallKit UI
  Future<void> showIncomingCall(Map<String, dynamic> data) async {
    if (kIsWeb) {
      debugPrint('CallNotificationService: showIncomingCall skipped on Web');
      return;
    }

    final String conversationId = (data['conversation_id'] ?? data['conversationId'] ?? '').toString();
    final String senderId = (data['sender_id'] ?? data['senderId'] ?? data['caller_id'] ?? data['callerId'])?.toString() ?? '';

    final bool isPhoneActive = await PhoneCallStateService.isPhoneCallActive();
    bool isDifferentSchatCallActive = false;

    if (getIt.isRegistered<CallWebRtcBloc>()) {
      final currentState = getIt<CallWebRtcBloc>().state;
      if (currentState is CallActive) {
        if (conversationId.isNotEmpty && currentState.conversationId != conversationId) {
          isDifferentSchatCallActive = true;
        }
      } else if (currentState is CallConnecting) {
        if (conversationId.isNotEmpty && currentState.conversationId != conversationId) {
          isDifferentSchatCallActive = true;
        }
      }
    }

    if (isPhoneActive || isDifferentSchatCallActive) {
      debugPrint('CallNotificationService: Suppressing incoming call heads-up UI because user is currently in another call (phone: $isPhoneActive, diffSchat: $isDifferentSchatCallActive)');
      if (getIt.isRegistered<ChatSocketRepository>()) {
        getIt<ChatSocketRepository>().emit('message', {
          'type': 'call_response',
          'conversation_id': conversationId,
          'recipient_id': senderId,
          'response': 'busy',
          'reason': 'busy',
          'message': 'Currently other person in call',
          'caller_name': getIt<StorageService>().getUsername() ?? 'User',
        });
      }
      return;
    }

    _lastCallKitShowTime = DateTime.now();
    final String uuid = _uuid.v4();
    final callerInfo = _extractCallerInfo(data);
    final String callerName = callerInfo.name;
    final String profilePicUrl = callerInfo.avatar;
    final bool isVideo = data['call_type'] == 'video' || data['callType'] == 'video';
    final bool isGroup = data['is_group'] == true ||
        data['is_group'] == 'true' ||
        data['isGroup'] == true ||
        data['isGroup'] == 'true';
    final String groupName = (data['group_name'] ?? data['groupName'] ?? '').toString().trim();
    final String notificationTitle = (isGroup && groupName.isNotEmpty) ? groupName : callerName;
    final String callSubtitle = isGroup && groupName.isNotEmpty
        ? '$callerName started a group ${isVideo ? 'video' : 'voice'} call'
        : 'Incoming ${isVideo ? 'video' : 'voice'} call';

    // FCM delivers all payload values as Strings — parse `offer` to a Map/SDP string safely.
    dynamic rawOffer = data['offer'] ?? data['sdp'] ?? data['offer_sdp'] ?? data['offerSdp'];
    if (rawOffer == null && data['data'] is Map) {
      rawOffer = data['data']['offer'] ?? data['data']['sdp'];
    }
    final dynamic offerParsed = _tryParseJson(rawOffer);

    final Map<String, dynamic> extra = {
      ...data,
      'call_uuid': uuid,
      'conversation_id': conversationId,
      'caller_name': callerName,
      'group_name': groupName,
      'is_group': isGroup,
      'call_type': data['call_type'] ?? (isVideo ? 'video' : 'audio'),
      'offer': offerParsed,
      'recipient_id': data['recipient_id'] ?? data['recipientId'],
      'profile_picture_url': profilePicUrl,
      'avatar': profilePicUrl,
    };

    final isForeground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (!isForeground) {
      printCallLog(
        stage: 'DISPLAYING HEADS-UP CALL NOTIFICATION (BACKGROUND)',
        callerName: notificationTitle,
        callType: isVideo ? 'Video Call' : 'Voice Call',
        conversationId: conversationId,
        availableButtons: ['Accept (Green Button)', 'Decline (Red Button)'],
        payload: extra,
        note: 'Showing heads-up notification with Accept / Decline action buttons',
      );
      await _showLocalCallNotification(uuid, notificationTitle, callSubtitle, extra);
    }
  }

  /// Displays high priority heads-up notification with action buttons
  static Future<void> _showLocalCallNotification(
    String callUuid,
    String callerName,
    String subText,
    Map<String, dynamic> extra,
  ) async {
    try {
      await _ensureLocalNotificationsInitialized();

      printCallLog(
        stage: 'DISPLAYING HEADS-UP NOTIFICATION BANNER',
        callerName: callerName,
        callType: extra['call_type']?.toString(),
        conversationId: extra['conversation_id']?.toString(),
        availableButtons: ['Accept (Action Button)', 'Decline (Action Button)'],
        payload: extra,
        note: 'Showing notification banner with Accept/Decline action buttons',
      );

      // Cancel previous notifications so Android does not group them together
      try {
        await _localNotifications.cancelAll();
      } catch (_) {}

      final androidDetails = AndroidNotificationDetails(
        _callChannelId,
        _callChannelName,
        icon: '@mipmap/launcher_icon',
        channelDescription: 'Incoming video and audio calls',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.call,
        fullScreenIntent: true,
        playSound: true,
        enableVibration: true,
        ongoing: true,
        autoCancel: false,
        timeoutAfter: 35000,
        color: const Color(0xFF1F2C34),
        colorized: true,
        subText: 'Incoming Call',
        styleInformation: BigTextStyleInformation(
          subText,
          contentTitle: callerName,
          summaryText: 'sChat Call',
          htmlFormatBigText: false,
          htmlFormatContentTitle: false,
        ),
        groupKey: 'schat_active_call_group',
        setAsGroupSummary: false,
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            'decline_call',
            'Decline',
            titleColor: Color(0xFFFF3B30),
            showsUserInterface: false,
            cancelNotification: true,
            contextual: false,
          ),
          AndroidNotificationAction(
            'answer_call',
            'Accept',
            titleColor: Color(0xFF00BFA5),
            showsUserInterface: true,
            cancelNotification: true,
            contextual: false,
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
        categoryIdentifier: 'CALL_CATEGORY',
        interruptionLevel: InterruptionLevel.critical,
      );

      await _localNotifications.show(
        id: callUuid.hashCode,
        title: callerName,
        body: subText,
        notificationDetails: NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: jsonEncode(extra),
      );
    } catch (e, st) {
      printCallLog(
        stage: 'ERROR SHOWING LOCAL NOTIFICATION BANNER',
        callerName: callerName,
        exception: e,
        stackTrace: st,
      );
    }
  }

  bool _isProgrammaticDismiss = false;

  /// Cancels local notification banners without ending active CallKit calls
  Future<void> cancelNotificationBannerOnly() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      debugPrint('CallNotificationService: Error cancelling notification banners: $e');
    }
  }

  /// Cancels all active call notifications and ends CallKit
  Future<void> dismissAllIncomingCalls() async {
    try {
      _isProgrammaticDismiss = true;
      await _localNotifications.cancelAll();
      await FlutterCallkitIncoming.endAllCalls();
    } catch (e) {
      debugPrint('CallNotificationService: Error dismissing incoming calls: $e');
    } finally {
      Future.delayed(const Duration(milliseconds: 1000), () {
        _isProgrammaticDismiss = false;
      });
    }
  }

  void _onCallKitEvent(CallEvent? event) {
    if (event == null) return;
    if (_isProgrammaticDismiss) {
      debugPrint('CallKit: Ignoring event during programmatic dismiss: $event');
      return;
    }

    if (event is CallEventActionCallAccept) {
      final raw = Map<String, dynamic>.from(event.callKitParams.extra ?? {});
      printCallLog(
        stage: 'CALLKIT ACTION EVENT: ACCEPTED',
        callerName: raw['caller_name']?.toString() ?? raw['name']?.toString(),
        callType: raw['call_type']?.toString(),
        conversationId: raw['conversation_id']?.toString(),
        availableButtons: ['Accept (Clicked)', 'Decline'],
        actionClicked: 'Accept (CallKit Screen)',
        payload: raw,
        note: 'User tapped Accept on CallKit screen. Navigating to active call.',
      );

      cancelNotificationBannerOnly();
      final normalised = _normaliseExtra(raw);
      _answerCallController.add(normalised);
    } else if (event is CallEventActionCallDecline) {
      final raw = Map<String, dynamic>.from(event.callKitParams.extra ?? {});
      final conversationId = raw['conversation_id'] as String?;

      printCallLog(
        stage: 'CALLKIT ACTION EVENT: DECLINED',
        callerName: raw['caller_name']?.toString() ?? raw['name']?.toString(),
        callType: raw['call_type']?.toString(),
        conversationId: conversationId,
        availableButtons: ['Accept', 'Decline (Clicked)'],
        actionClicked: 'Decline (CallKit Screen)',
        payload: raw,
      );

      final isForeground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
      if (isForeground) {
        debugPrint('CallKit: Ignoring CallDecline because app is in foreground');
        return;
      }
      // Ignore spurious immediate declines from OS / CallKit initialization (< 3.0s)
      if (_lastCallKitShowTime != null &&
          DateTime.now().difference(_lastCallKitShowTime!).inMilliseconds < 3000) {
        debugPrint('CallKit: Ignoring auto/spurious CallDecline received within 3s of incoming call');
        return;
      }
      final webrtcBloc = getIt<CallWebRtcBloc>();
      // ONLY reject if we are actually in a ringing incoming call (callee)
      if (webrtcBloc.state is! CallRinging) {
        debugPrint('CallKit: Ignoring CallDecline because state is not CallRinging (state=${webrtcBloc.state})');
        return;
      }
      dismissAllIncomingCalls();

      if (conversationId != null && conversationId.isNotEmpty) {
        try {
          webrtcBloc.add(RejectCallEvent(conversationId));
        } catch (_) {}
      }
    }
  }

  static void onLocalNotificationResponse(NotificationResponse response) {
    _onLocalNotificationResponse(response);
  }

  static void _onLocalNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    Map<String, dynamic> extra = {};
    if (payload != null && payload.isNotEmpty) {
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map) extra = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }

    final conversationId = extra['conversation_id']?.toString() ?? extra['conversationId']?.toString();
    final action = (response.actionId ?? '').toLowerCase();

    if (action == 'decline_call' || action == 'decline' || action == 'reject') {
      printCallLog(
        stage: 'NOTIFICATION BANNER ACTION: DECLINE CLICKED',
        callerName: extra['caller_name']?.toString() ?? extra['name']?.toString(),
        callType: extra['call_type']?.toString(),
        conversationId: conversationId,
        availableButtons: ['Accept', 'Decline (Clicked)'],
        actionClicked: 'Decline Button (Notification Banner)',
        payload: extra,
      );

      final webrtcBloc = getIt<CallWebRtcBloc>();
      if (webrtcBloc.state is! CallRinging) {
        debugPrint('CallNotificationService: Ignoring decline action because state is not CallRinging');
        return;
      }
      try {
        getIt<CallNotificationService>().dismissAllIncomingCalls();
        if (conversationId != null && conversationId.isNotEmpty) {
          getIt<ChatSocketRepository>().emit('message', {
            'type': 'call_response',
            'conversation_id': conversationId,
            'response': 'reject',
            'answer': null,
          });
          webrtcBloc.add(RejectCallEvent(conversationId));
        }
      } catch (e, st) {
        printCallLog(
          stage: 'ERROR DECLINING CALL FROM NOTIFICATION',
          conversationId: conversationId,
          exception: e,
          stackTrace: st,
        );
      }
    } else if (action == 'answer_call' || action == 'accept_call' || action == 'accept') {
      printCallLog(
        stage: 'NOTIFICATION BANNER ACTION: ACCEPT CLICKED',
        callerName: extra['caller_name']?.toString() ?? extra['name']?.toString(),
        callType: extra['call_type']?.toString(),
        conversationId: conversationId,
        availableButtons: ['Accept (Clicked)', 'Decline'],
        actionClicked: 'Accept Button (Notification Banner)',
        payload: extra,
        note: 'Accept button pressed -> opening app directly into active call',
      );

      try {
        final instance = getIt<CallNotificationService>();
        instance.cancelNotificationBannerOnly();
        final normalised = instance._normaliseExtra(extra);
        final webrtcBloc = getIt<CallWebRtcBloc>();
        webrtcBloc.add(AnswerCallEvent(normalised));
        webrtcBloc.navigateToCallPage(normalised);
      } catch (e, st) {
        printCallLog(
          stage: 'ERROR ANSWERING CALL FROM NOTIFICATION',
          conversationId: conversationId,
          exception: e,
          stackTrace: st,
        );
      }
    } else {
      // User tapped notification body -> open incoming call dialog/screen with Accept & Decline without ending the ringing call
      printCallLog(
        stage: 'NOTIFICATION BANNER BODY TAPPED (OPEN INCOMING CALL SCREEN)',
        callerName: extra['caller_name']?.toString() ?? extra['name']?.toString(),
        callType: extra['call_type']?.toString(),
        conversationId: conversationId,
        availableButtons: ['Accept', 'Decline'],
        actionClicked: 'Notification Body Clicked -> Opens Incoming Call UI',
        payload: extra,
      );

      try {
        getIt<CallNotificationService>().cancelNotificationBannerOnly();
        final webrtcBloc = getIt<CallWebRtcBloc>();
        webrtcBloc.add(ShowIncomingCallUiEvent(extra));
      } catch (e, st) {
        printCallLog(
          stage: 'ERROR OPENING INCOMING CALL UI FROM NOTIFICATION BODY',
          conversationId: conversationId,
          exception: e,
          stackTrace: st,
        );
      }
    }
  }

  @pragma('vm:entry-point')
  static void handleBackgroundNotificationAction(NotificationResponse response) {
    printCallLog(
      stage: 'BACKGROUND NOTIFICATION ACTION CLICKED',
      actionClicked: response.actionId ?? 'Unknown Action',
      availableButtons: ['Accept', 'Decline'],
    );
    final action = (response.actionId ?? '').toLowerCase();
    if (action == 'decline_call' || action == 'decline' || action == 'reject') {
      FlutterCallkitIncoming.endAllCalls();
      FlutterLocalNotificationsPlugin().cancelAll();
    } else if (action == 'answer_call' || action == 'accept_call' || action == 'accept') {
      FlutterCallkitIncoming.endAllCalls();
      FlutterLocalNotificationsPlugin().cancelAll();
    }
  }

  /// Normalises extras from CallKit, ensuring `offer` is preserved as Map or String.
  Map<String, dynamic> _normaliseExtra(Map<String, dynamic> extra) {
    dynamic rawOffer = extra['offer'] ?? extra['sdp'] ?? extra['offer_sdp'] ?? extra['offerSdp'];
    if (rawOffer == null && extra['data'] is Map) {
      rawOffer = extra['data']['offer'] ?? extra['data']['sdp'];
    }
    return {
      ...extra,
      'offer': _tryParseJson(rawOffer),
    };
  }

  /// If [value] is a JSON string, decode it to a [Map]/[List]; otherwise return as-is.
  static dynamic _tryParseJson(dynamic value) {
    if (value is String && value.isNotEmpty) {
      final trimmed = value.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          return jsonDecode(trimmed);
        } catch (_) {
          return value;
        }
      }
      return value;
    }
    return value;
  }

  // ─────────────────────────────────────────────────────────────
  // Static background FCM handler (runs in isolate, no DI/getIt)
  // ─────────────────────────────────────────────────────────────

  @pragma('vm:entry-point')
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    Map<String, dynamic> data = Map<String, dynamic>.from(message.data);

    if (data.containsKey('data') && data['data'] is String) {
      try {
        final nested = jsonDecode(data['data'] as String);
        if (nested is Map) {
          data.addAll(Map<String, dynamic>.from(nested));
        }
      } catch (_) {}
    } else if (data.containsKey('payload') && data['payload'] is String) {
      try {
        final nested = jsonDecode(data['payload'] as String);
        if (nested is Map) {
          data.addAll(Map<String, dynamic>.from(nested));
        }
      } catch (_) {}
    }

    final String type = (data['type'] ?? data['action'] ?? data['event'] ?? data['message_type'] ?? '').toString().toLowerCase();

    final bool isCallEnd = type == 'call_hangup' ||
        type == 'call_ended' ||
        type == 'call_end' ||
        type == 'call_cancel' ||
        type == 'call_canceled' ||
        type == 'call_cancelled' ||
        type == 'call_disconnected' ||
        type == 'call_disconnect' ||
        type == 'call_rejected' ||
        type == 'call_reject' ||
        type == 'call_timeout' ||
        type == 'call_missed' ||
        type == 'missed_call';

    if (isCallEnd) {
      printCallLog(
        stage: 'BACKGROUND FCM MESSAGE: CALL TERMINATED / CANCELLED',
        conversationId: data['conversation_id']?.toString(),
        payload: data,
        note: 'Call ended/cancelled ($type). Ending all active calls & notifications in background.',
      );
      try {
        await FlutterCallkitIncoming.endAllCalls();
        final localNotifications = FlutterLocalNotificationsPlugin();
        await localNotifications.cancelAll();
      } catch (e, st) {
        printCallLog(
          stage: 'ERROR DISMISSING CALLS IN BACKGROUND FCM HANDLER',
          exception: e,
          stackTrace: st,
        );
      }
      return;
    }

    final bool isCall = type == 'call_initiate' ||
        type == 'call_incoming' ||
        type == 'incoming_call' ||
        type == 'call' ||
        type == 'call_offer' ||
        data.containsKey('call_type') ||
        data.containsKey('callType') ||
        data.containsKey('offer');

    // 1. Incoming Call (High-Priority Heads-Up Notification with Decline & Accept Buttons)
    if (isCall) {
      final bool isPhoneActive = await PhoneCallStateService.isPhoneCallActive();
      if (isPhoneActive) {
        printCallLog(
          stage: 'BACKGROUND FCM MESSAGE: INCOMING CALL SUPPRESSED',
          conversationId: data['conversation_id']?.toString(),
          payload: data,
          note: 'User is active on another call (cellular/phone). Skipping incoming call notification.',
        );
        return;
      }

      final Uuid uuid = const Uuid();
      final String callUuid = uuid.v4();
      final callerInfo = _extractCallerInfo(data);
      final String callerName = callerInfo.name;
      final String profilePicUrl = callerInfo.avatar;
      final bool isVideo = data['call_type'] == 'video' || data['callType'] == 'video';
      final bool isGroup = data['is_group'] == true ||
          data['is_group'] == 'true' ||
          data['isGroup'] == true ||
          data['isGroup'] == 'true';
      final String groupName = (data['group_name'] ?? data['groupName'] ?? '').toString().trim();
      final String notificationTitle = (isGroup && groupName.isNotEmpty) ? groupName : callerName;
      final String callSubtitle = isGroup && groupName.isNotEmpty
          ? '$callerName started a group ${isVideo ? 'video' : 'voice'} call'
          : 'Incoming ${isVideo ? 'video' : 'voice'} call';

      dynamic rawOffer = data['offer'] ?? data['sdp'] ?? data['offer_sdp'] ?? data['offerSdp'];
      if (rawOffer == null && data['data'] is Map) {
        rawOffer = data['data']['offer'] ?? data['data']['sdp'];
      }
      final dynamic offerParsed = _tryParseJson(rawOffer);

      final Map<String, dynamic> extra = {
        ...data,
        'call_uuid': callUuid,
        'offer': offerParsed,
        'caller_name': callerName,
        'group_name': groupName,
        'is_group': isGroup,
        'profile_picture_url': profilePicUrl,
        'avatar': profilePicUrl,
      };

      printCallLog(
        stage: 'BACKGROUND FCM MESSAGE: INCOMING CALL RECEIVED',
        callerName: notificationTitle,
        callType: isVideo ? 'Video Call' : 'Voice Call',
        conversationId: data['conversation_id']?.toString(),
        availableButtons: ['Accept (Green Button)', 'Decline (Red Button)'],
        payload: extra,
        note: 'CallKit handles native heads-up banner on Android without duplicate local notification',
      );

      await _showLocalCallNotification(callUuid, notificationTitle, callSubtitle, extra);
      return;
    }

    // 2. Chat / Data Message (System Notification)
    try {
      final notification = message.notification;
      // If Firebase already displayed a notification for notification payload on Android, skip to avoid duplicates
      if (notification != null) {
        return;
      }
      String title = '';
      String body = '';

      if (title.isEmpty) {
        title = (message.data['title'] ??
                message.data['sender_name'] ??
                message.data['senderName'] ??
                message.data['name'] ??
                message.data['username'] ??
                'sChat')
            .toString();
      }

      if (body.isEmpty) {
        final content = message.data['body'] ??
            message.data['message'] ??
            message.data['content'] ??
            message.data['text'];
        if (content is Map) {
          body = (content['text'] ?? 'New message received').toString();
        } else if (content is String && content.isNotEmpty) {
          body = content;
        } else {
          body = 'New message received';
        }
      }

      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveBackgroundNotificationResponse: callNotificationTapBackground,
      );

      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        const channel = AndroidNotificationChannel(
          'schat_general_channel',
          'General Notifications',
          description: 'Notifications for chats and other alerts',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );
        await androidPlugin.createNotificationChannel(channel);
      }

      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'schat_general_channel',
        'General Notifications',
        channelDescription: 'Notifications for chats and other alerts',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/launcher_icon',
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          htmlFormatBigText: false,
          htmlFormatContentTitle: false,
        ),
        category: AndroidNotificationCategory.message,
      );
      const iOSPlatformChannelSpecifics = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );
      final platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      final int notificationId =
          message.messageId?.hashCode ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);

      await flutterLocalNotificationsPlugin.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: platformChannelSpecifics,
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      debugPrint('CallNotificationService: Error displaying background chat notification: $e');
    }
  }
}

