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
    return _apiService.get<List<ChatModel>>(
      CommonEndpoints.getChats,
      mapper: (json) {
        if (json is List) {
          return json.map((e) => ChatModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
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
    return _apiService.post<ChatModel>(
      CommonEndpoints.getChats,
      data: {
        'is_group': isGroup,
        'group_name': groupName ?? 'string',
        'group_description': groupDescription ?? 'string',
        'participant_ids': participantIds,
      },
      mapper: (json) => ChatModel.fromJson(json as Map<String, dynamic>),
    );
  }
}
