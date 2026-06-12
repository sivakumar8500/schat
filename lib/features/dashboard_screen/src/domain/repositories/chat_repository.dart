import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/dashboard_screen/src/domain/chat_model.dart';

abstract class ChatRepository {
  Future<ApiResult<List<ChatModel>>> getChats();
}
