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
  final String content;
  final String? mediaUrl;
  final String? mediaType;

  const SendMessage({
    required this.conversationId,
    required this.content,
    this.mediaUrl,
    this.mediaType,
  });
}

class SendTypingIndicator extends ChatSocketEvent {
  final String conversationId;
  const SendTypingIndicator(this.conversationId);
}

class SendReadReceipt extends ChatSocketEvent {
  final String conversationId;
  final String messageId;
  const SendReadReceipt({required this.conversationId, required this.messageId});
}
