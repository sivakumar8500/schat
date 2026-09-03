import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/features/profile_screen/src/domain/models/update_profile_request.dart';
import 'package:schat/features/profile_screen/src/domain/models/blocked_group_model.dart';
import 'package:schat/features/profile_screen/src/domain/models/phone_lookup_response.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/utils/common_endpoints.dart';
import 'package:schat/features/profile_screen/src/data/models/add_emergency_contact_request.dart';
import 'package:schat/features/profile_screen/src/data/models/emergency_contact_response.dart';
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
    data.removeWhere((key, value) => value == null && key != 'defaultDisappearingTimer');

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
  Future<ApiResult<UserModel>> getUserById(String userId) async {
    return _apiService.get<UserModel>(
      CommonEndpoints.getUserProfile(userId),
      mapper: (json) => UserModel.fromJson(json),
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

      String resolvedUrl = completeResult.when(
        success: (data) => data['url']?.toString() ?? data['file_url']?.toString() ?? '',
        failure: (error, statusCode) => throw Exception('Failed to complete upload: $error'),
      );

      if (resolvedUrl.isEmpty) {
        try {
          final serverUri = Uri.parse(CommonEndpoints.baseUrl);
          final portSuffix = serverUri.hasPort ? ':${serverUri.port}' : '';
          resolvedUrl = '${serverUri.scheme}://${serverUri.host}$portSuffix/$objectKey';
        } catch (_) {
          resolvedUrl = objectKey;
        }
      }
      return resolvedUrl;
    } catch (e) {
      debugPrint('Error in uploadProfilePicture: $e');
      rethrow;
    }
  }

  @override
  Future<ApiResult<void>> blockUser(String userId) async {
    return _apiService.post<void>(
      CommonEndpoints.blockUser(userId),
      mapper: (_) {},
    );
  }

  @override
  Future<ApiResult<void>> unblockUser(String userId) async {
    return _apiService.post<void>(
      CommonEndpoints.unblockUser(userId),
      mapper: (_) {},
    );
  }

  @override
  Future<ApiResult<List<UserModel>>> getBlockedUsers() async {
    return _apiService.get<List<UserModel>>(
      CommonEndpoints.getBlockedUsers,
      mapper: (json) {
        if (json is List) {
          return json.map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResult<List<BlockedGroupModel>>> getBlockedGroups() async {
    return _apiService.get<List<BlockedGroupModel>>(
      CommonEndpoints.getBlockedGroups,
      mapper: (json) {
        if (json is List) {
          return json.map((e) => BlockedGroupModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResult<PhoneLookupResponse>> lookupByPhoneNumber(String phoneNumber) async {
    return _apiService.get<PhoneLookupResponse>(
      CommonEndpoints.lookupUser,
      queryParameters: {'phone_number': phoneNumber},
      mapper: (json) => PhoneLookupResponse.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  @override
  Future<ApiResult<EmergencyContactResponse>> getAllEmergencyContacts() async {
    return _apiService.get<EmergencyContactResponse>(
      CommonEndpoints.allEmergencyContacts,
      mapper: (json) => EmergencyContactResponse.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  @override
  Future<ApiResult<PersonalContact>> addEmergencyContact(AddEmergencyContactRequest request) async {
    return _apiService.post<PersonalContact>(
      CommonEndpoints.emergencyContacts,
      data: request.toJson(),
      mapper: (json) => PersonalContact.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  @override
  Future<ApiResult<PersonalContact>> updateEmergencyContact(String contactId, String contactName) async {
    return _apiService.put<PersonalContact>(
      CommonEndpoints.emergencyContact(contactId),
      data: {'contactName': contactName},
      mapper: (json) => PersonalContact.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  @override
  Future<ApiResult<void>> deleteEmergencyContact(String contactId) async {
    return _apiService.delete<void>(
      CommonEndpoints.emergencyContact(contactId),
      mapper: (_) {},
    );
  }
}
