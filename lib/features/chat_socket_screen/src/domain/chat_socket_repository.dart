import 'dart:async';
import 'dart:convert';
import 'js_convert_helper_stub.dart'
    if (dart.library.html) 'js_convert_helper_web.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/services/session_manager_service.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_endpoints.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SocketEventLog {
  final String direction; // 'inbound' | 'outbound' | 'status'
  final DateTime timestamp;
  final Map<String, dynamic> payload;

  SocketEventLog({
    required this.direction,
    required this.timestamp,
    required this.payload,
  });
}

abstract class ChatSocketRepository {
  void connect();
  void disconnect();
  Stream<SocketEventLog> get onEventLog;
  void emit(String event, dynamic data);
  void sendMessage({
    required String conversationId,
    required String type,
    String? text,
    String? fileKey,
    String? thumbnail,
    String? fileName,
    int? fileSize,
    String? mimeType,
    double? duration,
    String? replyMessageId,
    double? latitude,
    double? longitude,
    String? address,
    String? title,
    Map<String, dynamic>? security,
    Map<String, dynamic>? viewControl,
    Map<String, dynamic>? expiry,
    Map<String, dynamic>? callMeta,
  });
  void sendTypingIndicator(String conversationId, {bool isTyping = true});
  void sendReadReceipt(String conversationId, String messageId);
  void sendDeliveryReceipt(String conversationId, String messageId);
  void editMessage({
    required String messageId,
    String? conversationId,
    String? text,
    Map<String, dynamic>? security,
  });
  void deleteMessage({
    required String conversationId,
    required String messageId,
    required String deleteType,
  });
  void sendFileAction({
    required String type,
    required String conversationId,
    required String messageId,
    required String fileKey,
  });
  void sendLocationMessage({
    required String conversationId,
    required double latitude,
    required double longitude,
    String? address,
  });
  void sendContactMessage({
    required String conversationId,
    required String contactName,
    required String phoneNumber,
  });
  void pinMessage({required String messageId});
  void unpinMessage({required String messageId});
  void sendReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
  });
  void sendScreenShareSignaling({
    required String type,
    required String conversationId,
    Map<String, dynamic>? data,
  });
  void sendPing();
  void onAppResumed();
  bool get isConnected;
  Stream<dynamic> get onMessage;
  List<SocketEventLog> get eventLogs;
  void clearLogs();
}

@LazySingleton(as: ChatSocketRepository)
class ChatSocketRepositoryImpl implements ChatSocketRepository {
  final StorageService _storageService;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _messageController = StreamController<dynamic>.broadcast();
  final _eventLogController = StreamController<SocketEventLog>.broadcast();
  final List<SocketEventLog> _eventLogs = [];
  Timer? _heartbeatTimer;
  DateTime? _lastPongReceived;
  bool _isConnected = false;
  bool _isConnecting = false;
  Completer<void>? _connectCompleter;
  final List<dynamic> _pendingMessagesQueue = [];

  ChatSocketRepositoryImpl(this._storageService);

  @override
  void onAppResumed() {
    _lastPongReceived = DateTime.now();
    if (!_isConnected) {
      debugPrint('ChatSocketRepository: App resumed and socket disconnected — reconnecting...');
      connect();
    } else {
      sendPing();
    }
  }

  @override
  Stream<SocketEventLog> get onEventLog => _eventLogController.stream;

  @override
  List<SocketEventLog> get eventLogs => List.unmodifiable(_eventLogs);

  @override
  void clearLogs() {
    _eventLogs.clear();
    _logEvent('status', {'status': 'logs_cleared'});
  }

  void _logEvent(String direction, Map<String, dynamic> payload) {
    final log = SocketEventLog(
      direction: direction,
      timestamp: DateTime.now(),
      payload: payload,
    );
    _eventLogs.insert(0, log);
    if (_eventLogs.length > 500) {
      _eventLogs.removeLast();
    }
    _eventLogController.add(log);
  }

