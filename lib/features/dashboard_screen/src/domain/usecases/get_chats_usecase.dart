import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';

@lazySingleton
class GetChatsUseCase {
  final DashboardRepository _repository;

  GetChatsUseCase(this._repository);

  Future<ApiResult<List<ChatModel>>> execute() async {
    return await _repository.getChats();
  }
}
