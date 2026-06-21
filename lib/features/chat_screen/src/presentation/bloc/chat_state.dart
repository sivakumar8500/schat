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
  final bool isMuted;
  final bool isLocked;
  final String myId;
  final bool isRecipientOnline;
  final bool isRecipientTyping;
  final Color? customBgColor;

  const ChatLoaded({
    required this.messages,
    this.isMuted = false,
    this.isLocked = false,
    this.myId = '',
    this.isRecipientOnline = false,
    this.isRecipientTyping = false,
    this.customBgColor,
  });

  ChatLoaded copyWith({
    List<MessageModel>? messages,
    bool? isMuted,
    bool? isLocked,
    String? myId,
    bool? isRecipientOnline,
    bool? isRecipientTyping,
    Color? customBgColor,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      isMuted: isMuted ?? this.isMuted,
      isLocked: isLocked ?? this.isLocked,
      myId: myId ?? this.myId,
      isRecipientOnline: isRecipientOnline ?? this.isRecipientOnline,
      isRecipientTyping: isRecipientTyping ?? this.isRecipientTyping,
      customBgColor: customBgColor ?? this.customBgColor,
    );
  }
}

class ChatError extends ChatState {
  final String errorMessage;
  const ChatError({required this.errorMessage});
}
