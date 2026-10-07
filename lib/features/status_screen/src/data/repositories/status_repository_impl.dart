import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/utils/common_endpoints.dart';
import '../../domain/repositories/status_repository.dart';
import '../../domain/status_model.dart';

@LazySingleton(as: StatusRepository)
class StatusRepositoryImpl implements StatusRepository {
  final ApiService _apiService;

  StatusRepositoryImpl(this._apiService);

  @override
  Future<List<StatusContactModel>> getRecentUpdates() async {
    try {
      final result = await _apiService.get<List<StatusContactModel>>(
        CommonEndpoints.getRecentStatuses,
        mapper: (data) => _parseStatusesResponse(data),
      );
      final list = result.when(
        success: (data) => data,
        failure: (message, _) => <StatusContactModel>[],
      );
      return list;
    } catch (e) {
      debugPrint('Error fetching recent status updates: $e');
      return [];
    }
  }

  List<StatusContactModel> _parseStatusesResponse(dynamic data) {
    if (data is! List) return [];

    // Case 1: Backend returns contact-grouped list [{ "userId": "...", "displayName": "...", "statuses": [...] }]
    if (data.isNotEmpty && data.first is Map && (data.first as Map).containsKey('statuses')) {
      return data.map((e) => StatusContactModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }

    // Case 2: Backend returns flat status list [{ "id": "...", "userId": "...", "textContent": "...", "user": {...} }]
    final Map<String, List<StatusItemModel>> groupedStatuses = {};
    final Map<String, Map<String, dynamic>> userMeta = {};

    for (final raw in data) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final item = StatusItemModel.fromJson(map);

      final userObj = map['user'] is Map ? Map<String, dynamic>.from(map['user'] as Map) : map;
      final userId = item.userId ?? (userObj['userId'] ?? userObj['id'] ?? userObj['_id'] ?? 'unknown').toString();
      final displayName = (userObj['displayName'] ?? userObj['first_name'] ?? userObj['username'] ?? 'User').toString();
      final username = userObj['username']?.toString();
      final avatar = (userObj['profilePictureUrl'] ?? userObj['profile_picture_url'])?.toString();

      groupedStatuses.putIfAbsent(userId, () => []).add(item);
      if (!userMeta.containsKey(userId)) {
        userMeta[userId] = {
          'userId': userId,
          'displayName': displayName,
          'username': username,
          'profilePictureUrl': avatar,
        };
      }
    }

    return groupedStatuses.entries.map((entry) {
      final meta = userMeta[entry.key] ?? {'userId': entry.key, 'displayName': 'User'};
      return StatusContactModel(
        contactId: entry.key,
        name: meta['displayName']?.toString() ?? 'User',
        username: meta['username']?.toString(),
        profilePictureUrl: meta['profilePictureUrl']?.toString(),
        statuses: entry.value,
      );
    }).toList();
  }


  @override
  Future<List<StatusContactModel>> getViewedUpdates() async {
    // Backend doesn't have a specific endpoint for viewed yet, assuming filtered client side
    return [];
  }

  @override
  Future<List<StatusContactModel>> getMutedUpdates() async {
    // Assume we filter on client side or use future endpoint
    return [];
  }

  @override
  Future<void> muteContact(String contactId, bool mute) async {
    if (mute) {
      await _apiService.post(CommonEndpoints.muteContactStatus(contactId));
    } else {
      await _apiService.post(CommonEndpoints.unmuteContactStatus(contactId));
    }
  }

