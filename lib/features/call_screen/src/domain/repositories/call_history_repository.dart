import 'package:schat/features/call_screen/src/domain/call_history.dart';

abstract class CallHistoryRepository {
  Future<List<CallHistoryModel>> getCallHistory({int limit = 50});
}
