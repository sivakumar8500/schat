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
    required String type,
    String? text,
    String? fileKey,
    String? thumbnail,
    String? fileName,
    int? fileSize,
    String? mimeType,
    double? duration,
    String? replyMessageId,
    Map<String, dynamic>? security,
    Map<String, dynamic>? viewControl,
    Map<String, dynamic>? expiry,
    Map<String, dynamic>? callMeta,
  });
  void sendTypingIndicator(String conversationId, {bool isTyping = true});
  void sendReadReceipt(String conversationId, String messageId);
  void editMessage({required String messageId, required String text});
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
  void sendScreenShareSignaling({
    required String type,
    required String conversationId,
    Map<String, dynamic>? data,
  });
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
        decodedData = rawData;
      }
      _messageController.add(decodedData);
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
    _reconnect();
  }

  void _handleConnectionClosed() {
    debugPrint('--------------------------');
    debugPrint('Socket Status: DISCONNECTED ❌');
    debugPrint('---------------------------');
    debugPrint('----------------------------------');
    disconnect();
    _reconnect();
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
    required String type,
    String? text,
    String? fileKey,
    String? thumbnail,
    String? fileName,
    int? fileSize,
    String? mimeType,
    double? duration,
    String? replyMessageId,
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

    final Map<String, dynamic> payload = {
      "type": type,
      "conversationId": conversationId,
      "conversation_id": conversationId,
    };

    if (content.isNotEmpty) payload['content'] = content;
    if (replyMessageId != null) payload['replyMessageId'] = replyMessageId;
    if (security != null) payload['security'] = security;
    if (viewControl != null) payload['viewControl'] = viewControl;
    if (expiry != null) payload['expiry'] = expiry;
    if (callMeta != null) payload['callMeta'] = callMeta;

    emit('message', payload);
  }

  @override
  void sendTypingIndicator(String conversationId, {bool isTyping = true}) {
    final Map<String, dynamic> payload = {
      "type": "typing",
      "conversationId": conversationId,
      "conversation_id": conversationId, // Send both to be safe
      "is_typing": isTyping,
      "isTyping": isTyping,
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
  void editMessage({required String messageId, required String text}) {
    final Map<String, dynamic> payload = {
      "type": "edit_message",
      "message_id": messageId,
      "text": text,
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
      "conversation_id": conversationId,
      "message_id": messageId,
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