  @override
  Future<void> createStatus({
    required String statusType,
    String? textContent,
    String? mediaFileId,
    String? textColor,
    String? filePath,
    String? fileName,
    String? mimeType,
    int? fileSizeBytes,
    dynamic fileBytes, // Uint8List
    String? privacyType,
    List<String>? privacyUserIds,
    void Function(double progress)? onProgress,
  }) async {
    String? finalMediaId = mediaFileId;

    // Handle file upload if provided
    if ((filePath != null && filePath.isNotEmpty) || fileBytes != null) {
      try {
        Uint8List? bytes;
        if (fileBytes != null) {
          bytes = fileBytes is Uint8List
              ? fileBytes
              : Uint8List.fromList(List<int>.from(fileBytes as Iterable));
        } else if (filePath != null) {
          final file = File(filePath);
          if (await file.exists()) {
            bytes = await file.readAsBytes();
          }
        }

        if (bytes == null || bytes.isEmpty) {
          throw Exception('Failed to read status media file or empty bytes');
        }

        final size = bytes.length;
        final inferredFileName = fileName ?? (filePath != null ? filePath.split('/').last : (statusType == 'video' ? 'video.mp4' : 'media.jpg'));
        String inferredMime = mimeType ?? (statusType == 'video' ? 'video/mp4' : (statusType == 'audio' ? 'audio/m4a' : 'image/jpeg'));
        final isVideo = statusType == 'video' || inferredMime.toLowerCase().contains('video') || inferredFileName.toLowerCase().endsWith('.mp4') || inferredFileName.toLowerCase().endsWith('.mov');
        final isAudio = statusType == 'audio' || inferredMime.toLowerCase().contains('audio') || inferredFileName.toLowerCase().endsWith('.m4a') || inferredFileName.toLowerCase().endsWith('.mp3');
        final mediaType = isVideo ? 'CHAT_VIDEO' : (isAudio ? 'CHAT_AUDIO' : 'CHAT_IMAGE');

        if (isVideo) {
          inferredMime = 'video/mp4';
        }

        onProgress?.call(0.05);

        // Step 1: Request upload URL with retries
        final requestData = {
          'media_type': mediaType,
          'mime_type': inferredMime,
          'file_size_bytes': size,
          'filename': inferredFileName,
        };

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
            debugPrint('Status upload request attempt $attempt failed: $e');
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

        if (uploadUrl.contains('minio')) {
          try {
            final serverUri = Uri.parse(CommonEndpoints.baseUrl);
            if (serverUri.host.isNotEmpty) {
              uploadUrl = uploadUrl.replaceAll('minio', serverUri.host);
            }
          } catch (_) {}
        }

        if (mediaId.isEmpty || uploadUrl.isEmpty) {
          throw Exception('Invalid metadata received from request-upload');
        }

        onProgress?.call(0.15);

        // Step 2: Upload file binary directly with timeout, retries, and live progress reporting
        bool s3Success = false;
        Exception? lastUploadError;
        final uploadDio = Dio(
          BaseOptions(
            connectTimeout: const Duration(minutes: 2),
            sendTimeout: const Duration(minutes: 10),
            receiveTimeout: const Duration(minutes: 2),
          ),
        );

        for (int uploadAttempt = 1; uploadAttempt <= 3; uploadAttempt++) {
          try {
            final uploadResponse = await uploadDio.put(
              uploadUrl,
              data: Stream.fromIterable(<List<int>>[bytes]),
              options: Options(
                headers: {
                  'Content-Type': inferredMime,
                  'Content-Length': bytes.length.toString(),
                },
              ),
              onSendProgress: (sent, total) {
                if (total > 0 && onProgress != null) {
                  // Map upload progress into 15% -> 90% range
                  final uploadFraction = (sent / total).clamp(0.0, 1.0);
                  final overallProgress = 0.15 + (uploadFraction * 0.75);
                  onProgress(overallProgress);
                }
              },
            );

              if (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 201) {
                s3Success = true;
                onProgress?.call(0.92);
                break;
              } else {
                throw Exception('S3 upload failed with status code: ${uploadResponse.statusCode}');
              }
            } catch (e) {
              lastUploadError = Exception(e.toString());
              debugPrint('Status S3 upload attempt $uploadAttempt failed: $e');
              if (uploadAttempt < 3) {
                await Future.delayed(Duration(milliseconds: 1000 * uploadAttempt));
              }
            }
          }

          if (!s3Success) {
            throw lastUploadError ?? Exception('S3 upload failed after retries');
          }

          // Step 3: Complete upload with retries
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

              final isCompleted = completeResult.when(
                success: (_) => true,
                failure: (error, statusCode) => false,
              );
              if (isCompleted) break;
            } catch (e) {
              debugPrint('Status complete upload attempt $completeAttempt failed: $e');
              if (completeAttempt < 3) {
                await Future.delayed(Duration(milliseconds: 800 * completeAttempt));
              }
            }
          }

          debugPrint('========\nstatus mediaId: $mediaId\n========');
          finalMediaId = mediaId;
          onProgress?.call(0.97);
        } catch (e) {
          debugPrint('Error uploading status media: $e');
          rethrow;
        }
      }

    // Create the actual status
    final createPayload = <String, dynamic>{
      'statusType': statusType,
    };
    if (textContent != null && textContent.trim().isNotEmpty) {
      createPayload['textContent'] = textContent.trim();
    }
    if (finalMediaId != null && finalMediaId.trim().isNotEmpty) {
      createPayload['mediaFileId'] = finalMediaId.trim();
    }
    if (textColor != null && textColor.trim().isNotEmpty) {
      createPayload['textColor'] = textColor.trim();
    }
    if (privacyType != null && privacyType.isNotEmpty) {
      createPayload['privacyType'] = privacyType;
    }
    if (privacyUserIds != null) {
      createPayload['privacyUserIds'] = privacyUserIds;
    }

    final result = await _apiService.post(
      CommonEndpoints.createStatus,
      data: createPayload,
    );
    
    result.when(
      success: (_) {
        onProgress?.call(1.0);
      },
      failure: (error, statusCode) => throw Exception(error),
    );
  }


  @override
  Future<List<StatusItemModel>> getMyStatuses() async {
    final result = await _apiService.get<List<StatusItemModel>>(
      CommonEndpoints.getMyStatuses,
      mapper: (data) {
        if (data is List) {
          return data
              .whereType<Map>()
              .map((e) => StatusItemModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } else if (data is Map && data.containsKey('statuses') && data['statuses'] is List) {
          return (data['statuses'] as List)
              .whereType<Map>()
              .map((e) => StatusItemModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
        return [];
      },
    );
    return result.when(
      success: (data) => data,
      failure: (message, _) => [],
    );
  }

  @override
  Future<void> deleteStatus(String statusId) async {
    await _apiService.delete(CommonEndpoints.deleteStatus(statusId));
  }

  @override
  Future<void> viewStatus(String statusId) async {
    await _apiService.post(CommonEndpoints.viewStatus(statusId));
  }

  @override
  Future<StatusPrivacyModel> getStatusPrivacy() async {
    try {
      final result = await _apiService.get<StatusPrivacyModel>(
        CommonEndpoints.statusPrivacy,
        mapper: (data) => StatusPrivacyModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
      final model = result.when(
        success: (data) => data,
        failure: (error, _) => const StatusPrivacyModel(),
      );
      return model;
    } catch (_) {
      return const StatusPrivacyModel();
    }
  }

  @override
  Future<StatusPrivacyModel> updateStatusPrivacy({
    required String privacyType,
    List<String>? includedUserIds,
    List<String>? excludedUserIds,
  }) async {
    final data = {
      'privacyType': privacyType,
      'includedUserIds': includedUserIds ?? [],
      'excludedUserIds': excludedUserIds ?? [],
    };
    try {
      final result = await _apiService.put<StatusPrivacyModel>(
        CommonEndpoints.statusPrivacy,
        data: data,
        mapper: (data) => StatusPrivacyModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
      final model = result.when(
        success: (data) => data,
        failure: (error, _) => const StatusPrivacyModel(),
      );
      return model;
    } catch (_) {
      return const StatusPrivacyModel();
    }
  }
}


