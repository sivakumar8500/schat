import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/features/profile_screen/src/domain/models/update_profile_request.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/utils/common_endpoints.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  final ApiService _apiService;
  final StorageService _storageService;

  ProfileRepositoryImpl(this._apiService, this._storageService);

  @override
  Future<ApiResult<UserModel>> getProfile() async {
    final result = await _apiService.get<UserModel>(
      CommonEndpoints.profileMe,
      mapper: (json) => UserModel.fromJson(json),
    );

    return result.when(
      success: (user) {
        _storageService.saveUserId(user.id);
        _storageService.saveUsername(user.username);
        _storageService.saveProfilePic(user.profilePictureUrl);
        return ApiResult.success(user);
      },
      failure: (message, statusCode) => ApiResult.failure(message, statusCode: statusCode),
    );
  }

  @override
  Future<ApiResult<UserModel>> updateProfile(UpdateProfileRequest request) async {
    final Map<String, dynamic> data = request.toJson();
    // Remove null values to prevent server-side errors on PATCH
    data.removeWhere((key, value) => value == null);

    final result = await _apiService.patch<UserModel>(
      CommonEndpoints.updateProfile,
      data: data,
      mapper: (json) => UserModel.fromJson(json),
    );

    return result.when(
      success: (user) {
        _storageService.saveUserId(user.id);
        _storageService.saveUsername(user.username);
        _storageService.saveProfilePic(user.profilePictureUrl);
        return ApiResult.success(user);
      },
      failure: (message, statusCode) => ApiResult.failure(message, statusCode: statusCode),
    );
  }

  @override
  Future<String?> uploadProfilePicture({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
    Uint8List? fileBytes,
  }) async {
    try {
      // Step 1: Request upload URL
      final requestData = {
        'media_type': 'CHAT_IMAGE',
        'mime_type': mimeType,
        'file_size_bytes': fileSizeBytes,
        'filename': fileName,
        'conversation_id': _storageService.getUserId() ?? '', // Using user ID as conversation_id for profile pic
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

      // Step 2: Upload file binary directly to S3 via PUT
      Uint8List bytes;
      if (kIsWeb) {
        if (fileBytes == null) {
          throw Exception('File bytes must not be null for web uploads');
        }
        bytes = fileBytes;
      } else {
        if (fileBytes != null) {
          bytes = fileBytes;
        } else {
          final file = File(filePath);
          if (!await file.exists()) {
            throw Exception('File does not exist at path: $filePath');
          }
          bytes = await file.readAsBytes();
        }
      }

      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        body: bytes,
        headers: {
          'Content-Type': mimeType,
        },
      );

      if (uploadResponse.statusCode != 200) {
        throw Exception('S3 upload failed with status code: ${uploadResponse.statusCode}');
      }

      // Step 3: Complete upload
      final completeResult = await _apiService.post<Map<String, dynamic>>(
        CommonEndpoints.completeUpload(mediaId),
        data: {
          'sha256_checksum': null,
        },
        mapper: (data) => Map<String, dynamic>.from(data as Map),
      );

      return completeResult.when(
        success: (_) => objectKey,
        failure: (error, statusCode) => throw Exception('Failed to complete upload: $error'),
      );
    } catch (e) {
      debugPrint('Error in uploadProfilePicture: $e');
      rethrow;
    }
  }
}
