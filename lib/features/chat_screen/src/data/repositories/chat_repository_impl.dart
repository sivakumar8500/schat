import 'package:injectable/injectable.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  @override
  Future<List<MessageModel>> getMessages(String chatId) async {
    // Mock network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      _createMockMessage('1', chatId, 'Hey! How are you doing today?', false),
      _createMockMessage('2', chatId, 'I am doing great! Working on the new app design.', true),
      _createMockMessage('3', chatId, 'Same here. Just finishing up some meetings.', false),
      _createMockMessage('4', chatId, 'Are we still on for lunch later?', false),
      _createMockMessage('5', chatId, 'Absolutely! See you at 1PM.', true),
    ];
  }

  @override
  Future<bool> sendMessage(MessageModel message) async {
    // Mock network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return true; // Assume success
  }

  MessageModel _createMockMessage(String id, String chatId, String text, bool isMe) {
    return MessageModel(
      id: id,
      chatId: chatId,
      type: 'text',
      senderId: isMe ? 'me' : 'other',
      receiverId: isMe ? 'other' : 'me',
      content: MessageContent(text: text),
      security: const MessageSecurity(
        isLocked: false,
        accessUsers: [],
        allowDownload: true,
        allowShare: true,
      ),
      viewControl: const MessageViewControl(
        type: 'standard',
        maxViews: 0,
        viewedBy: [],
        isOpened: true,
      ),
      expiry: const MessageExpiry(
        isEnabled: false,
        expireAt: 0,
      ),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
