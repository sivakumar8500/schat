import 'package:schat/features/dashboard_screen/src/domain/chat_model.dart';

abstract class ChatsState {
  const ChatsState();

  TResult maybeWhen<TResult>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<ChatModel> chats)? loaded,
    TResult Function(ChatModel chat, String contactName, String? profilePictureUrl)? chatCreated,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (this is ChatsInitial && initial != null) return initial();
    if (this is ChatsLoading && loading != null) return loading();
    if (this is ChatsLoaded && loaded != null) return loaded((this as ChatsLoaded).chats);
    if (this is ChatCreated && chatCreated != null) {
      final state = this as ChatCreated;
      return chatCreated(state.chat, state.contactName, state.profilePictureUrl);
    }
    if (this is ChatsError && error != null) return error((this as ChatsError).message);
    return orElse();
  }
}

class ChatsInitial extends ChatsState {
  const ChatsInitial();
}

class ChatsLoading extends ChatsState {
  const ChatsLoading();
}

class ChatsLoaded extends ChatsState {
  final List<ChatModel> chats;
  const ChatsLoaded(this.chats);
}

class ChatCreated extends ChatsState {
  final ChatModel chat;
  final String contactName;
  final String? profilePictureUrl;
  const ChatCreated(this.chat, this.contactName, {this.profilePictureUrl});
}

class ChatsError extends ChatsState {
  final String message;
  const ChatsError(this.message);
}
