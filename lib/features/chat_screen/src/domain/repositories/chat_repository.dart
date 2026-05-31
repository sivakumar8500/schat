import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';

abstract class ChatRepository {
  Future<List<MessageModel>> getMessages(String contactId);
  Future<bool> sendMessage(MessageModel message);
}
