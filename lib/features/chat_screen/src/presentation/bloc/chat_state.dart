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

  const ChatLoaded({
    required this.messages,
    this.isMuted = false,
    this.isLocked = false,
    this.myId = '',
  });
}

class ChatError extends ChatState {
  final String errorMessage;
  const ChatError({required this.errorMessage});
}
