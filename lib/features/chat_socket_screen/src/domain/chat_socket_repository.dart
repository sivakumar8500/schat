import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/utils/common_endpoints.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

abstract class ChatSocketRepository {
  void connect();
  void disconnect();
  void emit(String event, dynamic data);
  void sendMessage({
    required String conversationId,
    required String content,
    String? mediaUrl,
    String? mediaType,
  });
  void sendTypingIndicator(String conversationId);
  void sendReadReceipt(String conversationId, String messageId);
  void sendPing();
  bool get isConnected;
  Stream<dynamic> get onMessage;
}

@LazySingleton(as: ChatSocketRepository)
class ChatSocketRepositoryImpl implements ChatSocketRepository {
  final StorageService _storageService;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _messageController = StreamController<dynamic>.broadcast();
  Timer? _heartbeatTimer;
  bool _isConnected = false;

  ChatSocketRepositoryImpl(this._storageService);

  @override
  void connect() async {
    debugPrint('DEBUG: ChatSocketRepository.connect() called');
    
    if (_isConnected) {
      debugPrint('DEBUG: Socket already connected');
      return;
    }

    final token = _storageService.getAccessToken();
    if (token == null) {
      debugPrint('DEBUG: Socket connection aborted: No access token found');
      return;
    }

    try {
      final wsUrl = Uri.parse("${CommonEndpoints.socketUrl}?token=$token");
      debugPrint('--------------------------');
      debugPrint('WebSocket Connecting...');
      debugPrint('---------------------------');
      debugPrint('url --->: $wsUrl');

      _channel = WebSocketChannel.connect(wsUrl);
      
      await _channel!.ready;
      _isConnected = true;
      debugPrint('--------------------------');
      debugPrint('Socket Status: CONNECTED ✅');
      debugPrint('---------------------------');
      
      _startHeartbeat();

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
      _handleConnectionError(e);
    }
  }

  void _handleIncomingData(dynamic rawData) {
    debugPrint('--------------------------');
    debugPrint('Socket Data Received');
    debugPrint('---------------------------');
    debugPrint('response ----->: $rawData');
    debugPrint('----------------------------------');

    try {
      final data = jsonDecode(rawData);
      _messageController.add(data);
    } catch (e) {
      debugPrint('Error parsing incoming data: $e');
      _messageController.add(rawData);
    }
  }

  void _handleConnectionError(dynamic error) {
    debugPrint('--------------------------');
    debugPrint('Socket Status: CONNECTION ERROR ⚠️');
    debugPrint('---------------------------');
    debugPrint('error ---->: $error');
    debugPrint('----------------------------------');
    disconnect();
  }

  void _handleConnectionClosed() {
    debugPrint('--------------------------');
    debugPrint('Socket Status: DISCONNECTED ❌');
    debugPrint('---------------------------');
    debugPrint('----------------------------------');
    disconnect();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
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
    required String content,
    String? mediaUrl,
    String? mediaType,
  }) {
    final payload = {
      "type": "send_message",
      "conversation_id": conversationId,
      "content": content,
      "media_url": mediaUrl,
      "media_type": mediaType,
    };
    emit('message', payload);
  }

  @override
  void sendTypingIndicator(String conversationId) {
    final payload = {
      "type": "typing",
      "conversation_id": conversationId,
    };
    emit('message', payload);
  }

  @override
  void sendReadReceipt(String conversationId, String messageId) {
    final payload = {
      "type": "read_receipt",
      "conversation_id": conversationId,
      "message_id": messageId,
    };
    emit('message', payload);
  }

  @override
  void sendPing() {
    final payload = {
      "type": "ping",
    };
    emit('message', payload);
  }

  @override
  void emit(String event, dynamic data) {
    if (_channel == null) {
      debugPrint('Cannot emit: Socket not connected');
      return;
    }

    debugPrint('--------------------------');
    debugPrint('Socket Event Emitted');
    debugPrint('---------------------------');
    debugPrint('body ---->: ${jsonEncode(data ?? {})}');
    debugPrint('----------------------------------');
    
    _channel!.sink.add(jsonEncode(data));
  }

  @override
  void disconnect() {
    _stopHeartbeat();
    _subscription?.cancel();
    _channel?.sink.close(status.goingAway);
    _channel = null;
    _subscription = null;
    _isConnected = false;
  }

  @override
  bool get isConnected => _isConnected;

  @override
  Stream<dynamic> get onMessage => _messageController.stream;
}
