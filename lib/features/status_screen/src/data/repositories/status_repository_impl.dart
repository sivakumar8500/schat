import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
        mapper: (data) => (data as List).map((e) => StatusContactModel.fromJson(e)).toList(),
      );
      final list = result.when(
        success: (data) => data,
        failure: (message, _) => <StatusContactModel>[],
      );
      return list;
    } catch (e) {
      // Fallback for testing UI if API is not fully ready
      return [];
    }
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
    String? filePath,
    String? fileName,
    String? mimeType,
    int? fileSizeBytes,
    dynamic fileBytes, // Uint8List
    String? privacyType,
    List<String>? privacyUserIds,
  }) async {
    String? finalMediaId = mediaFileId;

    // Handle file upload if provided
    if (fileName != null && mimeType != null) {
      try {
        dynamic bytes = fileBytes;
        if (bytes == null && filePath != null) {
          final file = File(filePath);
          if (await file.exists()) {
            bytes = await file.readAsBytes();
          }
        }

        final size = bytes != null ? (bytes as Uint8List).length : (fileSizeBytes ?? 1024);
        final isVideo = mimeType.toLowerCase().contains('video') || (fileName.endsWith('.mp4'));
        final mediaType = isVideo ? 'CHAT_VIDEO' : 'CHAT_IMAGE';

        // Step 1: Request upload URL
        final requestData = {
          'media_type': mediaType,
          'mime_type': mimeType,
          'file_size_bytes': size,
          'filename': fileName,
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

        // Step 2: Upload file binary directly
        if (bytes != null) {
          final uploadResponse = await http.put(
            Uri.parse(uploadUrl),
            body: bytes,
            headers: {'Content-Type': mimeType},
          );

          if (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 201) {
            // Step 3: Complete upload
            await _apiService.post<Map<String, dynamic>>(
              CommonEndpoints.completeUpload(mediaId),
              data: {'sha256_checksum': null},
              mapper: (data) => Map<String, dynamic>.from(data as Map),
            );
            finalMediaId = mediaId;
          } else {
            throw Exception('Upload failed with status code: ${uploadResponse.statusCode}');
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
    };
    if (textContent != null && textContent.trim().isNotEmpty) {
      createPayload['textContent'] = textContent.trim();
    }
    if (finalMediaId != null && finalMediaId.trim().isNotEmpty) {
      createPayload['mediaFileId'] = finalMediaId.trim();
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
      success: (_) {},
      failure: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<List<StatusItemModel>> getMyStatuses() async {
    final result = await _apiService.get<List<StatusItemModel>>(
      CommonEndpoints.getMyStatuses,
      mapper: (data) => (data as List).map((e) => StatusItemModel.fromJson(e)).toList(),
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
}
