import 'package:schat/features/chat_transfer_screen/src/domain/models/chat_view_request_model.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/models/chat_view_user_model.dart';

abstract class ChatTransferEvent {
  const ChatTransferEvent();
}

class LoadChatTransferData extends ChatTransferEvent {
  const LoadChatTransferData();
}

class SendChatTransferRequest extends ChatTransferEvent {
  final String receiverId;
  const SendChatTransferRequest(this.receiverId);
}

class RespondChatTransferRequest extends ChatTransferEvent {
  final String requestId;
  final bool accept;
  const RespondChatTransferRequest({
    required this.requestId,
    required this.accept,
  });
}

class RevokeChatTransferRequest extends ChatTransferEvent {
  final String requestId;
  const RevokeChatTransferRequest(this.requestId);
}

class LoadTargetConversations extends ChatTransferEvent {
  final String targetUserId;
  final ChatViewUserModel? targetUser;
  const LoadTargetConversations({
    required this.targetUserId,
    this.targetUser,
  });
}

class SocketChatViewRequestReceived extends ChatTransferEvent {
  final ChatViewRequestModel request;
  const SocketChatViewRequestReceived(this.request);
}

class SocketChatViewRequestUpdated extends ChatTransferEvent {
  final ChatViewRequestModel request;
  const SocketChatViewRequestUpdated(this.request);
}

class ClearTransferMessages extends ChatTransferEvent {
  const ClearTransferMessages();
}
