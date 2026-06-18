import 'dart:typed_data';

abstract class ChatEvent {
  const ChatEvent();
}

class LoadMessagesEvent extends ChatEvent {
  final String conversationId;
  final String? recipientId;
  final bool? initialIsOnline;
  const LoadMessagesEvent({required this.conversationId, this.recipientId, this.initialIsOnline});
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

class UpdateUserStatusEvent extends ChatEvent {
  final String userId;
  final bool isOnline;
  const UpdateUserStatusEvent({required this.userId, required this.isOnline});
}

class UpdateTypingIndicatorEvent extends ChatEvent {
  final String conversationId;
  final bool isTyping;
  const UpdateTypingIndicatorEvent({required this.conversationId, required this.isTyping});
}

class MarkMessageReadEvent extends ChatEvent {
  final String messageId;
  final String conversationId;
  const MarkMessageReadEvent({required this.messageId, required this.conversationId});
}
