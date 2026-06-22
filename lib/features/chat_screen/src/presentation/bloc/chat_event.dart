import 'dart:typed_data';
import 'package:flutter/material.dart';

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
  final String? replyMessageId;
  final String? replyMessageBody;
  final bool allowShare;
  final bool allowDownload;
  final bool allowView;
  final int? fileSize;

  const SendMessageEvent({
    required this.conversationId,
    required this.text,
    this.type = 'text',
    this.attachmentPath,
    this.attachmentName,
    this.attachmentBytes,
    this.replyMessageId,
    this.replyMessageBody,
    this.allowShare = true,
    this.allowDownload = true,
    this.allowView = true,
    this.fileSize,
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

class DeleteMessagesEvent extends ChatEvent {
  final List<String> messageIds;
  final String conversationId;
  final String deleteType; // 'me' or 'everyone'
  const DeleteMessagesEvent({required this.messageIds, required this.conversationId, required this.deleteType});
}

class EditMessageEvent extends ChatEvent {
  final String messageId;
  final String conversationId;
  final String newContent;
  const EditMessageEvent({required this.messageId, required this.conversationId, required this.newContent});
}

class PinMessageEvent extends ChatEvent {
  final String messageId;
  final String conversationId;
  final bool isPinned;
  const PinMessageEvent({required this.messageId, required this.conversationId, required this.isPinned});
}

class ReceiveDeleteMessageEvent extends ChatEvent {
  final String messageId;
  final String conversationId;
  const ReceiveDeleteMessageEvent({required this.messageId, required this.conversationId});
}

class ReceiveEditMessageEvent extends ChatEvent {
  final String messageId;
  final String conversationId;
  final String newContent;
  const ReceiveEditMessageEvent({required this.messageId, required this.conversationId, required this.newContent});
}

class ChangeBackgroundColorEvent extends ChatEvent {
  final Color color;
  final String conversationId;
  const ChangeBackgroundColorEvent({required this.color, required this.conversationId});
}

class UpdateAttachmentPermissionsEvent extends ChatEvent {
  final String messageId;
  final String conversationId;
  final bool allowShare;
  final bool allowDownload;
  final bool allowView;

  const UpdateAttachmentPermissionsEvent({
    required this.messageId,
    required this.conversationId,
    required this.allowShare,
    required this.allowDownload,
    required this.allowView,
  });
}
