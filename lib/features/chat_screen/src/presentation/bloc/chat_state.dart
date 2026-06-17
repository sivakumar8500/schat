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

  const ChatLoaded({
    required this.messages,
    this.isMuted = false,
    this.isLocked = false,
    this.myId = '',
    this.isRecipientOnline = false,
    this.isRecipientTyping = false,
  });

  ChatLoaded copyWith({
    List<MessageModel>? messages,
    bool? isMuted,
    bool? isLocked,
    String? myId,
    bool? isRecipientOnline,
    bool? isRecipientTyping,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      isMuted: isMuted ?? this.isMuted,
      isLocked: isLocked ?? this.isLocked,
      myId: myId ?? this.myId,
      isRecipientOnline: isRecipientOnline ?? this.isRecipientOnline,
      isRecipientTyping: isRecipientTyping ?? this.isRecipientTyping,
    );
  }
}

class ChatError extends ChatState {
  final String errorMessage;
  const ChatError({required this.errorMessage});
}
