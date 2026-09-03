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
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? title;
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
    this.latitude,
    this.longitude,
    this.address,
    this.title,
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

class SendEditMessage extends ChatSocketEvent {
  final String messageId;
  final String? text;
  final Map<String, dynamic>? security;
  const SendEditMessage({required this.messageId, this.text, this.security});
}

class SendDeleteMessage extends ChatSocketEvent {
  final String conversationId;
  final String messageId;
  final String deleteType;
  const SendDeleteMessage({
    required this.conversationId,
    required this.messageId,
    required this.deleteType,
  });
}

class SendFileAction extends ChatSocketEvent {
  final String type;
  final String conversationId;
  final String messageId;
  final String fileKey;
  const SendFileAction({
    required this.type,
    required this.conversationId,
    required this.messageId,
    required this.fileKey,
  });
}

class SendLocationMessage extends ChatSocketEvent {
  final String conversationId;
  final double latitude;
  final double longitude;
  final String? address;
  const SendLocationMessage({
    required this.conversationId,
    required this.latitude,
    required this.longitude,
    this.address,
  });
}

class SendContactMessage extends ChatSocketEvent {
  final String conversationId;
  final String contactName;
  final String phoneNumber;
  const SendContactMessage({
    required this.conversationId,
    required this.contactName,
    required this.phoneNumber,
  });
}

class SendScreenShareSignaling extends ChatSocketEvent {
  final String type;
  final String conversationId;
  final Map<String, dynamic>? data;
  const SendScreenShareSignaling({
    required this.type,
    required this.conversationId,
    this.data,
  });
}
