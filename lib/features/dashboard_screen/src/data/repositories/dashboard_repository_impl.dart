import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/features/dashboard_screen/src/domain/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';
import 'package:schat/utils/common_endpoints.dart';

@LazySingleton(as: DashboardRepository)
class DashboardRepositoryImpl implements DashboardRepository {
  final ApiService _apiService;

  DashboardRepositoryImpl(this._apiService);

  @override
  Future<ApiResult<List<ChatModel>>> getChats() async {
    final result = await _apiService.get<List<ChatModel>>(
      CommonEndpoints.getChats,
      mapper: (json) {
        if (json is List) {
          return json.map((e) => ChatModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
    return result.when(
      success: (chats) => ApiResult.success(chats),
      failure: (message, statusCode) => ApiResult.failure(message, statusCode: statusCode),
    );
  }

  @override
  Future<ApiResult<ChatModel>> createChat({
    required bool isGroup,
    String? groupName,
    String? groupDescription,
    required List<String> participantIds,
  }) async {
    final result = await _apiService.post<ChatModel>(
      CommonEndpoints.getChats,
      data: {
        'is_group': isGroup,
        'group_name': groupName ?? 'string',
        'group_description': groupDescription ?? 'string',
        'participant_ids': participantIds,
      },
      mapper: (json) => ChatModel.fromJson(json as Map<String, dynamic>),
    );
    return result.when(
      success: (chat) => ApiResult.success(chat),
      failure: (message, statusCode) => ApiResult.failure(message, statusCode: statusCode),
    );
  }

  @override
  Future<ApiResult<ChatModel>> startDirectChat(String participantId) async {
    final result = await _apiService.post<ChatModel>(
      CommonEndpoints.getChats,
      data: {
        'is_group': false,
        'group_name': 'string',
        'group_description': 'string',
        'participant_ids': [participantId],
      },
      mapper: (json) => ChatModel.fromJson(json as Map<String, dynamic>),
    );
    return result.when(
      success: (chat) => ApiResult.success(chat),
      failure: (message, statusCode) => ApiResult.failure(message, statusCode: statusCode),
    );
  }

  @override
  Future<ApiResult<ChatModel>> createGroup({
    required String groupName,
    String? groupDescription,
    required List<String> participantIds,
  }) async {
    final result = await _apiService.post<ChatModel>(
      CommonEndpoints.createGroup,
      data: {
        'group_name': groupName,
        'group_description': groupDescription ?? '',
        'participant_ids': participantIds,
      },
      mapper: (json) => ChatModel.fromJson(json as Map<String, dynamic>),
    );
    return result.when(
      success: (chat) => ApiResult.success(chat),
      failure: (message, statusCode) => ApiResult.failure(message, statusCode: statusCode),
    );
  }
}
