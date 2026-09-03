import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/utils/common_endpoints.dart';
import 'package:schat/features/call_screen/src/domain/call_history.dart';
import 'package:schat/features/call_screen/src/domain/repositories/call_history_repository.dart';

@LazySingleton(as: CallHistoryRepository)
class CallHistoryRepositoryImpl implements CallHistoryRepository {
  final ApiService _apiService;

  CallHistoryRepositoryImpl(this._apiService);

  @override
  Future<List<CallHistoryModel>> getCallHistory({int limit = 50}) async {
    try {
      final endpoint = CommonEndpoints.getCallHistory(limit: limit);
      final result = await _apiService.get<List<CallHistoryModel>>(
        endpoint,
        mapper: (data) {
          if (data is List) {
            return data
                .map((e) => CallHistoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
          } else if (data is Map) {
            final list = data['data'] ?? data['calls'] ?? data['results'] ?? data['items'] ?? [];
            if (list is List) {
              return list
                  .map((e) => CallHistoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList();
            }
          }
          return <CallHistoryModel>[];
        },
      );

      return result.when(
        success: (data) => data,
        failure: (message, statusCode) {
          debugPrint('Error fetching call history: $message (code: $statusCode)');
          return <CallHistoryModel>[];
        },
      );
    } catch (e, stack) {
      debugPrint('Exception in getCallHistory: $e\n$stack');
      return <CallHistoryModel>[];
    }
  }
}