  @override
  void connect() async {
    debugPrint('DEBUG: ChatSocketRepository.connect() called (isConnected=$_isConnected, isConnecting=$_isConnecting)');
    
    if (_isConnected) {
      debugPrint('DEBUG: Socket already connected');
      return;
    }

    if (_isConnecting) {
      debugPrint('DEBUG: Socket connection already in progress, awaiting existing connection...');
      await _connectCompleter?.future;
      return;
    }

    _isConnecting = true;
    _connectCompleter = Completer<void>();

    final token = _storageService.getAccessToken();
    if (token == null) {
      debugPrint('DEBUG: Socket connection aborted: No access token found');
      _isConnecting = false;
      if (!(_connectCompleter?.isCompleted ?? true)) {
        _connectCompleter?.complete();
      }
      return;
    }

    try {
      final wsUrl = Uri.parse("${CommonEndpoints.socketUrl}?token=$token");
      debugPrint('--------------------------');
      debugPrint('WebSocket Connecting...');
      debugPrint('---------------------------');
      debugPrint('url --->: $wsUrl');

      _logEvent('status', {'status': 'connecting', 'url': wsUrl.toString()});

      _channel = WebSocketChannel.connect(wsUrl);
      
      await _channel!.ready;
      _isConnected = true;
      _isConnecting = false;
      if (!(_connectCompleter?.isCompleted ?? true)) {
        _connectCompleter?.complete();
      }
      _lastPongReceived = DateTime.now();
      debugPrint('--------------------------');
      debugPrint('Socket Status: CONNECTED ✅');
      debugPrint('---------------------------');
      
      _logEvent('status', {'status': 'connected'});

      _startHeartbeat();

      // Flush any queued outbound messages (e.g. call_response or ice candidates)
      if (_pendingMessagesQueue.isNotEmpty) {
        final messages = List<dynamic>.from(_pendingMessagesQueue);
        _pendingMessagesQueue.clear();
        for (final msg in messages) {
          try {
            emit('message', msg);
          } catch (e) {
            debugPrint('Error flushing queued socket message: $e');
          }
        }
      }

      _subscription = _channel!.stream.listen(
        (data) {
          _handleIncomingData(data);
        },
        onError: (error) {
          _handleConnectionError(error);
        },
        onDone: () {
          _handleConnectionClosed();
        },
      );
    } catch (e) {
      _isConnecting = false;
      if (!(_connectCompleter?.isCompleted ?? true)) {
        _connectCompleter?.complete();
      }
      _handleConnectionError(e);
    }
  }

  void _handleIncomingData(dynamic rawData) {
    debugPrint('--------------------------');
    debugPrint('Socket Data Received');
    debugPrint('---------------------------');
    debugPrint('type: ${rawData.runtimeType}');
    debugPrint('response ----->: $rawData');
    debugPrint('----------------------------------');

    try {
      dynamic decodedData;
      if (rawData is String) {
        decodedData = jsonDecode(rawData);
      } else if (rawData is List<int>) {
        decodedData = jsonDecode(utf8.decode(rawData));
      } else {
        decodedData = convertJsObject(rawData);
      }
      
      _lastPongReceived = DateTime.now();
      _logEvent('inbound', decodedData is Map<String, dynamic> 
          ? decodedData 
          : {'raw': rawData.toString(), 'decoded': decodedData});

      if (decodedData is Map<String, dynamic>) {
        final eventType = decodedData['type'] ?? decodedData['event'] ?? decodedData['action'];
        if (eventType == 'pong') {
          _lastPongReceived = DateTime.now();
        } else if (eventType == 'force_logout' ||
            eventType == 'session_expired' ||
            eventType == 'duplicate_login' ||
            eventType == 'logout_other_devices' ||
            eventType == 'device_conflict') {
          debugPrint('ChatSocketRepository: Received eviction event "$eventType". Triggering auto-logout & navigation to login.');
          final reason = decodedData['reason'] ??
              decodedData['message'] ??
              'You have been logged out because your account was logged in on another device.';
          getIt<SessionManagerService>().logoutAndRedirectToLogin(
            reason: reason.toString(),
          );
        }
      }

      _messageController.add(decodedData);
    } catch (e) {
      debugPrint('Error parsing incoming data: $e');
      _logEvent('inbound', {'raw': rawData.toString(), 'error': e.toString()});
      _messageController.add(rawData);
    }
  }

  void _handleConnectionError(dynamic error) {
    debugPrint('--------------------------');
    debugPrint('Socket Status: CONNECTION ERROR ⚠️');
    debugPrint('---------------------------');
    debugPrint('error ---->: $error');
    debugPrint('----------------------------------');
    _logEvent('status', {'status': 'error', 'error': error.toString()});
    disconnect();
    _reconnect();
  }

