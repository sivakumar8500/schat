import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_endpoints.dart';

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
    // Suppress foreground FCM if socket is likely handling it via CallWebRtcBloc.
    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) print('FCM Foreground Message: ${message.data}');
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

  Future<void> showIncomingCall(Map<String, dynamic> data) async {
    if (kIsWeb) {
      debugPrint('CallNotificationService: showIncomingCall skipped on Web');
      return;
    }
    final String uuid = _uuid.v4();
    final String callerName = data['caller_name'] ?? 'Unknown';
    final String conversationId = data['conversation_id'] ?? '';
    final bool isVideo = data['call_type'] == 'video';
    final callerDetails = data['caller_details'] ?? data['callerDetails'];
    String? profilePicUrl;
    if (callerDetails is Map) {
      profilePicUrl = callerDetails['profile_picture_url'] ??
          callerDetails['profilePictureUrl'];
    }
    profilePicUrl ??= data['caller_profile_picture_url'] ??
        data['profile_picture_url'] ??
        data['profilePictureUrl'] ??
        '';

    // FCM delivers all payload values as Strings — parse `offer` to a Map.
    final dynamic offerParsed = _tryParseJson(data['offer']);

    final CallKitParams params = CallKitParams(
      id: uuid,
      nameCaller: callerName,
      appName: 'sChat',
      avatar: profilePicUrl,
      handle: 'Incoming ${isVideo ? 'Video' : 'Audio'} Call',
      type: isVideo ? 1 : 0,
      duration: 30000,
      extra: <String, dynamic>{
        'conversation_id': conversationId,
        'caller_name': callerName,
        'call_type': data['call_type'],
        'offer': offerParsed,
        'recipient_id': data['recipient_id'],
        'profile_picture_url': profilePicUrl,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0F3460',
        backgroundUrl: 'https://i.pravatar.cc/500',
        actionColor: '#4CAF50',
        incomingCallNotificationChannelName: 'Incoming Call',
        textAccept: 'Accept',
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

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('FCM Background Message received: ${message.data}');
    if (message.data['type'] != 'call_initiate') return;

    final Uuid uuid = const Uuid();
    final String callUuid = uuid.v4();
    final String callerName = message.data['caller_name'] ?? 'Unknown';
    final bool isVideo = message.data['call_type'] == 'video';

    // FCM delivers all values as Strings — parse `offer` JSON string to Map.
    final dynamic offerParsed = _tryParseJson(message.data['offer']);

    final dynamic callerDetailsRaw =
        message.data['caller_details'] ?? message.data['callerDetails'];
    final dynamic callerDetailsParsed = _tryParseJson(callerDetailsRaw);
    String? profilePicUrl;
    if (callerDetailsParsed is Map) {
      profilePicUrl = callerDetailsParsed['profile_picture_url'] ??
          callerDetailsParsed['profilePictureUrl'];
    }
    profilePicUrl ??= message.data['caller_profile_picture_url'] ??
        message.data['profile_picture_url'] ??
        message.data['profilePictureUrl'];

    final Map<String, dynamic> extra = {
      ...message.data,
      'offer': offerParsed,
      'profile_picture_url': profilePicUrl,
    };

    final CallKitParams params = CallKitParams(
      id: callUuid,
      nameCaller: callerName,
      appName: 'sChat',
      avatar: profilePicUrl,
      handle: 'Incoming ${isVideo ? 'Video' : 'Audio'} Call',
      type: isVideo ? 1 : 0,
      duration: 30000,
      extra: extra,
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0F3460',
        actionColor: '#4CAF50',
        incomingCallNotificationChannelName: 'Incoming Call',
        textAccept: 'Accept',
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
  }
}
