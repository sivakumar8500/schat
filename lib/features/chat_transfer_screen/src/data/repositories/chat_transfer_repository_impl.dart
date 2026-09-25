import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/models/chat_view_request_model.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/repositories/chat_transfer_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import 'package:schat/utils/common_endpoints.dart';

@Injectable(as: ChatTransferRepository)
class ChatTransferRepositoryImpl implements ChatTransferRepository {
  final ApiService _apiService;

  ChatTransferRepositoryImpl(this._apiService);

  @override
  Future<ApiResult<ChatViewRequestModel>> sendChatViewRequest({required String receiverId}) async {
    return _apiService.post<ChatViewRequestModel>(
      CommonEndpoints.chatViewRequests,
      data: {
        'receiverId': receiverId,
        'receiver_id': receiverId,
      },
      mapper: (json) => ChatViewRequestModel.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  @override
  Future<ApiResult<List<ChatViewRequestModel>>> getChatViewRequests() async {
    return _apiService.get<List<ChatViewRequestModel>>(
      CommonEndpoints.chatViewRequests,
      mapper: (json) {
        if (json is List) {
          return json
              .map((e) => ChatViewRequestModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        } else if (json is Map && json['requests'] is List) {
          return (json['requests'] as List)
              .map((e) => ChatViewRequestModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResult<ChatViewRequestModel>> respondChatViewRequest({
    required String requestId,
    required bool accept,
  }) async {
    return _apiService.post<ChatViewRequestModel>(
      CommonEndpoints.respondChatViewRequest(requestId),
      data: {
        'accept': accept,
      },
      mapper: (json) => ChatViewRequestModel.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  @override
  Future<ApiResult<ChatViewRequestModel>> revokeChatViewRequest({required String requestId}) async {
    return _apiService.post<ChatViewRequestModel>(
      CommonEndpoints.revokeChatViewRequest(requestId),
      data: {},
      mapper: (json) => ChatViewRequestModel.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  @override
  Future<ApiResult<List<ChatModel>>> getTargetConversations({required String targetUserId}) async {
    return _apiService.get<List<ChatModel>>(
      CommonEndpoints.getTargetConversations(targetUserId),
      mapper: (json) {
        if (json is Map && json['conversations'] is List) {
          return (json['conversations'] as List)
              .map((e) => ChatModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        } else if (json is List) {
          return json
              .map((e) => ChatModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
        return [];
      },
    );
  }
}
