import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import '../repositories/chat_transfer_repository.dart';

@injectable
class GetTargetConversationsUseCase {
  final ChatTransferRepository _repository;

  GetTargetConversationsUseCase(this._repository);

  Future<ApiResult<List<ChatModel>>> execute({required String targetUserId}) {
    return _repository.getTargetConversations(targetUserId: targetUserId);
  }
}
