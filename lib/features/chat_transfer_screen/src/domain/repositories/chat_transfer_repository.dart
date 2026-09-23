import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import '../models/chat_view_request_model.dart';

abstract class ChatTransferRepository {
  Future<ApiResult<ChatViewRequestModel>> sendChatViewRequest({required String receiverId});
  Future<ApiResult<List<ChatViewRequestModel>>> getChatViewRequests();
  Future<ApiResult<ChatViewRequestModel>> respondChatViewRequest({
    required String requestId,
    required bool accept,
  });
  Future<ApiResult<ChatViewRequestModel>> revokeChatViewRequest({required String requestId});
  Future<ApiResult<List<ChatModel>>> getTargetConversations({required String targetUserId});
}
