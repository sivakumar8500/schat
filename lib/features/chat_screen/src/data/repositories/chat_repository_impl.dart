import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_shares_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/theme_color_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_screen/src/domain/models/chat_media_model.dart';
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
      final requestData = {
        'media_type': mediaType,
        'mime_type': mimeType,
        'file_size_bytes': fileSizeBytes,
        'filename': fileName,
        'conversation_id': conversationId,
      };

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

      return completeResult.when(
        success: (_) => objectKey,
        failure: (error, statusCode) => throw Exception('Failed to complete upload: $error'),
      );
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
  Future<void> updateTheme({required String conversationId, String? themeColorId}) async {
    final result = await _apiService.put(
      CommonEndpoints.updateTheme(conversationId),
      data: {'themeColorId': themeColorId},
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
        },
      },
      mapper: (data) => data,
    );
    result.when(
      success: (_) {},
      failure: (error, statusCode) => throw Exception(error),
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
}
