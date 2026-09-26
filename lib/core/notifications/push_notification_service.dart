import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/chat_screen/src/presentation/chat_page.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_bloc.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_event.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_state.dart';
import 'package:schat/main.dart';
import 'package:schat/utils/common_endpoints.dart';
import 'package:schat/injection.dart';
import 'package:schat/core/notifications/in_app_notification_service.dart';

@lazySingleton
class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  Map<String, dynamic>? _pendingNotificationData;
  Map<String, dynamic>? get pendingNotificationData => _pendingNotificationData;

  Future<void> initialize() async {
    if (_initialized) return;
    
    // Request permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    debugPrint('PushNotificationService: User granted permission: ${settings.authorizationStatus}');

    // Enable foreground notification presentation options for iOS
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Configure local notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create high-priority Android Notification Channel
    final androidPlugin = _localNotifications
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
      await androidPlugin.requestNotificationsPermission();
    }

    // Setup foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle tap on background message
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle cold-boot launch from FCM notification
    try {
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('PushNotificationService: App opened from cold-boot FCM message: ${initialMessage.data}');
        _queueOrExecuteNotification(initialMessage.data);
      }
    } catch (e) {
      debugPrint('PushNotificationService: Error getting initial FCM message: $e');
    }

    // Handle cold-boot launch from Local notification
    try {
      final launchDetails = await _localNotifications.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final payload = launchDetails.notificationResponse?.payload;
        debugPrint('PushNotificationService: App opened from cold-boot local notification payload: $payload');
        if (payload != null && payload.isNotEmpty) {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            _queueOrExecuteNotification(decoded);
          } else if (decoded is Map) {
            _queueOrExecuteNotification(Map<String, dynamic>.from(decoded));
          }
        }
      }
    } catch (e) {
      debugPrint('PushNotificationService: Error getting local notification launch details: $e');
    }

    _initialized = true;
  }

  Future<void> registerToken() async {
    try {
      debugPrint('==================================================');
      debugPrint('🔔 [FCM] Requesting FCM Token from Firebase...');
      final token = await _fcm.getToken();
      if (token != null) {
        debugPrint('==================================================');
        debugPrint('🔑 [FCM TOKEN ACQUIRED]:\n$token');
        debugPrint('==================================================');
        await _syncTokenWithBackend(token);
      } else {
        debugPrint('⚠️ [FCM] Token is null. Ensure Firebase is configured.');
      }
      
      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint('==================================================');
        debugPrint('🔄 [FCM TOKEN REFRESHED]:\n$newToken');
        debugPrint('==================================================');
        _syncTokenWithBackend(newToken);
      });
    } catch (e, st) {
      debugPrint('❌ [FCM] Error getting/registering token: $e');
      debugPrint('Stack trace: $st');
    }
  }

  Future<void> _syncTokenWithBackend(String token) async {
    try {
      final storage = getIt<StorageService>();
      final deviceId = storage.getOrGenerateDeviceId();
      final apiService = getIt<ApiService>();

      String platform = 'android';
      if (kIsWeb) {
        platform = 'web';
      } else if (Platform.isIOS) {
        platform = 'ios';
      } else if (Platform.isAndroid) {
        platform = 'android';
      }

      final payload = {
        'device_id': deviceId,
        'deviceId': deviceId,
        'fcm_token': token,
        'fcmToken': token,
        'push_token': token,
        'pushToken': token,
        'token': token,
        'platform': platform,
        'device_type': platform,
      };

      debugPrint('--------------------------------------------------');
      debugPrint('🚀 [FCM -> SERVER] REGISTERING DEVICE:');
      debugPrint('URL: ${CommonEndpoints.baseUrl}${CommonEndpoints.registerDevice}');
      debugPrint('FCM Token: $token');
      debugPrint('Device ID: $deviceId');
      debugPrint('Platform: $platform');
      debugPrint('Payload JSON: ${jsonEncode(payload)}');
      debugPrint('--------------------------------------------------');

      final response = await apiService.post(
        CommonEndpoints.registerDevice,
        data: payload,
      );

      debugPrint('--------------------------------------------------');
      debugPrint('✅ [SERVER -> FCM] DEVICE REGISTRATION RESPONSE:');
      debugPrint('Result: $response');
      debugPrint('--------------------------------------------------');
    } catch (e, st) {
      debugPrint('--------------------------------------------------');
      debugPrint('❌ [SERVER -> FCM] FAILED TO REGISTER DEVICE TOKEN:');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $st');
      debugPrint('--------------------------------------------------');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('PushNotificationService: Received foreground message: ${message.messageId}');
    
    final type = message.data['type'];
    if (type == 'call_initiate' || type == 'call_incoming') {
      try {
        final webrtcBloc = getIt<CallWebRtcBloc>();
        if (webrtcBloc.state is CallIdle) {
          webrtcBloc.add(HandleIncomingCallEvent(Map<String, dynamic>.from(message.data)));
        }
      } catch (_) {}
      return;
    }

    final myId = getIt<StorageService>().getUserId();
    final senderId = (message.data['sender_id'] ?? message.data['senderId'])?.toString();
    if (senderId != null && myId != null && senderId == myId) {
      debugPrint('PushNotificationService: Ignoring notification from self');
      return;
    }

    final recipientId = (message.data['recipient_id'] ?? message.data['recipientId'] ?? message.data['receiver_id'] ?? message.data['receiverId'])?.toString();
    if (recipientId != null && recipientId.isNotEmpty && myId != null && myId.isNotEmpty && recipientId != myId) {
      debugPrint('PushNotificationService: Suppressing push not intended for user $myId (meant for $recipientId)');
      return;
    }

    final convId = (message.data['conversationId'] ?? message.data['conversation_id'])?.toString();
    try {
      final inAppService = getIt<InAppNotificationService>();
      if (inAppService.isChatActive(conversationId: convId, senderId: senderId)) {
        debugPrint('PushNotificationService: Suppressing notification because user is actively chatting with $senderId / conv $convId');
        return;
      }
    } catch (_) {}

    _showLocalNotification(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('PushNotificationService: Message opened app: ${message.messageId}, data: ${message.data}');
    _queueOrExecuteNotification(message.data);
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('PushNotificationService: Local notification tapped: ${response.payload}');
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final data = jsonDecode(response.payload!);
        if (data is Map<String, dynamic>) {
          _queueOrExecuteNotification(data);
        } else if (data is Map) {
          _queueOrExecuteNotification(Map<String, dynamic>.from(data));
        }
      } catch (e) {
        debugPrint('PushNotificationService: Failed to parse notification payload: $e');
      }
    }
  }

  void _queueOrExecuteNotification(Map<String, dynamic> data) {
    _pendingNotificationData = Map<String, dynamic>.from(data);
    final navState = navigatorKey.currentState;
    if (navState != null) {
      handlePendingNotification();
    }
  }

  /// Applies pending notification if the app UI is ready (e.g. DashboardPage is mounted)
  void handlePendingNotification() {
    if (_pendingNotificationData == null) return;
    
    final navState = navigatorKey.currentState;
    if (navState == null) {
      debugPrint('PushNotificationService: Navigator state not ready yet, keeping pending notification');
      return;
    }

    final data = Map<String, dynamic>.from(_pendingNotificationData!);
    _pendingNotificationData = null;
    debugPrint('PushNotificationService: Applying notification action: $data');

    final type = data['type']?.toString();
    if (type == 'screen_permission_request') {
      try {
        getIt<InAppNotificationService>().checkPendingScreenPermissions();
      } catch (e) {
        debugPrint('PushNotificationService: Error triggering screen permission check: $e');
      }
      return;
    }

    if (type == 'call_initiate' || type == 'call_incoming') {
      try {
        final webrtcBloc = getIt<CallWebRtcBloc>();
        if (webrtcBloc.state is CallIdle) {
          webrtcBloc.add(HandleIncomingCallEvent(data));
        }
      } catch (e) {
        debugPrint('PushNotificationService: Error triggering call event: $e');
      }
      return;
    }

    final convId = (data['conversationId'] ?? data['conversation_id'])?.toString();
    final senderName = (data['sender_name'] ?? data['senderName'] ?? data['name'] ?? data['username'] ?? data['title'] ?? 'sChat').toString();
    final senderId = (data['sender_id'] ?? data['senderId'] ?? '').toString();

    if (convId != null && convId.isNotEmpty) {
      _navigateToConversation(convId, senderName, senderId);
    }
  }

  void _navigateToConversation(String convId, String contactName, String recipientId) {
    final navState = navigatorKey.currentState;
    if (navState == null) {
      debugPrint('PushNotificationService: NavigatorState is null cannot navigate to conversation $convId');
      return;
    }

    debugPrint('PushNotificationService: Navigating to ChatPage convId=$convId contact=$contactName recipient=$recipientId');
    navState.push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          conversationId: convId,
          contactName: contactName.isNotEmpty ? contactName : 'sChat',
          contactColor: const Color(0xFF00873C),
          isOnline: true,
          recipientId: recipientId,
        ),
      ),
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final type = message.data['type']?.toString();
    if (type == 'call_initiate' || type == 'call_incoming') {
      return;
    }

    final notification = message.notification;
    String title = notification?.title ?? '';
    String body = notification?.body ?? '';

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

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'schat_general_channel', // id
      'General Notifications', // name
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

    await _localNotifications.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }
}
