import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/features/profile_screen/src/domain/models/update_profile_request.dart';

abstract class ProfileRepository {
  Future<ApiResult<UserModel>> getProfile();
  Future<ApiResult<UserModel>> updateProfile(UpdateProfileRequest request);
}
