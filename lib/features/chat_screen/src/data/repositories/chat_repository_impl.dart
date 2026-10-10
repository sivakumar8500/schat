import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
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
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_endpoints.dart';

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  final ApiService _apiService;

  ChatRepositoryImpl(this._apiService);

  @override
  Future<List<MessageModel>> getMessages(String conversationId, {int? limit, int? skip}) async {
    final queryParams = <String, dynamic>{
      'limit': limit ?? 100,
    };
    if (skip != null) {
      queryParams['skip'] = skip;
      queryParams['offset'] = skip;
      if (limit != null && limit > 0) {
        queryParams['page'] = (skip ~/ limit) + 1;
      }
    }
    final result = await _apiService.get<List<MessageModel>>(
      '${CommonEndpoints.getMessages}$conversationId',
      queryParameters: queryParams,
      mapper: (data) {
        if (data is List) {
          return data.map((json) => MessageModel.fromJson(json as Map<String, dynamic>)).toList();
        } else if (data is Map) {
          final list = (data['messages'] ?? data['data'] ?? data['results'] ?? data['items'] ?? data['list']) as List? ?? [];
          return list.map((json) => MessageModel.fromJson(json as Map<String, dynamic>)).toList();
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
  Future<List<MessageModel>> searchMessagesInChat(String conversationId, String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      // 1. Try endpoint /messages/search/$conversationId?q=query
      final result = await _apiService.get<List<MessageModel>>(
        CommonEndpoints.searchMessagesInChat(conversationId),
        queryParameters: {'q': cleanQuery, 'query': cleanQuery},
        mapper: (data) {
          if (data is List) {
            return data.map((json) => MessageModel.fromJson(json as Map<String, dynamic>)).toList();
          } else if (data is Map && (data['messages'] is List || data['data'] is List || data['results'] is List)) {
            final list = (data['messages'] ?? data['data'] ?? data['results']) as List;
            return list.map((json) => MessageModel.fromJson(json as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );

      List<MessageModel> messages = [];
      result.when(
        success: (data) => messages = data,
        failure: (_, _) {},
      );

      if (messages.isNotEmpty) return messages;

      // 2. Fallback to /messages/search?conversation_id=$conversationId&q=$query
      final fallbackResult = await _apiService.get<List<MessageModel>>(
        CommonEndpoints.searchMessages,
        queryParameters: {'conversation_id': conversationId, 'q': cleanQuery, 'query': cleanQuery},
        mapper: (data) {
          if (data is List) {
            return data.map((json) => MessageModel.fromJson(json as Map<String, dynamic>)).toList();
          } else if (data is Map && (data['messages'] is List || data['data'] is List || data['results'] is List)) {
            final list = (data['messages'] ?? data['data'] ?? data['results']) as List;
            return list.map((json) => MessageModel.fromJson(json as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );

      fallbackResult.when(
        success: (data) => messages = data,
        failure: (_, _) {},
      );

      if (messages.isNotEmpty) return messages;

      // 3. Fallback to /search?q=$query&conversation_id=$conversationId
      final globalResult = await _apiService.get<List<MessageModel>>(
        CommonEndpoints.searchGlobal,
        queryParameters: {'q': cleanQuery, 'conversation_id': conversationId, 'filter': 'all', 'limit': 50},
        mapper: (data) {
          if (data is Map && data['messages'] is List) {
            final msgs = data['messages'] as List;
            return msgs.map((json) => MessageModel.fromJson(json as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );

      globalResult.when(
        success: (data) => messages = data,
        failure: (_, _) {},
      );

      return messages;
    } catch (_) {
      return [];
    }
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
    void Function(double progress)? onProgress,
  }) async {
    try {
      if (!kIsWeb) {
        await WakelockPlus.enable();
      }
    } catch (_) {}

    try {
      onProgress?.call(0.05);
      String resolvedMime = mimeType;
      final ext = fileName.split('.').last.toLowerCase();
      if (mediaType == 'CHAT_VIDEO' && (resolvedMime.isEmpty || resolvedMime == 'application/octet-stream')) {
        switch (ext) {
          case 'mov':
            resolvedMime = 'video/quicktime';
            break;
          case 'webm':
            resolvedMime = 'video/webm';
            break;
          case 'avi':
            resolvedMime = 'video/x-msvideo';
            break;
          case 'mkv':
            resolvedMime = 'video/x-matroska';
            break;
          default:
            resolvedMime = 'video/mp4';
        }
      } else if (mediaType == 'CHAT_IMAGE' && (resolvedMime.isEmpty || resolvedMime == 'application/octet-stream')) {
        switch (ext) {
          case 'png':
            resolvedMime = 'image/png';
            break;
          case 'webp':
            resolvedMime = 'image/webp';
            break;
          case 'gif':
            resolvedMime = 'image/gif';
            break;
          default:
            resolvedMime = 'image/jpeg';
        }
      } else if ((mediaType == 'VOICE_NOTE' || mediaType == 'CHAT_AUDIO') && (resolvedMime.isEmpty || resolvedMime == 'application/octet-stream')) {
        switch (ext) {
          case 'wav':
            resolvedMime = 'audio/wav';
            break;
          case 'm4a':
            resolvedMime = 'audio/mp4';
            break;
          case 'aac':
            resolvedMime = 'audio/aac';
            break;
          case 'ogg':
            resolvedMime = 'audio/ogg';
            break;
          default:
            resolvedMime = 'audio/mpeg';
        }
      } else if (mediaType == 'DOCUMENT') {
        switch (ext) {
          case 'pdf':
            resolvedMime = 'application/pdf';
            break;
          case 'doc':
            resolvedMime = 'application/msword';
            break;
          case 'docx':
            resolvedMime = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
            break;
          case 'xls':
            resolvedMime = 'application/vnd.ms-excel';
            break;
          case 'xlsx':
            resolvedMime = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
            break;
          case 'ppt':
            resolvedMime = 'application/vnd.ms-powerpoint';
            break;
          case 'pptx':
            resolvedMime = 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
            break;
          case 'zip':
            resolvedMime = 'application/zip';
            break;
          default:
            resolvedMime = 'application/pdf';
        }
      }

      final requestData = <String, dynamic>{
        'media_type': mediaType,
        'mime_type': resolvedMime,
        'file_size_bytes': fileSizeBytes,
        'filename': fileName,
      };
      if (conversationId.isNotEmpty) {
        requestData['conversation_id'] = conversationId;
      }

      // 1. Request upload metadata with retries
      Map<String, dynamic>? uploadMeta;
      Exception? lastRequestError;

      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          final requestResult = await _apiService.call<Map<String, dynamic>>(
            path: CommonEndpoints.requestUpload,
            method: 'POST',
            data: requestData,
            options: Options(
              sendTimeout: const Duration(minutes: 2),
              receiveTimeout: const Duration(minutes: 2),
            ),
            mapper: (data) => Map<String, dynamic>.from(data as Map),
          );

          uploadMeta = requestResult.when(
            success: (data) => data,
            failure: (error, statusCode) => throw Exception('Failed to request upload URL: $error'),
          );
          if (uploadMeta != null) break;
        } catch (e) {
          lastRequestError = Exception(e.toString());
          debugPrint('Upload request attempt $attempt failed: $e');
          final errStr = e.toString();
          if (errStr.contains('Invalid document MIME type') ||
              errStr.contains('Invalid video MIME type') ||
              errStr.contains('Invalid audio MIME type') ||
              errStr.contains('Invalid image MIME type') ||
              errStr.contains('MIME type')) {
            if (mediaType == 'DOCUMENT') {
              if (attempt == 1) {
                requestData['mime_type'] = 'application/pdf';
              } else if (attempt == 2) {
                requestData['mime_type'] = 'application/octet-stream';
              }
            } else if (mediaType == 'CHAT_VIDEO') {
              requestData['mime_type'] = 'video/mp4';
            } else if (mediaType == 'CHAT_IMAGE') {
              requestData['mime_type'] = 'image/jpeg';
            } else if (mediaType == 'VOICE_NOTE' || mediaType == 'CHAT_AUDIO') {
              requestData['mime_type'] = 'audio/mpeg';
            }
          }
          if (attempt < 3) {
            await Future.delayed(Duration(milliseconds: 500 * attempt));
          }
        }
      }

      if (uploadMeta == null) {
        throw lastRequestError ?? Exception('Failed to request upload URL after retries');
      }

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

      // 2. Perform direct S3/MinIO upload with retry
      Uint8List bytes;
      if (fileBytes != null && fileBytes.isNotEmpty) {
        bytes = fileBytes;
      } else if (!kIsWeb && filePath.isNotEmpty) {
        final file = File(filePath);
        if (!await file.exists()) throw Exception('File does not exist at path: $filePath');
        bytes = await file.readAsBytes();
      } else {
        throw Exception('No file data available for upload');
      }

      if (uploadUrl.contains('minio') || uploadUrl.contains('localhost') || uploadUrl.contains('127.0.0.1')) {
        try {
          final serverUri = Uri.parse(CommonEndpoints.baseUrl);
          final host = serverUri.host;
          if (host.isNotEmpty) {
            final parsedUpload = Uri.parse(uploadUrl);
            if (parsedUpload.host == 'minio' || parsedUpload.host == 'localhost' || parsedUpload.host == '127.0.0.1') {
              uploadUrl = parsedUpload.replace(host: host).toString();
            } else if (uploadUrl.contains('minio')) {
              uploadUrl = uploadUrl.replaceAll('minio', host);
            }
          }
        } catch (_) {}
      }

      final finalUploadMime = requestData['mime_type']?.toString() ?? resolvedMime;
      Exception? lastUploadError;
      bool s3Success = false;

      final uploadDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      for (int uploadAttempt = 1; uploadAttempt <= 3; uploadAttempt++) {
        try {
          final uploadResponse = await uploadDio.put(
            uploadUrl,
            data: Stream.fromIterable(<List<int>>[bytes]),
            options: Options(
              headers: {
                'Content-Type': finalUploadMime,
                'Content-Length': bytes.length.toString(),
              },
            ),
            onSendProgress: (sent, total) {
              if (total > 0 && onProgress != null) {
                // Map upload progress into 5% -> 90% range
                final uploadFraction = (sent / total).clamp(0.0, 1.0);
                final overallProgress = 0.05 + (uploadFraction * 0.85);
                onProgress(overallProgress);
              }
            },
          );

          if (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 204 || uploadResponse.statusCode == 201) {
            s3Success = true;
            onProgress?.call(0.92);
            break;
          } else {
            throw Exception('S3 upload failed with status code: ${uploadResponse.statusCode}');
          }
        } catch (e) {
          lastUploadError = Exception(e.toString());
          debugPrint('S3 upload attempt $uploadAttempt failed: $e');
          if (uploadAttempt < 3) {
            await Future.delayed(Duration(milliseconds: 1000 * uploadAttempt));
          }
        }
      }

      if (!s3Success) {
        throw lastUploadError ?? Exception('S3 upload failed after retries');
      }

      // 3. Complete upload with retries
      String? completedObjectKey;
      Exception? lastCompleteError;

      for (int completeAttempt = 1; completeAttempt <= 3; completeAttempt++) {
        try {
          final completeResult = await _apiService.call<Map<String, dynamic>>(
            path: CommonEndpoints.completeUpload(mediaId),
            method: 'POST',
            data: {'sha256_checksum': null},
            options: Options(
              sendTimeout: const Duration(minutes: 2),
              receiveTimeout: const Duration(minutes: 2),
            ),
            mapper: (data) => Map<String, dynamic>.from(data as Map),
          );

          completedObjectKey = completeResult.when(
            success: (_) {
              debugPrint('========\nmediaid: $mediaId completed\n========');
              onProgress?.call(1.0);
              return objectKey;
            },
            failure: (error, statusCode) => throw Exception('Failed to complete upload: $error'),
          );
          if (completedObjectKey != null) break;
        } catch (e) {
          lastCompleteError = Exception(e.toString());
          debugPrint('Complete upload attempt $completeAttempt failed: $e');
          if (completeAttempt < 3) {
            await Future.delayed(Duration(milliseconds: 1000 * completeAttempt));
          }
        }
      }

      if (completedObjectKey == null) {
        throw lastCompleteError ?? Exception('Failed to complete upload after retries');
      }

      return completedObjectKey;
    } catch (e) {
      debugPrint('Error in uploadMedia: $e');
      rethrow;
    } finally {
      try {
        if (!kIsWeb) {
          await WakelockPlus.disable();
        }
      } catch (_) {}
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
          'is_locked': isLocked,
          'accessUsers': accessUsers,
          'access_users': accessUsers,
          'allowDownload': allowDownload,
          'allow_download': allowDownload,
          'allowShare': allowShare,
          'allow_share': allowShare,
          'allowView': allowView,
          'allow_view': allowView,
          'canView': allowView,
          'can_view': allowView,
        },
        'allowView': allowView,
        'allow_view': allowView,
        'allowDownload': allowDownload,
        'allow_download': allowDownload,
        'allowShare': allowShare,
        'allow_share': allowShare,
        'isLocked': isLocked,
        'is_locked': isLocked,
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
  Future<void> reactToMessage({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) async {
    final myId = getIt<StorageService>().getUserId() ?? '';
    final result = await _apiService.post(
      CommonEndpoints.reactToMessage(messageId),
      data: {
        'conversationId': conversationId,
        'conversation_id': conversationId,
        'messageId': messageId,
        'message_id': messageId,
        'emoji': emoji,
        'reaction': emoji,
        'userId': myId,
        'user_id': myId,
      },
      mapper: (data) => data,
    );
    result.when(
      success: (_) {},
      failure: (error, statusCode) => debugPrint('reactToMessage error: $error'),
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
  Future<List<ScreenPermissionModel>> getActiveScreenPermissions(String conversationId) async {
    final result = await _apiService.get<List<ScreenPermissionModel>>(
      CommonEndpoints.screenPermissionActive(conversationId),
      mapper: (data) {
        if (data is List) {
          return data
              .map((e) => ScreenPermissionModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .where((p) => !p.isCompleted && !p.isRejected && ((p.remainingCount ?? p.allowedCount ?? 1) > 0 || (p.isScreenRecord && p.durationSeconds != null)))
              .toList();
        } else if (data is Map) {
          if (data['permissions'] is List) {
            return (data['permissions'] as List)
                .map((e) => ScreenPermissionModel.fromJson(Map<String, dynamic>.from(e as Map)))
                .where((p) => !p.isCompleted && !p.isRejected && ((p.remainingCount ?? p.allowedCount ?? 1) > 0 || (p.isScreenRecord && p.durationSeconds != null)))
                .toList();
          }
          if (data['data'] is List) {
            return (data['data'] as List)
                .map((e) => ScreenPermissionModel.fromJson(Map<String, dynamic>.from(e as Map)))
                .where((p) => !p.isCompleted && !p.isRejected && ((p.remainingCount ?? p.allowedCount ?? 1) > 0 || (p.isScreenRecord && p.durationSeconds != null)))
                .toList();
          }
          final model = ScreenPermissionModel.fromJson(Map<String, dynamic>.from(data));
          if (!model.isCompleted && !model.isRejected && ((model.remainingCount ?? model.allowedCount ?? 1) > 0 || (model.isScreenRecord && model.durationSeconds != null))) {
            return [model];
          }
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
    final list = await getActiveScreenPermissions(conversationId);
    return list.isNotEmpty ? list.first : null;
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

  @override
  Future<bool> reportConversation({
    required String conversationId,
    required String reportedUserId,
    String? reportedUserName,
    String? reason,
    String? description,
    List<Map<String, dynamic>>? recentMessages,
    bool blockUser = false,
  }) async {
    final reporterId = getIt<StorageService>().getUserId() ?? '';
    final reporterName = getIt<StorageService>().getUsername() ?? '';

    final payload = <String, dynamic>{
      'conversation_id': conversationId,
      'reported_user_id': reportedUserId,
      'reported_user_name': reportedUserName ?? '',
      'reporter_id': reporterId,
      'reporter_name': reporterName,
      'reason': reason ?? 'Spam / Abuse',
      'description': description ?? '',
      'recent_messages': recentMessages ?? [],
      'messages_count': (recentMessages ?? []).length,
      'block_user': blockUser,
      'reported_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      // First attempt: /users/report endpoint
      final result = await _apiService.call<Map<String, dynamic>>(
        path: CommonEndpoints.reportUser,
        method: 'POST',
        data: payload,
      );

      final success = await result.when(
        success: (_) async => true,
        failure: (error, statusCode) async {
          // Fallback: /chats/tickets endpoint to ensure report is recorded in db
          try {
            final ticketRes = await _apiService.call(
              path: CommonEndpoints.createTicket,
              method: 'POST',
              data: {
                'subject': 'Report: ${reportedUserName ?? reportedUserId} ($reason)',
                'description': 'User $reporterName ($reporterId) reported $reportedUserName ($reportedUserId).\nReason: $reason\nDetails: $description\nLast Messages: ${recentMessages?.length ?? 0}',
                'category': 'REPORT',
                'priority': 'HIGH',
                'metadata': payload,
              },
            );
            return ticketRes.when(
              success: (_) => true,
              failure: (_, _) => true, // Still marked done client side
            );
          } catch (_) {
            return true;
          }
        },
      );
      return success;
    } catch (e) {
      debugPrint('ChatRepositoryImpl: reportConversation error: $e');
      return true;
    }
  }
}


