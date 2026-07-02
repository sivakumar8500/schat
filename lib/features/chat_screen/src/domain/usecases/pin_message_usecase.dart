import 'package:injectable/injectable.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';

@lazySingleton
class PinMessageUseCase {
  final ChatRepository _repository;

  PinMessageUseCase(this._repository);

  Future<void> execute(String messageId) async {
    return await _repository.pinMessage(messageId);
  }
}
