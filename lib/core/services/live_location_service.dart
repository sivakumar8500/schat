import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/injection.dart';

class LiveLocationSession {
  final String conversationId;
  final String messageId;
  final int durationSeconds;
  final int expiresAt;
  final String? comment;
  double currentLatitude;
  double currentLongitude;
  String? currentAddress;
  DateTime lastUpdated;
  bool _isManuallyStopped = false;

  final void Function(LiveLocationSession session, double lat, double lng)? onLocationUpdate;
  final void Function(LiveLocationSession session)? onSessionEndedCallback;

  LiveLocationSession({
    required this.conversationId,
    required this.messageId,
    required this.durationSeconds,
    required this.expiresAt,
    required this.currentLatitude,
    required this.currentLongitude,
    this.currentAddress,
    this.comment,
    this.onLocationUpdate,
    this.onSessionEndedCallback,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  bool get isExpired => DateTime.now().millisecondsSinceEpoch >= expiresAt;

  bool get isActive => !isExpired && !_isManuallyStopped;

  set isActive(bool val) {
    _isManuallyStopped = !val;
  }
  
  int get remainingSeconds {
    final diff = expiresAt - DateTime.now().millisecondsSinceEpoch;
    return diff > 0 ? (diff / 1000).ceil() : 0;
  }
}

class LiveLocationService {
  static final LiveLocationService _instance = LiveLocationService._internal();
  factory LiveLocationService() => _instance;
  static LiveLocationService get instance => _instance;

  LiveLocationService._internal();

  final Map<String, LiveLocationSession> _activeSessions = {};
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _tickerTimer;

  final _sessionUpdatedController = StreamController<LiveLocationSession>.broadcast();
  Stream<LiveLocationSession> get onSessionUpdated => _sessionUpdatedController.stream;
  Stream<LiveLocationSession> get sessionStream => _sessionUpdatedController.stream;

  final _sessionEndedController = StreamController<String>.broadcast();
  Stream<String> get onSessionEnded => _sessionEndedController.stream;

  bool isLiveSharing(String conversationId) {
    final session = _activeSessions[conversationId];
    if (session == null) return false;
    if (session.isExpired) {
      stopLiveSharing(conversationId, session.messageId);
      return false;
    }
    return true;
  }

  LiveLocationSession? getSession(String conversationId) {
    return _activeSessions[conversationId];
  }

  LiveLocationSession? getSessionByMessageId(String messageId) {
    for (final s in _activeSessions.values) {
      if (s.messageId == messageId) return s;
    }
    return null;
  }

  Future<void> startLiveSharing({
    required String conversationId,
    required String messageId,
    required int durationSeconds,
    required double initialLatitude,
    required double initialLongitude,
    String? initialAddress,
    String? comment,
    void Function(LiveLocationSession session, double lat, double lng)? onLocationUpdate,
    void Function(LiveLocationSession session)? onSessionEnded,
  }) async {
    final expiresAt = DateTime.now().millisecondsSinceEpoch + (durationSeconds * 1000);

    final session = LiveLocationSession(
      conversationId: conversationId,
      messageId: messageId,
      durationSeconds: durationSeconds,
      expiresAt: expiresAt,
      currentLatitude: initialLatitude,
      currentLongitude: initialLongitude,
      currentAddress: initialAddress,
      comment: comment,
      onLocationUpdate: onLocationUpdate,
      onSessionEndedCallback: onSessionEnded,
    );

    _activeSessions[conversationId] = session;
    _sessionUpdatedController.add(session);

    _startLocationStreaming();
    _startTicker();
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiredKeys = <String>[];

      _activeSessions.forEach((key, session) {
        if (now >= session.expiresAt) {
          expiredKeys.add(key);
        } else {
          _sessionUpdatedController.add(session);
        }
      });

      for (final key in expiredKeys) {
        final s = _activeSessions[key];
        if (s != null) {
          stopLiveSharing(s.conversationId, s.messageId);
        }
      }

      if (_activeSessions.isEmpty) {
        _tickerTimer?.cancel();
        _tickerTimer = null;
      }
    });
  }

  void _startLocationStreaming() {
    if (_positionStreamSubscription != null) return;

    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (position) {
          _onNewPosition(position);
        },
        onError: (err) {
          debugPrint('LiveLocationService position stream error: $err');
        },
      );
    } catch (e) {
      debugPrint('LiveLocationService could not start position stream: $e');
    }
  }

  void _onNewPosition(Position position) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _activeSessions.forEach((convId, session) {
      if (now < session.expiresAt && session.isActive) {
        session.currentLatitude = position.latitude;
        session.currentLongitude = position.longitude;
        session.lastUpdated = DateTime.now();

        _broadcastLiveLocationUpdate(session);
        _sessionUpdatedController.add(session);
        session.onLocationUpdate?.call(session, position.latitude, position.longitude);
      }
    });
  }

  void _broadcastLiveLocationUpdate(LiveLocationSession session) {
    try {
      final socketRepo = getIt<ChatSocketRepository>();
      final payload = {
        "type": "live_location_update",
        "action": "live_location_update",
        "conversation_id": session.conversationId,
        "conversationId": session.conversationId,
        "message_id": session.messageId,
        "messageId": session.messageId,
        "latitude": session.currentLatitude,
        "longitude": session.currentLongitude,
        "address": session.currentAddress ?? "",
        "updatedAt": DateTime.now().toIso8601String(),
        "isLive": true,
        "isLiveActive": true,
      };
      socketRepo.emit('message', payload);
    } catch (e) {
      debugPrint('Error broadcasting live location update: $e');
    }
  }

  void stopLiveSharing(String conversationId, [String? messageId]) {
    final session = _activeSessions.remove(conversationId);
    final effectiveMsgId = messageId ?? session?.messageId ?? '';
    if (session != null) {
      session.isActive = false;
      session.onSessionEndedCallback?.call(session);

      try {
        final socketRepo = getIt<ChatSocketRepository>();
        final payload = {
          "type": "live_location_stop",
          "action": "live_location_stop",
          "conversation_id": conversationId,
          "conversationId": conversationId,
          "message_id": effectiveMsgId,
          "messageId": effectiveMsgId,
          "isLive": true,
          "isLiveActive": false,
        };
        socketRepo.emit('message', payload);
      } catch (e) {
        debugPrint('Error broadcasting live location stop: $e');
      }

      _sessionEndedController.add(effectiveMsgId);
      _sessionUpdatedController.add(session);
    }

    if (_activeSessions.isEmpty) {
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
      _tickerTimer?.cancel();
      _tickerTimer = null;
    }
  }

  void stopLiveSharingByMessageId(String messageId) {
    String? targetConvId;
    _activeSessions.forEach((convId, session) {
      if (session.messageId == messageId) {
        targetConvId = convId;
      }
    });
    if (targetConvId != null) {
      stopLiveSharing(targetConvId!, messageId);
    }
  }
}
