import 'package:injectable/injectable.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';

@lazySingleton
class UnpinMessageUseCase {
  final ChatRepository _repository;

  UnpinMessageUseCase(this._repository);

  Future<void> execute(String messageId) async {
    return await _repository.unpinMessage(messageId);
  }
}
