import 'package:schat/features/dashboard_screen/src/domain/last_message_model.dart';

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

  const UpdateUserStatus({
    required this.userId,
    required this.isOnline,
  });
}

class NewMessageReceived extends ChatsEvent {
  final String conversationId;
  final LastMessageModel lastMessage;
  final String updatedAt;

  const NewMessageReceived({
    required this.conversationId,
    required this.lastMessage,
    required this.updatedAt,
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
