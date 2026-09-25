import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_result.dart';
import '../models/chat_view_request_model.dart';
import '../repositories/chat_transfer_repository.dart';

@injectable
class GetChatViewRequestsUseCase {
  final ChatTransferRepository _repository;

  GetChatViewRequestsUseCase(this._repository);

  Future<ApiResult<List<ChatViewRequestModel>>> execute() {
    return _repository.getChatViewRequests();
  }
}
