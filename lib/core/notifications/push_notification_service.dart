import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_service.dart';
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
    );
    
    debugPrint('PushNotificationService: User granted permission: ${settings.authorizationStatus}');
    
    // Configure local notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Setup foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle tap on background message
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    _initialized = true;
  }

  Future<void> registerToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        debugPrint('PushNotificationService: FCM Token: $token');
        await _syncTokenWithBackend(token);
      }
      
      _fcm.onTokenRefresh.listen((newToken) {
        _syncTokenWithBackend(newToken);
      });
    } catch (e) {
      debugPrint('PushNotificationService: Error getting/registering token: $e');
    }
  }

  Future<void> _syncTokenWithBackend(String token) async {
    try {
      final apiService = getIt<ApiService>();
      await apiService.post(
        CommonEndpoints.registerFcmToken,
        data: {'fcmToken': token},
      );
      debugPrint('PushNotificationService: Token synced with backend');
    } catch (e) {
      debugPrint('PushNotificationService: Failed to sync token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('PushNotificationService: Received foreground message: ${message.messageId}');
    
    final type = message.data['type'];
    if (type == 'call_incoming') {
      // Calls are usually handled by CallNotificationService (CallKit), we can skip local notification for it
      // if CallNotificationService already intercepts via its own handler or socket.
      // But if we want to show standard notification fallback:
      return;
    }
    
    _showLocalNotification(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('PushNotificationService: Message opened app: ${message.messageId}');
    // Navigate based on message data
    final type = message.data['type'];
    if (type == 'chat') {
      final conversationId = message.data['conversationId'];
      // Navigate to chat
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('PushNotificationService: Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        // Handle navigation based on data
      } catch (e) {
        debugPrint('PushNotificationService: Failed to parse notification payload: $e');
      }
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'schat_general_channel', // id
      'General Notifications', // name
      channelDescription: 'Notifications for chats and other alerts',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
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

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }
}
