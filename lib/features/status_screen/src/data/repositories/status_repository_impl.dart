import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

    final pathLower = (filePath ?? '').toLowerCase();
    final nameLower = (fileName ?? '').toLowerCase();
    final mimeLower = (mimeType ?? '').toLowerCase();
    final isAudio = statusType == 'audio' ||
        statusType == 'voice' ||
        mimeLower.contains('audio') ||
        pathLower.endsWith('.m4a') ||
        pathLower.endsWith('.mp3') ||
        pathLower.endsWith('.aac') ||
        pathLower.endsWith('.wav') ||
        pathLower.endsWith('.ogg') ||
        nameLower.endsWith('.m4a') ||
        nameLower.endsWith('.mp3') ||
        nameLower.endsWith('.aac') ||
        nameLower.endsWith('.wav') ||
        nameLower.endsWith('.ogg');
    final isVideo = !isAudio &&
        (statusType == 'video' ||
            mimeLower.contains('video') ||
            pathLower.endsWith('.mp4') ||
            pathLower.endsWith('.mov') ||
            pathLower.endsWith('.webm') ||
            pathLower.endsWith('.avi') ||
            pathLower.endsWith('.mkv') ||
            nameLower.endsWith('.mp4') ||
            nameLower.endsWith('.mov') ||
            nameLower.endsWith('.webm') ||
            nameLower.endsWith('.avi') ||
            nameLower.endsWith('.mkv'));

    // Handle file upload if provided
    if ((filePath != null && filePath.isNotEmpty) || fileBytes != null) {
      try {
        Uint8List? bytes;
        int uploadContentLength = fileSizeBytes ?? 0;
        File? uploadLocalFile;

        if (fileBytes != null) {
          bytes = fileBytes is Uint8List
              ? fileBytes
              : Uint8List.fromList(List<int>.from(fileBytes as Iterable));
          uploadContentLength = bytes.length;
        } else if (filePath != null) {
          final file = File(filePath);
          if (await file.exists()) {
            uploadLocalFile = file;
            uploadContentLength = await file.length();
            if (uploadContentLength <= 25 * 1024 * 1024) {
              bytes = await file.readAsBytes();
            }
          }
        }

        if (uploadContentLength <= 0 && (bytes == null || bytes.isEmpty)) {
          throw Exception('Failed to read status media file or empty bytes');
        }

        final ext = (fileName != null && fileName.contains('.'))
            ? fileName.split('.').last.toLowerCase()
            : (filePath != null && filePath.contains('.')
                ? filePath.split('.').last.toLowerCase()
                : (isVideo ? 'mp4' : (isAudio ? 'm4a' : 'jpg')));

        final inferredFileName = fileName ??
            (filePath != null
                ? filePath.split('/').last
                : (isVideo
                    ? 'video.$ext'
                    : (isAudio ? 'voice_status.$ext' : 'media.$ext')));

        String inferredMime = mimeType ?? '';
        if (isVideo) {
          if (ext == 'mov' || ext == 'quicktime') {
            inferredMime = 'video/quicktime';
          } else if (ext == 'webm') {
            inferredMime = 'video/webm';
          } else {
            inferredMime = 'video/mp4';
          }
        } else if (isAudio) {
          if (ext == 'wav') {
            inferredMime = 'audio/wav';
          } else if (ext == 'aac') {
            inferredMime = 'audio/aac';
          } else if (ext == 'ogg') {
            inferredMime = 'audio/ogg';
          } else if (ext == 'mp3') {
            inferredMime = 'audio/mpeg';
          } else {
            inferredMime = 'audio/mp4';
          }
        } else {
          if (ext == 'png') {
            inferredMime = 'image/png';
          } else if (ext == 'webp') {
            inferredMime = 'image/webp';
          } else if (ext == 'gif') {
            inferredMime = 'image/gif';
          } else {
            inferredMime = 'image/jpeg';
          }
        }

        final mediaType =
            isVideo ? 'CHAT_VIDEO' : (isAudio ? 'VOICE_NOTE' : 'CHAT_IMAGE');

        onProgress?.call(0.05);

        // Helper for direct multipart upload fallback
        Future<String?> performDirectMultipartUpload() async {
          try {
            MultipartFile multipartFile;
            if (bytes != null && bytes.isNotEmpty) {
              multipartFile = MultipartFile.fromBytes(
                bytes,
                filename: inferredFileName,
              );
            } else if (!kIsWeb && filePath != null && File(filePath).existsSync()) {
              multipartFile = await MultipartFile.fromFile(
                filePath,
                filename: inferredFileName,
              );
            } else {
              return null;
            }

            final formDataMap = <String, dynamic>{
              'file': multipartFile,
              'media_type': mediaType,
            };
            final formData = FormData.fromMap(formDataMap);

            final directResult = await _apiService.call<Map<String, dynamic>>(
              path: CommonEndpoints.directUpload,
              method: 'POST',
              data: formData,
              options: Options(
                sendTimeout: const Duration(minutes: 5),
                receiveTimeout: const Duration(minutes: 5),
              ),
              mapper: (data) => Map<String, dynamic>.from(data as Map),
            );

            final directId = directResult.when(
              success: (data) {
                final directMediaId = data['id']?.toString() ?? '';
                onProgress?.call(0.95);
                debugPrint('Status direct upload succeeded -> mediaId: $directMediaId');
                return directMediaId.isNotEmpty ? directMediaId : null;
              },
              failure: (error, statusCode) {
                debugPrint('Status direct upload failed: $error (status $statusCode)');
                return null;
              },
            );
            return directId;
          } catch (e) {
            debugPrint('Status direct upload exception: $e');
            return null;
          }
        }

        // Step 1: Request upload URL with retries
        final requestData = {
          'media_type': mediaType,
          'mime_type': inferredMime,
          'file_size_bytes': uploadContentLength,
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
            final errStr = e.toString();
            if (errStr.contains('Invalid video MIME type') || errStr.contains('MIME type')) {
              if (isVideo) {
                requestData['mime_type'] = 'video/mp4';
              } else if (isAudio) {
                requestData['mime_type'] = 'audio/mp4';
              } else {
                requestData['mime_type'] = 'image/jpeg';
              }
            }
            if (attempt < 3) {
              await Future.delayed(Duration(milliseconds: 500 * attempt));
            }
          }
        }

        if (uploadMeta == null) {
          final fallbackMediaId = await performDirectMultipartUpload();
          if (fallbackMediaId != null) {
            finalMediaId = fallbackMediaId;
          } else {
            throw lastRequestError ?? Exception('Failed to request upload URL after retries');
          }
        } else {
          final mediaId = uploadMeta['media_id']?.toString() ?? '';
          String uploadUrl = uploadMeta['upload_url']?.toString() ?? '';

          if (uploadUrl.startsWith('/') || uploadUrl.contains('/media/upload')) {
            // Backend returned fallback endpoint
            final fallbackMediaId = await performDirectMultipartUpload();
            if (fallbackMediaId != null) {
              finalMediaId = fallbackMediaId;
            } else {
              throw Exception('Direct fallback upload failed for status media');
            }
          } else {
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

            if (mediaId.isEmpty || uploadUrl.isEmpty) {
              throw Exception('Invalid metadata received from request-upload');
            }

            onProgress?.call(0.15);

            // Step 2: Upload file binary directly with timeout, retries, and live progress reporting
            bool s3Success = false;
            Exception? lastUploadError;
            final uploadDio = Dio(
              BaseOptions(
                connectTimeout: const Duration(minutes: 5),
                sendTimeout: const Duration(minutes: 15),
                receiveTimeout: const Duration(minutes: 5),
              ),
            );

            for (int uploadAttempt = 1; uploadAttempt <= 3; uploadAttempt++) {
              try {
                final Stream<List<int>> uploadStream = bytes != null
                    ? Stream.fromIterable(<List<int>>[bytes])
                    : uploadLocalFile!.openRead();

                final uploadResponse = await uploadDio.put(
                  uploadUrl,
                  data: uploadStream,
                  options: Options(
                    headers: {
                      'Content-Type': requestData['mime_type']?.toString() ?? inferredMime,
                      'Content-Length': uploadContentLength.toString(),
                    },
                  ),
                  onSendProgress: (sent, total) {
                    if (total > 0 && onProgress != null) {
                      final uploadFraction = (sent / total).clamp(0.0, 1.0);
                      final overallProgress = 0.15 + (uploadFraction * 0.75);
                      onProgress(overallProgress);
                    }
                  },
                );

                if (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 201 || uploadResponse.statusCode == 204) {
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
              final fallbackMediaId = await performDirectMultipartUpload();
              if (fallbackMediaId != null) {
                finalMediaId = fallbackMediaId;
              } else {
                throw lastUploadError ?? Exception('S3 upload failed after retries');
              }
            } else {
              // Step 3: Complete upload with retries
              bool completedOk = false;
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

                  completedOk = completeResult.when(
                    success: (_) => true,
                    failure: (error, statusCode) => false,
                  );
                  if (completedOk) break;
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
            }
          }
        }
      } catch (e) {
        debugPrint('Error uploading status media: $e');
        rethrow;
      }
    }

    // Create the actual status
    final createPayload = <String, dynamic>{
      'statusType': statusType,
      'status_type': statusType,
    };
    if (textContent != null && textContent.trim().isNotEmpty) {
      createPayload['textContent'] = textContent.trim();
      createPayload['text_content'] = textContent.trim();
      createPayload['text'] = textContent.trim();
    }
    if (finalMediaId != null && finalMediaId.trim().isNotEmpty) {
      createPayload['mediaFileId'] = finalMediaId.trim();
      createPayload['media_file_id'] = finalMediaId.trim();
      createPayload['mediaId'] = finalMediaId.trim();
      createPayload['media_id'] = finalMediaId.trim();
    }
    if (textColor != null && textColor.trim().isNotEmpty) {
      createPayload['textColor'] = textColor.trim();
      createPayload['text_color'] = textColor.trim();
    }
    if (privacyType != null && privacyType.isNotEmpty) {
      createPayload['privacyType'] = privacyType;
      createPayload['privacy_type'] = privacyType;
    }
    if (privacyUserIds != null && privacyUserIds.isNotEmpty) {
      final sanitizedUids = privacyUserIds
          .where((id) => id.trim().isNotEmpty && RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(id.trim()))
          .map((id) => id.trim())
          .toList();
      if (sanitizedUids.isNotEmpty) {
        createPayload['privacyUserIds'] = sanitizedUids;
        createPayload['privacy_user_ids'] = sanitizedUids;
        createPayload['includedUserIds'] = sanitizedUids;
        createPayload['included_user_ids'] = sanitizedUids;
        createPayload['excludedUserIds'] = sanitizedUids;
        createPayload['excluded_user_ids'] = sanitizedUids;
        createPayload['contactIds'] = sanitizedUids;
        createPayload['contact_ids'] = sanitizedUids;
      }
    }

    var result = await _apiService.post(
      CommonEndpoints.createStatus,
      data: createPayload,
    );

    // If server does not accept 'audio' as status_type, retry gracefully with 'video'
    if (isAudio) {
      bool needFallback = false;
      result.when(
        success: (_) {},
        failure: (error, statusCode) {
          if (statusCode == 400 || error.contains('Invalid status type')) {
            needFallback = true;
          }
        },
      );
      if (needFallback) {
        final fallbackPayload = Map<String, dynamic>.from(createPayload);
        fallbackPayload['statusType'] = 'video';
        fallbackPayload['status_type'] = 'video';
        result = await _apiService.post(
          CommonEndpoints.createStatus,
          data: fallbackPayload,
        );
      }
    }
    
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
    final incList = includedUserIds ?? [];
    final excList = excludedUserIds ?? [];
    final activeIds = (privacyType == 'only' || privacyType == 'include' || privacyType == 'only_share_with')
        ? incList
        : excList;

    final data = {
      'privacyType': privacyType,
      'privacy_type': privacyType,
      'includedUserIds': incList,
      'included_user_ids': incList,
      'excludedUserIds': excList,
      'excluded_user_ids': excList,
      'privacyUserIds': activeIds,
      'privacy_user_ids': activeIds,
      'contactIds': activeIds,
      'contact_ids': activeIds,
    };
    try {
      final result = await _apiService.put<StatusPrivacyModel>(
        CommonEndpoints.statusPrivacy,
        data: data,
        mapper: (data) => StatusPrivacyModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
      final model = result.when(
        success: (data) => data,
        failure: (error, _) => StatusPrivacyModel(
          privacyType: privacyType,
          includedUserIds: incList,
          excludedUserIds: excList,
        ),
      );
      return model;
    } catch (_) {
      return StatusPrivacyModel(
        privacyType: privacyType,
        includedUserIds: incList,
        excludedUserIds: excList,
      );
    }
  }
}


