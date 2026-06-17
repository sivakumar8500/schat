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
        return ApiResult.success(user);
      },
      failure: (message, statusCode) => ApiResult.failure(message, statusCode: statusCode),
    );
  }

  @override
  Future<ApiResult<UserModel>> updateProfile(UpdateProfileRequest request) async {
    final result = await _apiService.patch<UserModel>(
      CommonEndpoints.updateProfile,
      data: request.toJson(),
      mapper: (json) => UserModel.fromJson(json),
    );

    return result.when(
      success: (user) {
        _storageService.saveUserId(user.id);
        return ApiResult.success(user);
      },
      failure: (message, statusCode) => ApiResult.failure(message, statusCode: statusCode),
    );
  }
}
