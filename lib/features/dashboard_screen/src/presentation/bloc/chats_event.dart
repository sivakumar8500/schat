import 'package:freezed_annotation/freezed_annotation.dart';

part 'chats_event.freezed.dart';

@freezed
class ChatsEvent with _$ChatsEvent {
  const factory ChatsEvent.fetchChats() = FetchChats;
}
