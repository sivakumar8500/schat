import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_state.dart';
import 'package:schat/injection.dart';
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
    if (!isGroup && participantIds.length == 1) {
      return startDirectChat(participantIds.first);
    }
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
    final targetId = participantId.trim();
    final myId = getIt.isRegistered<StorageService>() ? getIt<StorageService>().getUserId() : null;
    if (myId != null && myId.trim() == targetId) {
      return ApiResult.failure('Cannot start a chat with yourself');
    }
    // 1. Check in-memory ChatsBloc state first to avoid redundant POST /chats/ (which 500s on existing 1-to-1 chats)
    try {
      if (getIt.isRegistered<ChatsBloc>()) {
        final chatsState = getIt<ChatsBloc>().state;
        if (chatsState is ChatsLoaded) {
          for (final c in chatsState.chats) {
            if (!c.isGroup && c.recipient.id.trim() == targetId && c.id.isNotEmpty) {
              debugPrint('DEBUG: startDirectChat found existing chat in ChatsBloc: ${c.id} for recipient $targetId');
              return ApiResult.success(c);
            }
          }
        }
      }
    } catch (_) {}

    // 2. Check server chat list before attempting to create a new 1-to-1 chat
    try {
      final existingResult = await getChats();
      ChatModel? matchedChat;
      existingResult.when(
        success: (chats) {
          for (final c in chats) {
            if (!c.isGroup && c.recipient.id.trim() == targetId && c.id.isNotEmpty) {
              matchedChat = c;
              break;
            }
          }
        },
        failure: (_, _) {},
      );
      if (matchedChat != null) {
        debugPrint('DEBUG: startDirectChat found existing chat via getChats(): ${matchedChat!.id} for recipient $targetId');
        return ApiResult.success(matchedChat!);
      }
    } catch (_) {}

    // 3. Create new direct chat if none exists
    final result = await _apiService.post<ChatModel>(
      CommonEndpoints.getChats,
      data: {
        'is_group': false,
        'group_name': 'string',
        'group_description': 'string',
        'participant_ids': [targetId],
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
    try {
      debugPrint('DEBUG: DashboardRepository.createGroup called with name=$groupName, participants=$participantIds');
      final result = await _apiService.post<ChatModel>(
        CommonEndpoints.createGroup,
        data: {
          'group_name': groupName,
          'group_description': groupDescription ?? '',
          'groupPictureUrl': groupPictureUrl ?? '',
          'groupImageUrl': groupImageUrl ?? '',
          'participant_ids': participantIds,
        },
        mapper: (json) {
          debugPrint('DEBUG: DashboardRepository.createGroup mapper received json: $json');
          if (json is Map) {
            return ChatModel.fromJson(Map<String, dynamic>.from(json));
          }
          throw Exception('Expected Map for createGroup response, received: ${json.runtimeType}');
        },
      );
      final ApiResult<ChatModel> finalResult = result.when(
        success: (chat) {
          debugPrint('DEBUG: DashboardRepository.createGroup SUCCESS: chat.id=${chat.id}, group_name=${chat.groupName}');
          return ApiResult<ChatModel>.success(chat);
        },
        failure: (message, statusCode) {
          debugPrint('DEBUG: DashboardRepository.createGroup FAILURE: $message (code: $statusCode)');
          return ApiResult<ChatModel>.failure(message, statusCode: statusCode);
        },
      );
      return finalResult;
    } catch (e, st) {
      debugPrint('DEBUG: DashboardRepository.createGroup exception: $e\n$st');
      return ApiResult<ChatModel>.failure(e.toString());
    }
  }

  @override
  Future<ApiResult<void>> hideChat(String conversationId) async {
    try {
      getIt<StorageService>().saveChatHidden(conversationId, true);
    } catch (_) {}
    return _apiService.post<void>(
      CommonEndpoints.hideChat(conversationId),
      mapper: (_) {},
    );
  }

  @override
  Future<ApiResult<void>> unhideChat(String conversationId) async {
    try {
      getIt<StorageService>().saveChatHidden(conversationId, false);
    } catch (_) {}
    return _apiService.post<void>(
      CommonEndpoints.unhideChat(conversationId),
      mapper: (_) {},
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
          list = (json['hidden_conversations'] ??
                  json['hiddenConversations'] ??
                  json['hided_conversations'] ??
                  json['hidedConversations']) as List? ??
              [];
        }
        final chats = list.map((e) => ChatModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        for (final c in chats) {
          if (c.id.isNotEmpty) {
            try {
              getIt<StorageService>().saveChatHidden(c.id, true);
            } catch (_) {}
          }
        }
        return chats;
      },
    );
    return result;
  }

  @override
  Future<ApiResult<List<ChatModel>>> getLockedChats() async {
    final result = await _apiService.get<List<ChatModel>>(
      CommonEndpoints.getLockedChats,
      mapper: (json) {
        debugPrint('DEBUG: DashboardRepository.getLockedChats() mapping result: ${json.runtimeType}');
        List<dynamic> list = [];
        if (json is List) {
          list = json;
        } else if (json is Map && (json['locked_conversations'] ?? json['lockedConversations'] ?? json['conversations']) is List) {
          list = (json['locked_conversations'] ?? json['lockedConversations'] ?? json['conversations']) as List;
        }
        final chats = list.map((e) => ChatModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        for (final c in chats) {
          if (c.id.isNotEmpty) {
            try {
              getIt<StorageService>().saveChatLocked(c.id, true);
            } catch (_) {}
          }
        }
        return chats;
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
