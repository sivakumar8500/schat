import 'package:flutter/material.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';

abstract class ChatState {
  const ChatState();
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  final List<MessageModel> messages;
  final List<MessageModel> pinnedMessages;
  final bool isMuted;
  final bool isLocked;
  final bool isFavorite;
  final String myId;
  final bool isRecipientOnline;
  final bool isRecipientTyping;
  final Color? customBgColor;
  final String? notificationMessage;

  const ChatLoaded({
    required this.messages,
    this.pinnedMessages = const [],
    this.isMuted = false,
    this.isLocked = false,
    this.isFavorite = false,
    this.myId = '',
    this.isRecipientOnline = false,
    this.isRecipientTyping = false,
    this.customBgColor,
    this.notificationMessage,
  });

  ChatLoaded copyWith({
    List<MessageModel>? messages,
    List<MessageModel>? pinnedMessages,
    bool? isMuted,
    bool? isLocked,
    bool? isFavorite,
    String? myId,
    bool? isRecipientOnline,
    bool? isRecipientTyping,
    Color? customBgColor,
    String? notificationMessage,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      pinnedMessages: pinnedMessages ?? this.pinnedMessages,
      isMuted: isMuted ?? this.isMuted,
      isLocked: isLocked ?? this.isLocked,
      isFavorite: isFavorite ?? this.isFavorite,
      myId: myId ?? this.myId,
      isRecipientOnline: isRecipientOnline ?? this.isRecipientOnline,
      isRecipientTyping: isRecipientTyping ?? this.isRecipientTyping,
      customBgColor: customBgColor ?? this.customBgColor,
      notificationMessage: notificationMessage,
    );
  }
}

class ChatError extends ChatState {
  final String errorMessage;
  const ChatError({required this.errorMessage});
}

class ChatDeleted extends ChatState {
  const ChatDeleted();
}
