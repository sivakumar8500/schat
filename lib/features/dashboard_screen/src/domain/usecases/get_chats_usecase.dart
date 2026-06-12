import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/dashboard_screen/src/domain/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/chat_repository.dart';

@lazySingleton
class GetChatsUseCase {
  final ChatRepository _repository;

  GetChatsUseCase(this._repository);

  Future<ApiResult<List<ChatModel>>> execute() async {
    return await _repository.getChats();
  }
}
