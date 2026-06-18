import 'package:freezed_annotation/freezed_annotation.dart';

part 'chats_event.freezed.dart';

@freezed
class ChatsEvent with _$ChatsEvent {
  const factory ChatsEvent.fetchChats() = FetchChats;
  const factory ChatsEvent.createChat({
    required String participantId,
    required String contactName,
    String? profilePictureUrl,
  }) = CreateChat;
  const factory ChatsEvent.updateUserStatus({
    required String userId,
    required bool isOnline,
  }) = UpdateUserStatus;
}
