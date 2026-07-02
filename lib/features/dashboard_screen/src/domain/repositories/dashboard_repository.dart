import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';

abstract class DashboardRepository {
  Future<ApiResult<List<ChatModel>>> getChats();
  Future<ApiResult<ChatModel>> createChat({
    required bool isGroup,
    String? groupName,
    String? groupDescription,
    required List<String> participantIds,
  });

  Future<ApiResult<ChatModel>> startDirectChat(String participantId);

  Future<ApiResult<ChatModel>> createGroup({
    required String groupName,
    String? groupDescription,
    required List<String> participantIds,
  });
}
