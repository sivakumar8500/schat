import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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
import 'package:schat/injection.dart';
import 'package:schat/utils/common_endpoints.dart';

@pragma('vm:entry-point')
@lazySingleton
class CallNotificationService {
  final ApiService _apiService;
  final StorageService _storageService;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final Uuid _uuid = const Uuid();

  CallNotificationService(this._apiService, this._storageService);

  // Stream to notify the app when a call is answered from CallKit
  final _answerCallController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onCallAnswered => _answerCallController.stream;

  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('CallNotificationService: Skipping initialization on Web');
      return;
    }

    // Handle background actions from CallKit
    FlutterCallkitIncoming.onEvent.listen(_onCallKitEvent);

    // Listen for foreground messages.
    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) print('FCM Foreground Message: ${message.data}');
      final type = message.data['type']?.toString();
      if (type == 'call_initiate' || type == 'call_incoming') {
        try {
          final webrtcBloc = getIt<CallWebRtcBloc>();
          if (webrtcBloc.state is CallIdle) {
            webrtcBloc.add(HandleIncomingCallEvent(Map<String, dynamic>.from(message.data)));
          }
        } catch (e) {
          debugPrint('CallNotificationService: Error handling foreground call message: $e');
        }
      }
    });
  }

  /// Public method to register device (called on login/auth state change)
  Future<void> registerDevice() async {
    if (kIsWeb) return;
    try {
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
    // Allow device registration without auth token as per new requirements
    // if (!_storageService.hasToken()) {
    //   debugPrint('CallNotificationService: User not authenticated, skipping token registration');
    //   return;
    // }

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
        'push_token': token,
        'device_type': deviceType,
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

  Future<void> showIncomingCall(Map<String, dynamic> data) async {
    if (kIsWeb) {
      debugPrint('CallNotificationService: showIncomingCall skipped on Web');
      return;
    }
    final String uuid = _uuid.v4();
    final callerInfo = _extractCallerInfo(data);
    final String callerName = callerInfo.name;
    final String profilePicUrl = callerInfo.avatar;
    final String conversationId = (data['conversation_id'] ?? data['conversationId'] ?? '').toString();
    final bool isVideo = data['call_type'] == 'video' || data['callType'] == 'video';

    // FCM delivers all payload values as Strings — parse `offer` to a Map.
    final dynamic offerParsed = _tryParseJson(data['offer']);

    final CallKitParams params = CallKitParams(
      id: uuid,
      nameCaller: callerName,
      appName: 'sChat',
      avatar: profilePicUrl.isNotEmpty ? profilePicUrl : null,
      handle: 'Incoming ${isVideo ? 'Video' : 'Audio'} Call',
      type: isVideo ? 1 : 0,
      duration: 30000,
      extra: <String, dynamic>{
        'conversation_id': conversationId,
        'caller_name': callerName,
        'call_type': data['call_type'] ?? (isVideo ? 'video' : 'audio'),
        'offer': offerParsed,
        'recipient_id': data['recipient_id'] ?? data['recipientId'],
        'profile_picture_url': profilePicUrl,
        'avatar': profilePicUrl,
      },
      android: const AndroidParams(
        isCustomNotification: false,
        isShowLogo: false,
        isShowCallID: true,
        isShowFullLockedScreen: true,
        isFullScreen: true,
        isImportant: true,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0F3460',
        actionColor: '#4CAF50',
        textColor: '#FFFFFF',
        incomingCallNotificationChannelName: 'Incoming Calls',
        textAccept: 'Answer',
        textDecline: 'Decline',
      ),
      ios: const IOSParams(
        iconName: 'AppIcon',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: true,
        supportsUngrouping: true,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    try {
      await FlutterCallkitIncoming.showCallkitIncoming(params);
    } catch (e) {
      debugPrint('CallNotificationService: Error showing CallKit: $e');
    }
  }

  void _onCallKitEvent(CallEvent? event) {
    if (event == null) return;

    if (event is CallEventActionCallAccept) {
      debugPrint('CallKit: Call Accepted');
      final raw = Map<String, dynamic>.from(event.callKitParams.extra ?? {});
      // CallKit may re-serialize the offer map as a JSON string — parse it back.
      _answerCallController.add(_normaliseExtra(raw));
    } else if (event is CallEventActionCallDecline) {
      debugPrint('CallKit: Call Declined');
      final raw = Map<String, dynamic>.from(event.callKitParams.extra ?? {});
      final conversationId = raw['conversation_id'] as String?;

      if (conversationId != null) {
        getIt<ChatSocketRepository>().emit('message', {
          'type': 'call_response',
          'conversation_id': conversationId,
          'response': 'reject',
          'answer': null,
        });
      }
    }
  }

  /// Normalises extras from CallKit, ensuring `offer` is a [Map] not a JSON string.
  Map<String, dynamic> _normaliseExtra(Map<String, dynamic> extra) {
    return {
      ...extra,
      'offer': _tryParseJson(extra['offer']),
    };
  }

  /// If [value] is a JSON string, decode it to a [Map]/[List]; otherwise return as-is.
  static dynamic _tryParseJson(dynamic value) {
    if (value is String && value.isNotEmpty) {
      try {
        return jsonDecode(value);
      } catch (_) {
        return null;
      }
    }
    return value;
  }

  // ─────────────────────────────────────────────────────────────
  // Static background FCM handler (runs in isolate, no DI/getIt)
  // ─────────────────────────────────────────────────────────────

  @pragma('vm:entry-point')
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('FCM Background Message received: ${message.data}');
    final type = message.data['type']?.toString();

    // 1. Incoming Call (CallKit VoIP)
    if (type == 'call_initiate' || type == 'call_incoming') {
      final Uuid uuid = const Uuid();
      final String callUuid = uuid.v4();
      final callerInfo = _extractCallerInfo(message.data);
      final String callerName = callerInfo.name;
      final String profilePicUrl = callerInfo.avatar;
      final bool isVideo = message.data['call_type'] == 'video' || message.data['callType'] == 'video';

      final dynamic offerParsed = _tryParseJson(message.data['offer']);

      final Map<String, dynamic> extra = {
        ...message.data,
        'offer': offerParsed,
        'caller_name': callerName,
        'profile_picture_url': profilePicUrl,
        'avatar': profilePicUrl,
      };

      final CallKitParams params = CallKitParams(
        id: callUuid,
        nameCaller: callerName,
        appName: 'sChat',
        avatar: profilePicUrl.isNotEmpty ? profilePicUrl : null,
        handle: 'Incoming ${isVideo ? 'Video' : 'Audio'} Call',
        type: isVideo ? 1 : 0,
        duration: 30000,
        extra: extra,
        android: const AndroidParams(
          isCustomNotification: false,
          isShowLogo: false,
          isShowCallID: true,
          isShowFullLockedScreen: true,
          isFullScreen: true,
          isImportant: true,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0F3460',
          actionColor: '#4CAF50',
          textColor: '#FFFFFF',
          incomingCallNotificationChannelName: 'Incoming Calls',
          textAccept: 'Answer',
          textDecline: 'Decline',
        ),
        ios: const IOSParams(
          iconName: 'AppIcon',
          handleType: 'generic',
          supportsVideo: true,
          maximumCallGroups: 1,
          maximumCallsPerCallGroup: 1,
          ringtonePath: 'system_ringtone_default',
        ),
      );
      await FlutterCallkitIncoming.showCallkitIncoming(params);
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

      await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);

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
