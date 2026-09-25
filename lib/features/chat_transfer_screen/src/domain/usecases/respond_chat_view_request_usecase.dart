import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_result.dart';
import '../models/chat_view_request_model.dart';
import '../repositories/chat_transfer_repository.dart';

@injectable
class RespondChatViewRequestUseCase {
  final ChatTransferRepository _repository;

  RespondChatViewRequestUseCase(this._repository);

  Future<ApiResult<ChatViewRequestModel>> execute({
    required String requestId,
    required bool accept,
  }) {
    return _repository.respondChatViewRequest(
      requestId: requestId,
      accept: accept,
    );
  }
}
