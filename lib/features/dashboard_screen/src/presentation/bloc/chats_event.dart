import 'package:schat/features/dashboard_screen/src/domain/models/last_message_model.dart';

abstract class ChatsEvent {
  const ChatsEvent();
}

class FetchChats extends ChatsEvent {
  const FetchChats();
}

class CreateChat extends ChatsEvent {
  final String participantId;
  final String contactName;
  final String? profilePictureUrl;

  const CreateChat({
    required this.participantId,
    required this.contactName,
    this.profilePictureUrl,
  });
}

class UpdateUserStatus extends ChatsEvent {
  final String userId;
  final bool isOnline;
  final String? lastSeen;

  const UpdateUserStatus({
    required this.userId,
    required this.isOnline,
    this.lastSeen,
  });
}

class NewMessageReceived extends ChatsEvent {
  final String conversationId;
  final LastMessageModel lastMessage;
  final String updatedAt;
  final int? unreadCount;

  const NewMessageReceived({
    required this.conversationId,
    required this.lastMessage,
    required this.updatedAt,
    this.unreadCount,
  });
}

class MessageEdited extends ChatsEvent {
  final String conversationId;
  final LastMessageModel message;

  const MessageEdited({
    required this.conversationId,
    required this.message,
  });
}

class RemoveChat extends ChatsEvent {
  final String conversationId;

  const RemoveChat({
    required this.conversationId,
  });
}

class CallLogUpdated extends ChatsEvent {
  final String conversationId;
  final String messageId;
  final Map<String, dynamic> callMeta;

  const CallLogUpdated({
    required this.conversationId,
    required this.messageId,
    required this.callMeta,
  });
}

class UpdateChatTypingStatus extends ChatsEvent {
  final String conversationId;
  final bool isTyping;

  const UpdateChatTypingStatus({
    required this.conversationId,
    required this.isTyping,
  });
}

class MessageDeleted extends ChatsEvent {
  final String conversationId;
  final String messageId;

  const MessageDeleted({
    required this.conversationId,
    required this.messageId,
  });
}

class UpdateDisappearingTimer extends ChatsEvent {
  final String conversationId;
  final int? seconds;

  const UpdateDisappearingTimer({
    required this.conversationId,
    this.seconds,
  });
}

