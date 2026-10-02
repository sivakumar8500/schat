import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_shares_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/theme_color_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_screen/src/domain/models/chat_media_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/screen_permission_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/scheduled_message_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/media_permissions_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/media_access_tree_model.dart';
import 'package:http/http.dart' as http;
import 'package:schat/utils/common_endpoints.dart';

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  final ApiService _apiService;

  ChatRepositoryImpl(this._apiService);

  @override
  Future<List<MessageModel>> getMessages(String conversationId, {int? limit, int? skip}) async {
    final queryParams = <String, dynamic>{
      'limit': limit ?? 50,
    };
    if (skip != null) {
      queryParams['skip'] = skip;
    }
    final result = await _apiService.get<List<MessageModel>>(
      '${CommonEndpoints.getMessages}$conversationId',
      queryParameters: queryParams,
      mapper: (data) {
        if (data is List) {
          return data.map((json) => MessageModel.fromJson(json as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );

    return result.when(
      success: (messages) => messages,
      failure: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<bool> sendMessage(MessageModel message) async {
    return true;
  }

  @override
  Future<String?> uploadMedia({
    required String conversationId,
    required String filePath,
    required String fileName,
    required String mediaType,
    required String mimeType,
    required int fileSizeBytes,
    Uint8List? fileBytes,
  }) async {
    try {
      final requestData = <String, dynamic>{
        'media_type': mediaType,
        'mime_type': mimeType,
        'file_size_bytes': fileSizeBytes,
        'filename': fileName,
      };
      if (conversationId.isNotEmpty) {
        requestData['conversation_id'] = conversationId;
      }

      final requestResult = await _apiService.post<Map<String, dynamic>>(
        CommonEndpoints.requestUpload,
        data: requestData,
        mapper: (data) => Map<String, dynamic>.from(data as Map),
      );

      final uploadMeta = requestResult.when(
        success: (data) => data,
        failure: (error, statusCode) => throw Exception('Failed to request upload URL: $error'),
      );

      final mediaId = uploadMeta['media_id']?.toString() ?? '';
      String uploadUrl = uploadMeta['upload_url']?.toString() ?? '';
      final objectKey = uploadMeta['object_key']?.toString() ?? '';

      if (uploadUrl.contains('minio')) {
        try {
          final serverUri = Uri.parse(CommonEndpoints.baseUrl);
          final host = serverUri.host;
          if (host.isNotEmpty) {
            uploadUrl = uploadUrl.replaceAll('minio', host);
          }
        } catch (_) {}
      }

      if (mediaId.isEmpty || uploadUrl.isEmpty || objectKey.isEmpty) {
        throw Exception('Invalid metadata received from request-upload');
      }

      Uint8List bytes;
      if (kIsWeb) {
        if (fileBytes == null) throw Exception('File bytes must not be null for web uploads');
        bytes = fileBytes;
      } else {
        if (fileBytes != null) {
          bytes = fileBytes;
        } else {
          final file = File(filePath);
          if (!await file.exists()) throw Exception('File does not exist at path: $filePath');
          bytes = await file.readAsBytes();
        }
      }

      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        body: bytes,
        headers: {'Content-Type': mimeType},
      );

      if (uploadResponse.statusCode != 200) {
        throw Exception('S3 upload failed with status code: ${uploadResponse.statusCode}');
      }

      final completeResult = await _apiService.post<Map<String, dynamic>>(
        CommonEndpoints.completeUpload(mediaId),
        data: {'sha256_checksum': null},
        mapper: (data) => Map<String, dynamic>.from(data as Map),
      );

      final res = completeResult.when(
        success: (_) {
          debugPrint('========\nmediaid: $mediaId\n========');
          return objectKey;
        },
        failure: (error, statusCode) => throw Exception('Failed to complete upload: $error'),
      );
      return res;
    } catch (e) {
      debugPrint('Error in uploadMedia: $e');
      rethrow;
    }
  }

  @override
  Future<List<ChatMediaModel>> getConversationMedia(String conversationId, {int? limit}) async {
    final result = await _apiService.get<List<ChatMediaModel>>(
      CommonEndpoints.getConversationMedia(conversationId),
      queryParameters: {'limit': limit ?? 50},
      mapper: (data) {
        // Handle direct list response
        if (data is List) {
          return data
              .map((json) => ChatMediaModel.fromJson(Map<String, dynamic>.from(json as Map)))
              .toList();
        }
        // Handle wrapped/paginated responses: {"items": [...]} / {"media": [...]} / {"data": [...]}
        if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          final listData = map['items'] ?? map['media'] ?? map['data'] ??
              map['results'] ?? map['content'];
          if (listData is List) {
            return listData
                .map((json) => ChatMediaModel.fromJson(Map<String, dynamic>.from(json as Map)))
                .toList();
          }
        }
        debugPrint('[ChatRepo] getConversationMedia: unexpected response type: ${data.runtimeType}');
        return [];
      },
    );

    return result.when(
      success: (mediaList) => mediaList,
      failure: (error, statusCode) {
        debugPrint('[ChatRepo] getConversationMedia failed [$statusCode]: $error');
        return [];        // Return empty instead of throwing so UI shows empty state
      },
    );
  }

  @override
  Future<Map<String, dynamic>> getGroupDetails(String groupId) async {
    final result = await _apiService.get<Map<String, dynamic>>(
      CommonEndpoints.getGroupDetails(groupId),
      mapper: (data) => Map<String, dynamic>.from(data as Map),
    );

    return result.when(
      success: (data) => data,
      failure: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<void> toggleFavorite({required String conversationId, required bool isFavorite}) async {
    final endpoint = isFavorite 
        ? CommonEndpoints.favoriteChat(conversationId) 
        : CommonEndpoints.unfavoriteChat(conversationId);
    final result = await _apiService.post(endpoint, mapper: (data) => data);
    result.when(
      success: (_) {},
      failure: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<void> toggleMute({required String conversationId, required bool isMuted}) async {
    final endpoint = isMuted 
        ? CommonEndpoints.muteChat(conversationId) 
        : CommonEndpoints.unmuteChat(conversationId);
    final result = await _apiService.post(endpoint, mapper: (data) => data);
    result.when(
      success: (_) {},
      failure: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<void> updateChatPrivacySettings({
    required String conversationId,
    bool? readReceiptsEnabled,
    bool? typingIndicatorsEnabled,
  }) async {
    final payload = <String, dynamic>{};
    if (readReceiptsEnabled != null) {
      payload['read_receipts_enabled'] = readReceiptsEnabled;
    }
    if (typingIndicatorsEnabled != null) {
      payload['typing_indicators_enabled'] = typingIndicatorsEnabled;
    }

    final result = await _apiService.put(
      CommonEndpoints.updateChatPrivacy(conversationId),
      data: payload,
      mapper: (data) => data,
    );
    result.when(
      success: (_) {},
      failure: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<void> forwardMessage({required String messageId, required String targetConversationId}) async {
    final result = await _apiService.post(
      CommonEndpoints.forwardMessage(messageId),
      data: {'conversationId': targetConversationId},
      mapper: (data) => data,
    );
    result.when(
      success: (_) {},
      failure: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<void> setDisappearingTimer({required String conversationId, int? seconds}) async {
    final result = await _apiService.post(
      CommonEndpoints.setDisappearingTimer(conversationId),
      data: {'timer_seconds': seconds},
      mapper: (data) => data,
    );
    result.when(
      success: (_) {},
      failure: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    final result = await _apiService.delete(
      CommonEndpoints.deleteGroup(groupId),
      mapper: (data) => data,
    );
    result.when(
      success: (_) {},
      failure: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<void> updateGroupInfo({
    required String groupId,
    String? name,
    String? description,
    String? iconUrl,
    List<String>? participantIds,
    bool? onlyAdminsSendMessages,
  }) async {
    final Map<String, dynamic> data = {};
    if (name != null) data['group_name'] = name;
    if (description != null) data['group_description'] = description;
    if (iconUrl != null) {
      data['groupPictureUrl'] = iconUrl;
      data['groupImageUrl'] = iconUrl;
    }
    if (participantIds != null) {
      data['participant_ids'] = participantIds;
      data['participantIds'] = participantIds;
    }
    if (onlyAdminsSendMessages != null) {
      data['only_admins_send_messages'] = onlyAdminsSendMessages;
      data['onlyAdminsSendMessages'] = onlyAdminsSendMessages;
    }

    final result = await _apiService.patch(
      CommonEndpoints.updateGroup(groupId),
      data: data,
      mapper: (data) => data,
    );
    result.when(
      success: (_) {},
      failure: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<void> addGroupParticipants({required String groupId, required List<String> userIds}) async {
    final result = await _apiService.post(
      CommonEndpoints.addGroupParticipants(groupId),
      // Send both snake_case and camelCase keys to support all backend versions robustly
      data: {
        'participant_ids': userIds,
        'participantIds': userIds,
      },
      mapper: (data) => data,
    );
    result.when(
      success: (_) {},
      failure: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<void> removeGroupParticipant({required String groupId, required String userId}) async {
    final result = await _apiService.delete(
      CommonEndpoints.removeGroupParticipant(groupId, userId),
      mapper: (data) => data,
    );
    result.when(
      success: (_) {},
      failure: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<void> promoteGroupAdmin({required String groupId, required String userId}) async {
    final result = await _apiService.post(
      CommonEndpoints.promoteGroupAdmin(groupId, userId),
      mapper: (data) => data,
    );
    result.when(
      success: (_) {},
      failure: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<void> demoteGroupAdmin({required String groupId, required String userId}) async {
    final result = await _apiService.delete(
      CommonEndpoints.demoteGroupAdmin(groupId, userId),
      mapper: (data) => data,
    );
    result.when(
      success: (_) {},
      failure: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<void> pinMessage(String messageId) async {
    final result = await _apiService.post(
      CommonEndpoints.pinMessage(messageId),
      mapper: (data) => data,
    );
    result.when(
      success: (_) {},
      failure: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<void> unpinMessage(String messageId) async {
    final result = await _apiService.post(
      CommonEndpoints.unpinMessage(messageId),
      mapper: (data) => data,
    );
    result.when(
      success: (_) {},
      failure: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<List<MessageModel>> getPinnedMessages(String conversationId) async {
    final result = await _apiService.get<List<MessageModel>>(
      CommonEndpoints.getPinnedMessages(conversationId),
      mapper: (data) {
        if (data is List) {
          return data.map((json) => MessageModel.fromJson(json as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );

    return result.when(
      success: (messages) => messages,
      failure: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<String?> clearChat(String conversationId) async {
    final result = await _apiService.post<Map<String, dynamic>>(
      CommonEndpoints.clearChat(conversationId),
      mapper: (data) => Map<String, dynamic>.from(data as Map),
    );

    return result.when(
      success: (data) {
        // Server returns ConversationResponse; extract clearedAt timestamp
        return data['clearedAt']?.toString() ??
            data['cleared_at']?.toString();
      },
      failure: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<List<ThemeColorModel>> getThemes() async {
    final result = await _apiService.get<List<ThemeColorModel>>(
      CommonEndpoints.getThemes,
      mapper: (data) {
        if (data is List) {
          return data
              .map((json) => ThemeColorModel.fromJson(Map<String, dynamic>.from(json as Map)))
              .toList();
        }
        return [];
      },
    );

    return result.when(
      success: (themes) => themes,
      failure: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<void> updateTheme({
    required String conversationId,
    String? themeColorId,
    String? customWallpaperUrl,
    bool applyToAll = false,
  }) async {
    final payload = <String, dynamic>{
      'themeColorId': themeColorId,
      'customWallpaperUrl': customWallpaperUrl,
      'applyToAll': applyToAll,
    };

    final endpoint = applyToAll
        ? CommonEndpoints.defaultTheme
        : CommonEndpoints.updateTheme(conversationId);

    final result = await _apiService.put(
      endpoint,
      data: payload,
      mapper: (data) => data,
    );
    result.when(
      success: (_) {},
      failure: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<void> resetTheme({
    required String conversationId,
    bool resetAll = false,
  }) async {
    final endpoint = resetAll
        ? CommonEndpoints.defaultTheme
        : CommonEndpoints.resetConversationTheme(conversationId);

    final result = await _apiService.delete(
      endpoint,
      mapper: (data) => data,
    );
    result.when(
      success: (_) {},
      failure: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<void> updateMessageSecurity(
    String messageId, {
    required bool allowShare,
    required bool allowDownload,
    bool allowView = true,
    bool isLocked = false,
    List<String> accessUsers = const [],
  }) async {
    final result = await _apiService.patch(
      CommonEndpoints.updateMessageSecurity(messageId),
      data: {
        'security': {
          'isLocked': isLocked,
          'accessUsers': accessUsers,
          'allowDownload': allowDownload,
          'allowShare': allowShare,
          'allowView': allowView,
        },
      },
      mapper: (data) => data,
    );
    result.when(
      success: (_) {},
      failure: (error, statusCode) => debugPrint('updateMessageSecurity error: $error'),
    );
  }

  @override
  Future<MessageSharesModel> getMessageShares(String messageId) async {
    final result = await _apiService.get<MessageSharesModel>(
      CommonEndpoints.getMessageShares(messageId),
      mapper: (data) {
        if (data is Map) {
          return MessageSharesModel.fromJson(Map<String, dynamic>.from(data));
        }
        return const MessageSharesModel(count: 0, users: []);
      },
    );
    return result.when(
      success: (model) => model,
      failure: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<bool> scheduleMessage(Map<String, dynamic> requestData) async {
    final result = await _apiService.post(
      CommonEndpoints.scheduleMessage,
      data: requestData,
      mapper: (data) => true,
    );

    return result.when(
      success: (_) => true,
      failure: (error, _) => throw Exception(error),
    );
  }

  List<ScheduledMessageModel> _parseScheduledMessagesList(dynamic data, {String? conversationId}) {
    List<dynamic> rawList = [];
    if (data is List) {
      rawList = data;
    } else if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map['data'] is List) {
        rawList = map['data'] as List;
      } else if (map['scheduled_messages'] is List) {
        rawList = map['scheduled_messages'] as List;
      } else if (map['scheduledMessages'] is List) {
        rawList = map['scheduledMessages'] as List;
      } else if (map['messages'] is List) {
        rawList = map['messages'] as List;
      } else if (map['items'] is List) {
        rawList = map['items'] as List;
      } else if (map['results'] is List) {
        rawList = map['results'] as List;
      } else if (map['records'] is List) {
        rawList = map['records'] as List;
      } else if (map['data'] is Map) {
        final inner = Map<String, dynamic>.from(map['data'] as Map);
        if (inner['items'] is List) {
          rawList = inner['items'] as List;
        } else if (inner['messages'] is List) {
          rawList = inner['messages'] as List;
        } else if (inner['scheduled_messages'] is List) {
          rawList = inner['scheduled_messages'] as List;
        } else if (inner['scheduledMessages'] is List) {
          rawList = inner['scheduledMessages'] as List;
        } else if (inner['results'] is List) {
          rawList = inner['results'] as List;
        } else if (inner['records'] is List) {
          rawList = inner['records'] as List;
        } else if (inner['data'] is List) {
          rawList = inner['data'] as List;
        }
      } else if (map['id'] != null || map['_id'] != null || map['scheduled_message_id'] != null) {
        rawList = [map];
      }
    }

    final parsed = rawList
        .whereType<Map>()
        .map((item) => ScheduledMessageModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return parsed;
  }

  @override
  Future<List<ScheduledMessageModel>> getScheduledMessages({String? conversationId}) async {
    try {
      final endpoint = CommonEndpoints.getScheduledMessages(conversationId: conversationId);
      final result = await _apiService.get<List<ScheduledMessageModel>>(
        endpoint,
        mapper: (data) => _parseScheduledMessagesList(data, conversationId: conversationId),
      );

      final list = result.when(
        success: (items) => items,
        failure: (error, statusCode) => <ScheduledMessageModel>[],
      );

      if (list.isNotEmpty) {
        return list;
      }

      // Fallback: If conversation_id query returned empty, fetch base scheduled messages
      if (conversationId != null && conversationId.trim().isNotEmpty) {
        final fallbackResult = await _apiService.get<List<ScheduledMessageModel>>(
          CommonEndpoints.scheduleMessage,
          mapper: (data) => _parseScheduledMessagesList(data, conversationId: conversationId),
        );

        final fallbackList = fallbackResult.when(
          success: (items) => items,
          failure: (error, statusCode) => <ScheduledMessageModel>[],
        );

        if (fallbackList.isNotEmpty) {
          final target = conversationId.trim().toLowerCase();
          final filtered = fallbackList.where((m) {
            final conv = m.conversationId.trim().toLowerCase();
            return conv == target ||
                conv.isEmpty ||
                conv.replaceAll('-', '') == target.replaceAll('-', '');
          }).toList();
          return filtered.isNotEmpty ? filtered : fallbackList;
        }
      }

      return list;
    } catch (e) {
      debugPrint('Error in getScheduledMessages: $e');
      return [];
    }
  }

  @override
  Future<bool> cancelScheduledMessage(String scheduledMessageId) async {
    final result = await _apiService.delete(
      CommonEndpoints.cancelScheduledMessage(scheduledMessageId),
      mapper: (data) => true,
    );

    return result.when(
      success: (_) => true,
      failure: (error, _) => throw Exception(error),
    );
  }

  @override
  Future<ScheduledMessageModel> updateScheduledMessage(
    String scheduledMessageId,
    Map<String, dynamic> requestData,
  ) async {
    final result = await _apiService.put<ScheduledMessageModel>(
      CommonEndpoints.updateScheduledMessage(scheduledMessageId),
      data: requestData,
      mapper: (data) => ScheduledMessageModel.fromJson(data as Map<String, dynamic>),
    );

    return result.when(
      success: (model) => model,
      failure: (error, _) => throw Exception(error),
    );
  }

  @override
  Future<bool> shareMedia({
    required String mediaId,
    required String granteeId,
    String? parentGrantId,
    bool canView = true,
    bool canDownload = false,
    bool canShare = false,
  }) async {
    final result = await _apiService.post(
      CommonEndpoints.shareMedia(mediaId),
      data: {
        'grantee_id': granteeId,
        ...?parentGrantId == null ? null : {'parent_grant_id': parentGrantId},
        'permissions': {
          'can_view': canView,
          'can_download': canDownload,
          'can_share': canShare,
        },
      },
    );

    return result.when(
      success: (_) => true,
      failure: (error, _) => throw Exception(error),
    );
  }

  @override
  Future<MediaPermissionsModel> getMediaPermissions(String mediaId) async {
    final result = await _apiService.get<MediaPermissionsModel>(
      CommonEndpoints.mediaPermissions(mediaId),
      mapper: (data) => MediaPermissionsModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );

    return result.when(
      success: (data) => data,
      failure: (error, _) => throw Exception(error),
    );
  }

  @override
  Future<MediaAccessTreeModel> getMediaAccessTree(String mediaId) async {
    final result = await _apiService.get<MediaAccessTreeModel>(
      CommonEndpoints.mediaAccessTree(mediaId),
      mapper: (data) => MediaAccessTreeModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );

    return result.when(
      success: (data) => data,
      failure: (error, _) => throw Exception(error),
    );
  }

  @override
  Future<bool> setMediaOwnerOverride({
    required String mediaId,
    required String grantId,
    required bool canView,
    required bool canDownload,
    required bool canShare,
  }) async {
    final result = await _apiService.patch(
      CommonEndpoints.mediaOwnerOverride(mediaId, grantId),
      data: {
        'owner_override': {
          'can_view': canView,
          'can_download': canDownload,
          'can_share': canShare,
        },
      },
    );

    return result.when(
      success: (_) => true,
      failure: (error, _) => throw Exception(error),
    );
  }

  @override
  Future<bool> revokeMediaShareGrant({
    required String mediaId,
    required String grantId,
  }) async {
    final result = await _apiService.delete(
      CommonEndpoints.mediaRevokeGrant(mediaId, grantId),
    );

    return result.when(
      success: (_) => true,
      failure: (error, _) => throw Exception(error),
    );
  }

  @override
  Future<bool> revokeAllMediaShares(String mediaId) async {
    final result = await _apiService.post(
      CommonEndpoints.mediaRevokeAll(mediaId),
    );

    return result.when(
      success: (_) => true,
      failure: (error, _) => throw Exception(error),
    );
  }

  @override
  Future<ScreenPermissionModel> requestScreenPermission({
    required String conversationId,
    required String permissionType,
    int? allowedCount,
    int? durationSeconds,
  }) async {
    final result = await _apiService.post<ScreenPermissionModel>(
      CommonEndpoints.screenPermissionRequest,
      data: {
        'conversation_id': conversationId,
        'permission_type': permissionType,
        ...?allowedCount == null ? null : {'allowed_count': allowedCount},
        ...?durationSeconds == null ? null : {'duration_seconds': durationSeconds},
      },
      mapper: (data) => ScreenPermissionModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );

    return result.when(
      success: (data) => data,
      failure: (error, _) => throw Exception(error),
    );
  }

  @override
  Future<ScreenPermissionModel> respondToScreenPermission({
    required String requestId,
    required String action,
  }) async {
    final result = await _apiService.post<ScreenPermissionModel>(
      CommonEndpoints.screenPermissionRespond(requestId),
      data: {'action': action},
      mapper: (data) => ScreenPermissionModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );

    return result.when(
      success: (data) => data,
      failure: (error, _) => throw Exception(error),
    );
  }

  @override
  Future<List<ScreenPermissionModel>> getPendingScreenPermissions() async {
    final result = await _apiService.get<List<ScreenPermissionModel>>(
      CommonEndpoints.screenPermissionPending,
      mapper: (data) {
        if (data is List) {
          return data
              .map((e) => ScreenPermissionModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
        return [];
      },
    );

    return result.when(
      success: (data) => data,
      failure: (error, _) => [],
    );
  }

  @override
  Future<ScreenPermissionModel?> getActiveScreenPermission(String conversationId) async {
    final result = await _apiService.get<ScreenPermissionModel?>(
      CommonEndpoints.screenPermissionActive(conversationId),
      mapper: (data) {
        if (data != null && data is Map) {
          return ScreenPermissionModel.fromJson(Map<String, dynamic>.from(data));
        }
        return null;
      },
    );

    return result.when(
      success: (data) => data,
      failure: (error, _) => null,
    );
  }

  @override
  Future<ScreenPermissionModel> consumeScreenPermission(String requestId) async {
    final result = await _apiService.post<ScreenPermissionModel>(
      CommonEndpoints.screenPermissionConsume(requestId),
      mapper: (data) => ScreenPermissionModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );

    return result.when(
      success: (data) => data,
      failure: (error, _) => throw Exception(error),
    );
  }

  @override
  Future<bool> deleteMessageForEveryone(String messageId) async {
    try {
      final result = await _apiService.delete(
        CommonEndpoints.deleteMessage(messageId),
        mapper: (data) => data,
      );
      final isSuccess = result.when(
        success: (_) => true,
        failure: (error, _) {
          debugPrint('deleteMessageForEveryone API error: $error');
          return false;
        },
      );
      return isSuccess;
    } catch (e) {
      debugPrint('deleteMessageForEveryone exception: $e');
      return false;
    }
  }

  @override
  Future<ChatLockStatusModel> getChatLockStatus() async {
    try {
      final result = await _apiService.get<ChatLockStatusModel>(
        CommonEndpoints.getLockStatus,
        mapper: (data) => ChatLockStatusModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
      final value = result.when(
        success: (data) => data,
        failure: (error, _) => const ChatLockStatusModel(),
      );
      return value;
    } catch (_) {
      return const ChatLockStatusModel();
    }
  }

  @override
  Future<bool> setChatLockPassword(String password, {String? oldPassword}) async {
    try {
      final data = <String, dynamic>{'password': password};
      if (oldPassword != null && oldPassword.isNotEmpty) {
        data['oldPassword'] = oldPassword;
      }
      final result = await _apiService.post(
        CommonEndpoints.setLockPassword,
        data: data,
        mapper: (d) => d,
      );
      final value = result.when(
        success: (_) => true,
        failure: (error, _) => false,
      );
      return value;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> verifyChatLockPassword(String password) async {
    try {
      final result = await _apiService.post(
        CommonEndpoints.verifyLockPassword,
        data: {'password': password},
        mapper: (d) => d,
      );
      final value = result.when(
        success: (d) => d is Map ? (d['valid'] == true) : true,
        failure: (error, _) => false,
      );
      return value;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> toggleChatLock(String conversationId, {required bool isLocked, String? password}) async {
    try {
      final data = <String, dynamic>{'isLocked': isLocked};
      if (password != null && password.isNotEmpty) {
        data['password'] = password;
      }
      final result = await _apiService.post(
        CommonEndpoints.lockChat(conversationId),
        data: data,
        mapper: (d) => d,
      );
      final value = result.when(
        success: (_) => true,
        failure: (error, _) => false,
      );
      return value;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<dynamic>> getLockedChats() async {
    try {
      final result = await _apiService.get<List<dynamic>>(
        CommonEndpoints.getLockedChats,
        mapper: (data) => data is List ? data : [],
      );
      final value = result.when(
        success: (data) => data,
        failure: (error, _) => [],
      );
      return value;
    } catch (_) {
      return [];
    }
  }
}