  void _handleConnectionClosed() {
    final closeCode = _channel?.closeCode;
    final closeReason = _channel?.closeReason;
    debugPrint('--------------------------');
    debugPrint('Socket Status: DISCONNECTED ❌ CloseCode: $closeCode, Reason: $closeReason');
    debugPrint('---------------------------');
    debugPrint('----------------------------------');
    _logEvent('status', {
      'status': 'disconnected',
      'closeCode': closeCode,
      'closeReason': closeReason,
    });
    disconnect();
    if (closeCode == 1008 || closeCode == 4001 || closeCode == 4003) {
      debugPrint('ChatSocketRepository: Session terminated with CloseCode $closeCode (Policy / Displacement). Logging out...');
      getIt<SessionManagerService>().logoutAndRedirectToLogin(
        reason: 'Your session has ended because your account was logged in on another device.',
      );
    } else {
      _reconnect();
    }
  }

  void _reconnect() {
    if (!_isConnected) {
      debugPrint('Attempting to reconnect in 5 seconds...');
      Timer(const Duration(seconds: 5), () {
        connect();
      });
    }
  }

  void _startHeartbeat() {
    _lastPongReceived = DateTime.now();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_lastPongReceived != null &&
          DateTime.now().difference(_lastPongReceived!) > const Duration(seconds: 45)) {
        debugPrint('DEBUG: WebSocket heartbeat timeout (no activity received in 45s). Reconnecting...');
        _handleConnectionError('Heartbeat timeout');
        return;
      }
      sendPing();
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  @override
  void sendMessage({
    required String conversationId,
    required String type,
    String? text,
    String? fileKey,
    String? thumbnail,
    String? fileName,
    int? fileSize,
    String? mimeType,
    double? duration,
    String? replyMessageId,
    double? latitude,
    double? longitude,
    String? address,
    String? title,
    Map<String, dynamic>? security,
    Map<String, dynamic>? viewControl,
    Map<String, dynamic>? expiry,
    Map<String, dynamic>? callMeta,
  }) {
    final Map<String, dynamic> content = {};
    if (text != null) content['text'] = text;
    if (fileKey != null) content['fileKey'] = fileKey;
    if (thumbnail != null) content['thumbnail'] = thumbnail;
    if (fileName != null) content['fileName'] = fileName;
    if (fileSize != null) content['fileSize'] = fileSize;
    if (mimeType != null) content['mimeType'] = mimeType;
    if (duration != null) content['duration'] = duration;
    
    if (latitude != null) content['latitude'] = latitude;
    if (longitude != null) content['longitude'] = longitude;
    if (address != null) content['address'] = address;
    if (title != null) content['title'] = title;

    String payloadType = type;
    if (type == 'voice_note' || (mimeType != null && mimeType.startsWith('audio/'))) {
      payloadType = 'audio';
    }

    final resolvedSecurity = security != null ? {
      ...security,
      'isLocked': security['isLocked'] ?? security['is_locked'] ?? false,
      'is_locked': security['isLocked'] ?? security['is_locked'] ?? false,
      'accessUsers': security['accessUsers'] ?? security['access_users'] ?? [],
      'access_users': security['accessUsers'] ?? security['access_users'] ?? [],
      'allowDownload': security['allowDownload'] ?? security['allow_download'] ?? false,
      'allow_download': security['allowDownload'] ?? security['allow_download'] ?? false,
      'allowShare': security['allowShare'] ?? security['allow_share'] ?? false,
      'allow_share': security['allowShare'] ?? security['allow_share'] ?? false,
      'allowView': security['allowView'] ?? security['allow_view'] ?? true,
      'allow_view': security['allowView'] ?? security['allow_view'] ?? true,
      'canView': security['allowView'] ?? security['allow_view'] ?? true,
      'can_view': security['allowView'] ?? security['allow_view'] ?? true,
    } : null;

    final resolvedViewControl = viewControl != null ? {
      ...viewControl,
      'type': viewControl['type'] ?? 'normal',
      'maxViews': viewControl['maxViews'] ?? viewControl['max_views'] ?? 1,
      'max_views': viewControl['maxViews'] ?? viewControl['max_views'] ?? 1,
      'isViewOnce': viewControl['isViewOnce'] ?? viewControl['is_view_once'] ?? false,
      'is_view_once': viewControl['isViewOnce'] ?? viewControl['is_view_once'] ?? false,
      'allowDownload': viewControl['allowDownload'] ?? viewControl['allow_download'] ?? false,
      'allow_download': viewControl['allowDownload'] ?? viewControl['allow_download'] ?? false,
      'allowShare': viewControl['allowShare'] ?? viewControl['allow_share'] ?? false,
      'allow_share': viewControl['allowShare'] ?? viewControl['allow_share'] ?? false,
      'allowView': viewControl['allowView'] ?? viewControl['allow_view'] ?? true,
      'allow_view': viewControl['allowView'] ?? viewControl['allow_view'] ?? true,
    } : null;

    final Map<String, dynamic> payload = {
      "type": payloadType,
      "conversationId": conversationId,
      "conversation_id": conversationId,
    };

    if (content.isNotEmpty) payload['content'] = content;
    if (replyMessageId != null) {
      payload['replyMessageId'] = replyMessageId;
      payload['reply_message_id'] = replyMessageId;
    }
    if (resolvedSecurity != null) {
      payload['security'] = resolvedSecurity;
      payload['allowView'] = resolvedSecurity['allowView'];
      payload['allow_view'] = resolvedSecurity['allowView'];
      payload['allowDownload'] = resolvedSecurity['allowDownload'];
      payload['allow_download'] = resolvedSecurity['allowDownload'];
      payload['allowShare'] = resolvedSecurity['allowShare'];
      payload['allow_share'] = resolvedSecurity['allowShare'];
    }
    if (resolvedViewControl != null) payload['viewControl'] = resolvedViewControl;
    if (expiry != null) payload['expiry'] = expiry;
    if (callMeta != null) payload['callMeta'] = callMeta;

    emit('message', payload);
  }

