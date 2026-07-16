import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';
import 'package:schat/utils/common_endpoints.dart';

@LazySingleton(as: DashboardRepository)
class DashboardRepositoryImpl implements DashboardRepository {
  final ApiService _apiService;

  DashboardRepositoryImpl(this._apiService);

  @override
  Future<ApiResult<List<ChatModel>>> getChats() async {
    debugPrint('DEBUG: DashboardRepository.getChats() calling API');
    final result = await _apiService.get<List<ChatModel>>(
      CommonEndpoints.getChats,
      mapper: (json) {
        debugPrint('DEBUG: DashboardRepository.getChats() mapping result: ${json.runtimeType}');
        List<dynamic> list = [];
        if (json is List) {
          list = json;
        } else if (json is Map && json['conversations'] is List) {
          list = json['conversations'] as List;
        }
        return list.map((e) => ChatModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      },
    );
    return result.when(
      success: (chats) {
        debugPrint('DEBUG: DashboardRepository.getChats() SUCCESS: ${chats.length} chats');
        return ApiResult.success(chats);
      },
      failure: (message, statusCode) {
        debugPrint('DEBUG: DashboardRepository.getChats() FAILURE: $message, status: $statusCode');
        return ApiResult.failure(message, statusCode: statusCode);
      },
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
    String? groupPictureUrl,
    String? groupImageUrl,
    required List<String> participantIds,
  }) async {
    final result = await _apiService.post<ChatModel>(
      CommonEndpoints.createGroup,
      data: {
        'group_name': groupName,
        'group_description': groupDescription ?? '',
        'groupPictureUrl': groupPictureUrl ?? '',
        'groupImageUrl': groupImageUrl ?? '',
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
  Future<ApiResult<void>> hideChat(String conversationId) async {
    return _apiService.post<void>(
      CommonEndpoints.hideChat(conversationId),
      mapper: (_) => null,
    );
  }

  @override
  Future<ApiResult<void>> unhideChat(String conversationId) async {
    return _apiService.post<void>(
      CommonEndpoints.unhideChat(conversationId),
      mapper: (_) => null,
    );
  }

  @override
  Future<ApiResult<List<ChatModel>>> getHiddenChats() async {
    final result = await _apiService.get<List<ChatModel>>(
      CommonEndpoints.getChats,
      mapper: (json) {
        debugPrint('DEBUG: DashboardRepository.getHiddenChats() mapping result: ${json.runtimeType}');
        List<dynamic> list = [];
        if (json is Map) {
          list = (json['hiddenConversations'] ?? json['hidedConversations']) as List? ?? [];
        }
        return list.map((e) => ChatModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      },
    );
    return result;
  }

  @override
  Future<ApiResult<void>> muteChat(String conversationId) async {
    return _apiService.post<void>(
      CommonEndpoints.muteChat(conversationId),
      mapper: (_) {},
    );
  }

  @override
  Future<ApiResult<void>> unmuteChat(String conversationId) async {
    return _apiService.post<void>(
      CommonEndpoints.unmuteChat(conversationId),
      mapper: (_) {},
    );
  }

  @override
  Future<ApiResult<void>> deleteChat(String conversationId) async {
    return _apiService.delete<void>(
      CommonEndpoints.deleteChat(conversationId),
      mapper: (_) {},
    );
  }

  @override
  Future<ApiResult<void>> deleteGroup(String groupId) async {
    return _apiService.delete<void>(
      CommonEndpoints.deleteGroup(groupId),
      mapper: (_) {},
    );
  }
}
