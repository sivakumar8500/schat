import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_result.dart';
import '../models/chat_view_request_model.dart';
import '../repositories/chat_transfer_repository.dart';

@injectable
class RevokeChatViewRequestUseCase {
  final ChatTransferRepository _repository;

  RevokeChatViewRequestUseCase(this._repository);

  Future<ApiResult<ChatViewRequestModel>> execute({required String requestId}) {
    return _repository.revokeChatViewRequest(requestId: requestId);
  }
}