  @override
  void sendTypingIndicator(String conversationId, {bool isTyping = true}) {
    if (!isTyping) return; // Do not send if they stopped typing, backend only expects typing start events
    final Map<String, dynamic> payload = {
      "type": "typing",
      "conversationId": conversationId,
      "conversation_id": conversationId,
    };
    emit('message', payload);
  }

  @override
  void sendReadReceipt(String conversationId, String messageId) {
    final Map<String, dynamic> payload = {
      "type": "read_receipt",
      "conversationId": conversationId,
      "conversation_id": conversationId,
      "messageId": messageId,
      "message_id": messageId,
    };
    emit('message', payload);
  }

  @override
  void sendDeliveryReceipt(String conversationId, String messageId) {
    final Map<String, dynamic> payload = {
      "type": "delivery_receipt",
      "conversationId": conversationId,
      "conversation_id": conversationId,
      "messageId": messageId,
      "message_id": messageId,
    };
    emit('message', payload);
  }

  @override
  void editMessage({
    required String messageId,
    String? conversationId,
    String? text,
    Map<String, dynamic>? security,
  }) {
    final resolvedSecurity = security != null ? {
      ...security,
      'isLocked': security['isLocked'] ?? security['is_locked'] ?? false,
      'is_locked': security['isLocked'] ?? security['is_locked'] ?? false,
      'accessUsers': security['accessUsers'] ?? security['access_users'] ?? [],
      'access_users': security['accessUsers'] ?? security['access_users'] ?? [],
      'allowDownload': security['allowDownload'] ?? security['allow_download'] ?? false,
      'allow_download': security['allowDownload'] ?? security['allow_download'] ?? false,
      'allowShare': security['allowShare'] ?? security['allow_share'] ?? false,
      'allow_share': security['allowShare'] ?? security['allow_share'] ?? false,
      'allowView': security['allowView'] ?? security['allow_view'] ?? true,
      'allow_view': security['allowView'] ?? security['allow_view'] ?? true,
      'canView': security['allowView'] ?? security['allow_view'] ?? true,
      'can_view': security['allowView'] ?? security['allow_view'] ?? true,
    } : null;

    final Map<String, dynamic> payload = {
      "type": "edit_message",
      "message_id": messageId,
      "messageId": messageId,
      if (conversationId != null) "conversation_id": conversationId,
      if (conversationId != null) "conversationId": conversationId,
      if (text != null) "text": text,
      if (resolvedSecurity != null) "security": resolvedSecurity,
      if (resolvedSecurity != null) "allowView": resolvedSecurity['allowView'],
      if (resolvedSecurity != null) "allow_view": resolvedSecurity['allowView'],
      if (resolvedSecurity != null) "allowDownload": resolvedSecurity['allowDownload'],
      if (resolvedSecurity != null) "allow_download": resolvedSecurity['allowDownload'],
      if (resolvedSecurity != null) "allowShare": resolvedSecurity['allowShare'],
      if (resolvedSecurity != null) "allow_share": resolvedSecurity['allowShare'],
    };
    emit('message', payload);
  }

