import 'package:injectable/injectable.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';

@lazySingleton
class GetPinnedMessagesUseCase {
  final ChatRepository _repository;

  GetPinnedMessagesUseCase(this._repository);

  Future<List<MessageModel>> execute(String conversationId) async {
    return await _repository.getPinnedMessages(conversationId);
  }
}
