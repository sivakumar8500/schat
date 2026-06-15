import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:schat/features/dashboard_screen/src/domain/chat_model.dart';

part 'chats_state.freezed.dart';

@freezed
class ChatsState with _$ChatsState {
  const factory ChatsState.initial() = ChatsInitial;
  const factory ChatsState.loading() = ChatsLoading;
  const factory ChatsState.loaded(List<ChatModel> chats) = ChatsLoaded;
  const factory ChatsState.chatCreated(ChatModel chat, String contactName, {String? profilePictureUrl}) = ChatCreated;
  const factory ChatsState.error(String message) = ChatsError;
}
