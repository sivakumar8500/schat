abstract class ChatSocketEvent {
  const ChatSocketEvent();
}

class ConnectSocket extends ChatSocketEvent {
  const ConnectSocket();
}

class DisconnectSocket extends ChatSocketEvent {
  const DisconnectSocket();
}

class SendMessage extends ChatSocketEvent {
  final String conversationId;
  final String type;
  final String? text;
  final String? fileKey;
  final String? thumbnail;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final double? duration;
  final String? replyMessageId;
  final Map<String, dynamic>? security;
  final Map<String, dynamic>? viewControl;
  final Map<String, dynamic>? expiry;
  final Map<String, dynamic>? callMeta;

  const SendMessage({
    required this.conversationId,
    required this.type,
    this.text,
    this.fileKey,
    this.thumbnail,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.duration,
    this.replyMessageId,
    this.security,
    this.viewControl,
    this.expiry,
    this.callMeta,
  });
}

class SendTypingIndicator extends ChatSocketEvent {
  final String conversationId;
  final bool isTyping;
  const SendTypingIndicator(this.conversationId, {this.isTyping = true});
}

class SendReadReceipt extends ChatSocketEvent {
  final String conversationId;
  final String messageId;
  const SendReadReceipt({required this.conversationId, required this.messageId});
}