  @override
  void deleteMessage({
    required String conversationId,
    required String messageId,
    required String deleteType,
  }) {
    final Map<String, dynamic> payload = {
      "type": "delete_message",
      "conversation_id": conversationId,
      "message_id": messageId,
      "delete_type": deleteType,
    };
    emit('message', payload);
  }

  @override
  void sendFileAction({
    required String type,
    required String conversationId,
    required String messageId,
    required String fileKey,
  }) {
    final Map<String, dynamic> payload = {
      "type": type,
      "conversationId": conversationId,
      "conversation_id": conversationId,
      "messageId": messageId,
      "message_id": messageId,
      "fileKey": fileKey,
      "file_key": fileKey,
    };
    emit('message', payload);
  }

  @override
  void sendLocationMessage({
    required String conversationId,
    required double latitude,
    required double longitude,
    String? address,
  }) {
    final Map<String, dynamic> payload = {
      "type": "location",
      "conversation_id": conversationId,
      "content": {
        "latitude": latitude,
        "longitude": longitude,
        "address": address ?? "",
      }
    };
    emit('message', payload);
  }

  @override
  void sendContactMessage({
    required String conversationId,
    required String contactName,
    required String phoneNumber,
  }) {
    final Map<String, dynamic> payload = {
      "type": "contact",
      "conversation_id": conversationId,
      "content": {
        "contactName": contactName,
        "phoneNumber": phoneNumber,
      }
    };
    emit('message', payload);
  }

  @override
  void pinMessage({required String messageId}) {
    final Map<String, dynamic> payload = {
      "type": "pin_message",
      "message_id": messageId,
    };
    emit('message', payload);
  }

  @override
  void unpinMessage({required String messageId}) {
    final Map<String, dynamic> payload = {
      "type": "unpin_message",
      "message_id": messageId,
    };
    emit('message', payload);
  }

  @override
  void sendReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) {
    final myId = _storageService.getUserId() ?? '';
    final myName = _storageService.getUsername() ?? 'User';
    final Map<String, dynamic> payload = {
      "type": "message_reaction",
      "action": "reaction",
      "event": "message_reaction",
      "conversationId": conversationId,
      "conversation_id": conversationId,
      "messageId": messageId,
      "message_id": messageId,
      "id": messageId,
      "emoji": emoji,
      "reaction": emoji,
      "userId": myId,
      "user_id": myId,
      "senderId": myId,
      "sender_id": myId,
      "userName": myName,
      "user_name": myName,
    };
    emit('message', payload);
  }

  @override
  void sendScreenShareSignaling({
    required String type,
    required String conversationId,
    Map<String, dynamic>? data,
  }) {
    final Map<String, dynamic> payload = {
      "type": type,
      "conversation_id": conversationId,
      ...?data,
    };
    emit('message', payload);
  }

  @override
  void sendPing() {
    final Map<String, dynamic> payload = {
      "type": "ping",
    };
    emit('message', payload);
  }

  @override
  void emit(String event, dynamic data) {
    if (_channel == null || !_isConnected) {
      debugPrint('ChatSocketRepository: Socket not connected yet. Queueing message for delivery once connected.');
      _pendingMessagesQueue.add(data);
      _logEvent('status', {'status': 'queued_outbound', 'data': data});
      if (!_isConnecting && !_isConnected) {
        connect();
      }
      return;
    }

    debugPrint('--------------------------');
    debugPrint('Socket Event Emitted');
    debugPrint('---------------------------');
    debugPrint('body ---->: ${jsonEncode(data ?? {})}');
    debugPrint('----------------------------------');
    
    _logEvent('outbound', data is Map<String, dynamic> ? data : {'raw': data.toString()});

    try {
      _channel!.sink.add(jsonEncode(data));
    } catch (e) {
      debugPrint('Error sending data over socket sink: $e. Re-queueing message.');
      _pendingMessagesQueue.add(data);
    }
  }

  @override
  void disconnect() {
    final wasConnected = _isConnected;
    _stopHeartbeat();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscription = null;
    _isConnected = false;
    if (wasConnected) {
      _logEvent('status', {'status': 'disconnected_manually'});
    }
  }

  @override
  bool get isConnected => _isConnected;

  @override
  Stream<dynamic> get onMessage => _messageController.stream;
}
