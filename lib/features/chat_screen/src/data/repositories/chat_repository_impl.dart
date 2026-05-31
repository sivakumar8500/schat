import 'package:injectable/injectable.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  @override
  Future<List<MessageModel>> getMessages(String contactId) async {
    // Mock network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      const MessageModel(id: '1', text: 'Hey! How are you doing today?', time: '10:00 AM', isMe: false),
      const MessageModel(id: '2', text: 'I am doing great! Working on the new app design.', time: '10:05 AM', isMe: true, isRead: true),
      const MessageModel(id: '3', text: 'Same here. Just finishing up some meetings.', time: '10:10 AM', isMe: false),
      const MessageModel(id: '4', text: 'Are we still on for lunch later?', time: '10:12 AM', isMe: false),
      const MessageModel(id: '5', text: 'Absolutely! See you at 1PM.', time: '10:15 AM', isMe: true, isRead: false),
    ];
  }

  @override
  Future<bool> sendMessage(MessageModel message) async {
    // Mock network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return true; // Assume success
  }
}
