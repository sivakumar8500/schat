import 'dart:typed_data';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/features/profile_screen/src/domain/models/update_profile_request.dart';

abstract class ProfileRepository {
  Future<ApiResult<UserModel>> getProfile();
  Future<ApiResult<UserModel>> updateProfile(UpdateProfileRequest request);
  Future<ApiResult<UserModel>> getUserById(String userId);
  Future<String?> uploadProfilePicture({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
    Uint8List? fileBytes,
  });

  Future<ApiResult<void>> blockUser(String userId);
  Future<ApiResult<void>> unblockUser(String userId);
  Future<ApiResult<List<UserModel>>> getBlockedUsers();
}
