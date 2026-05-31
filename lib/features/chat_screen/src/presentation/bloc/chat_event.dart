import 'dart:typed_data';

abstract class ChatEvent {
  const ChatEvent();
}

class LoadMessagesEvent extends ChatEvent {
  final String contactName;
  const LoadMessagesEvent({required this.contactName});
}

class SendMessageEvent extends ChatEvent {
  final String contactName;
  final String text;
  final String type;
  final String? attachmentPath;
  final String? attachmentName;
  final Uint8List? attachmentBytes;

  const SendMessageEvent({
    required this.contactName,
    required this.text,
    this.type = 'text',
    this.attachmentPath,
    this.attachmentName,
    this.attachmentBytes,
  });
}

class ToggleMuteEvent extends ChatEvent {
  final bool isMuted;
  const ToggleMuteEvent({required this.isMuted});
}

class ToggleLockEvent extends ChatEvent {
  final bool isLocked;
  const ToggleLockEvent({required this.isLocked});
}
