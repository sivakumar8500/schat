import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/features/dashboard_screen/src/domain/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/utils/common_endpoints.dart';

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  final ApiService _apiService;

  ChatRepositoryImpl(this._apiService);

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
}
