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
    final Map<String, CallHistoryModel> callsMap = {};

    // 1. Fetch from /messages/calls with adaptive limit fallback
    final fallbackLimits = [limit, 35, 25, 15, 10];
    for (final l in fallbackLimits) {
      try {
        final endpoint = CommonEndpoints.getCallHistory(limit: l);
        final result = await _apiService.get<List<CallHistoryModel>>(
          endpoint,
          mapper: (data) {
            final List<CallHistoryModel> parsed = [];
            final items = data is List
                ? data
                : (data is Map
                    ? (data['data'] ?? data['calls'] ?? data['results'] ?? data['items'] ?? [])
                    : []);
            if (items is List) {
              for (final e in items) {
                try {
                  if (e is Map) {
                    parsed.add(CallHistoryModel.fromJson(Map<String, dynamic>.from(e)));
                  }
                } catch (err) {
                  debugPrint('CallHistoryRepositoryImpl: Error parsing call entry: $err');
                }
              }
            }
            return parsed;
          },
        );

        final batch = result.when(
          success: (data) => data,
          failure: (msg, code) {
            debugPrint('CallHistoryRepositoryImpl: Fetching with limit $l returned code $code: $msg');
            return <CallHistoryModel>[];
          },
        );

        if (batch.isNotEmpty) {
          for (final call in batch) {
            if (call.id.isNotEmpty) {
              callsMap[call.id] = call;
            }
          }
          break; // Successfully got the latest calls batch
        }
      } catch (e) {
        debugPrint('CallHistoryRepositoryImpl: Exception fetching with limit $l: $e');
      }
    }

    // 2. Also retrieve call messages from active chat conversations to complete history
    try {
      final chatsResult = await _apiService.get<Map<String, dynamic>>(
        CommonEndpoints.getChats,
        mapper: (data) => data is Map<String, dynamic> ? data : <String, dynamic>{},
      );

      final chatsData = chatsResult.when(
        success: (data) => data,
        failure: (_, _) => <String, dynamic>{},
      );

      final List<dynamic> conversations = [
        if (chatsData['conversations'] is List) ...chatsData['conversations'],
        if (chatsData['hiddenConversations'] is List) ...chatsData['hiddenConversations'],
        if (chatsData['hidedConversations'] is List) ...chatsData['hidedConversations'],
      ];

      for (final conv in conversations) {
        if (conv is! Map) continue;
        final conversationId = (conv['id'] ?? conv['_id'])?.toString();
        if (conversationId == null || conversationId.isEmpty) continue;

        final recipient = conv['recipient'];
        final isGroup = conv['is_group'] == true || conv['isGroup'] == true;
        final groupName = conv['group_name'] ?? conv['groupName'];
        final groupPictureUrl = conv['groupPictureUrl'] ?? conv['group_picture_url'] ?? conv['groupImageUrl'];

        // Check if last_message is a call
        final lastMsg = conv['last_message'] ?? conv['lastMessage'];
        if (lastMsg is Map) {
          final type = (lastMsg['type'] ?? lastMsg['message_type'])?.toString().toLowerCase();
          final callMeta = lastMsg['callMeta'] ?? lastMsg['call_meta'];
          if (type == 'call' || (callMeta is Map && callMeta['callType'] != null)) {
            final msgId = (lastMsg['id'] ?? lastMsg['_id'] ?? lastMsg['message_id'])?.toString();
            if (msgId != null && msgId.isNotEmpty && !callsMap.containsKey(msgId)) {
              try {
                final synthesizedJson = <String, dynamic>{
                  ...Map<String, dynamic>.from(lastMsg),
                  'conversationId': conversationId,
                  'isGroup': isGroup,
                  'groupName': ?groupName,
                  'groupPictureUrl': ?groupPictureUrl,
                  'otherParticipant': ?recipient,
                };
                callsMap[msgId] = CallHistoryModel.fromJson(synthesizedJson);
              } catch (e) {
                debugPrint('CallHistoryRepositoryImpl: Error parsing lastMsg call: $e');
              }
            }
          }
        }

        // Fetch messages for conversation to extract all call records
        try {
          final msgsEndpoint = '${CommonEndpoints.getMessages}$conversationId?limit=50';
          final msgsResult = await _apiService.get<List<dynamic>>(
            msgsEndpoint,
            mapper: (data) => data is List ? data : [],
          );

          final msgs = msgsResult.when(
            success: (data) => data,
            failure: (_, _) => <dynamic>[],
          );

          for (final msg in msgs) {
            if (msg is! Map) continue;
            final type = (msg['type'] ?? msg['message_type'])?.toString().toLowerCase();
            final callMeta = msg['callMeta'] ?? msg['call_meta'];
            if (type == 'call' || (callMeta is Map && callMeta['callType'] != null)) {
              final msgId = (msg['id'] ?? msg['_id'] ?? msg['message_id'])?.toString();
              if (msgId != null && msgId.isNotEmpty && !callsMap.containsKey(msgId)) {
                try {
                  final synthesizedJson = <String, dynamic>{
                    ...Map<String, dynamic>.from(msg),
                    'conversationId': conversationId,
                    'isGroup': isGroup,
                    'groupName': ?groupName,
                    'groupPictureUrl': ?groupPictureUrl,
                    'otherParticipant': ?recipient,
                  };
                  callsMap[msgId] = CallHistoryModel.fromJson(synthesizedJson);
                } catch (e) {
                  debugPrint('CallHistoryRepositoryImpl: Error parsing conversation call: $e');
                }
              }
            }
          }
        } catch (e) {
          debugPrint('CallHistoryRepositoryImpl: Error fetching messages for $conversationId: $e');
        }
      }
    } catch (e) {
      debugPrint('CallHistoryRepositoryImpl: Error fetching conversations call logs: $e');
    }

    final allCalls = callsMap.values.toList();

    // Sort by createdAt descending (newest first)
    allCalls.sort((a, b) {
      final aDate = a.createdAt != null ? DateTime.tryParse(a.createdAt!) : null;
      final bDate = b.createdAt != null ? DateTime.tryParse(b.createdAt!) : null;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    return allCalls;
  }

  @override
  Future<bool> deleteCall(String callId) async {
    try {
      final endpoint = CommonEndpoints.deleteMessage(callId);
      final result = await _apiService.delete(endpoint, mapper: (data) => data);
      final isSuccess = result.when(
        success: (_) => true,
        failure: (err, code) {
          debugPrint('deleteCall error: $err (code: $code)');
          return false;
        },
      );
      return isSuccess;
    } catch (e) {
      debugPrint('Exception in deleteCall: $e');
      return false;
    }
  }
}
