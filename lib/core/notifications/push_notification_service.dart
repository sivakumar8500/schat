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
import 'package:schat/main.dart';
import 'package:schat/utils/common_endpoints.dart';
import 'package:schat/injection.dart';

@lazySingleton
class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;

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

    // Handle cold-boot launch from notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
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
      // Calls are handled by CallNotificationService/CallKit
      return;
    }

    final senderId = (message.data['sender_id'] ?? message.data['senderId'])?.toString();
    final myId = getIt<StorageService>().getUserId();
    if (senderId != null && myId != null && senderId == myId) {
      debugPrint('PushNotificationService: Ignoring notification from self');
      return;
    }
    
    _showLocalNotification(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('PushNotificationService: Message opened app: ${message.messageId}');
    final convId = (message.data['conversationId'] ?? message.data['conversation_id'])?.toString();
    final senderName = (message.data['sender_name'] ?? message.data['senderName'] ?? message.data['title'] ?? 'sChat').toString();
    final senderId = (message.data['sender_id'] ?? message.data['senderId'] ?? '').toString();

    if (convId != null && convId.isNotEmpty) {
      _navigateToConversation(convId, senderName, senderId);
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('PushNotificationService: Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        if (data is Map) {
          final convId = (data['conversationId'] ?? data['conversation_id'])?.toString();
          final senderName = (data['sender_name'] ?? data['senderName'] ?? data['title'] ?? 'sChat').toString();
          final senderId = (data['sender_id'] ?? data['senderId'] ?? '').toString();

          if (convId != null && convId.isNotEmpty) {
            _navigateToConversation(convId, senderName, senderId);
          }
        }
      } catch (e) {
        debugPrint('PushNotificationService: Failed to parse notification payload: $e');
      }
    }
  }

  void _navigateToConversation(String convId, String contactName, String recipientId) {
    final navState = navigatorKey.currentState;
    if (navState == null) return;

    navState.push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          conversationId: convId,
          contactName: contactName,
          contactColor: const Color(0xFF00873C),
          isOnline: true,
          recipientId: recipientId,
        ),
      ),
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    String title = notification?.title ?? '';
    String body = notification?.body ?? '';

    if (title.isEmpty) {
      title = (message.data['title'] ??
              message.data['sender_name'] ??
              message.data['senderName'] ??
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

    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'schat_general_channel', // id
      'General Notifications', // name
      channelDescription: 'Notifications for chats and other alerts',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/launcher_icon',
    );
    const iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const platformChannelSpecifics = NotificationDetails(
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
