import 'dart:typed_data';

abstract class ChatEvent {
  const ChatEvent();
}

class LoadMessagesEvent extends ChatEvent {
  final String conversationId;
  const LoadMessagesEvent({required this.conversationId});
}

class SendMessageEvent extends ChatEvent {
  final String conversationId;
  final String text;
  final String type;
  final String? attachmentPath;
  final String? attachmentName;
  final Uint8List? attachmentBytes;

  const SendMessageEvent({
    required this.conversationId,
    required this.text,
    this.type = 'text',
    this.attachmentPath,
    this.attachmentName,
    this.attachmentBytes,
  });
}

class ReceiveMessageEvent extends ChatEvent {
  final Map<String, dynamic> messageData;
  const ReceiveMessageEvent({required this.messageData});
}

class ToggleMuteEvent extends ChatEvent {
  final bool isMuted;
  const ToggleMuteEvent({required this.isMuted});
}

class ToggleLockEvent extends ChatEvent {
  final bool isLocked;
  const ToggleLockEvent({required this.isLocked});
}
