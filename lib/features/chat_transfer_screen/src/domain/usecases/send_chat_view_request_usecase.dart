import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_result.dart';
import '../models/chat_view_request_model.dart';
import '../repositories/chat_transfer_repository.dart';

@injectable
class SendChatViewRequestUseCase {
  final ChatTransferRepository _repository;

  SendChatViewRequestUseCase(this._repository);

  Future<ApiResult<ChatViewRequestModel>> execute({required String receiverId}) {
    return _repository.sendChatViewRequest(receiverId: receiverId);
  }
}
