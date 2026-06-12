import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/features/profile_screen/src/domain/models/update_profile_request.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/utils/common_endpoints.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  final ApiService _apiService;

  ProfileRepositoryImpl(this._apiService);

  @override
  Future<ApiResult<UserModel>> getProfile() async {
    return _apiService.get<UserModel>(
      CommonEndpoints.profileMe,
      mapper: (json) => UserModel.fromJson(json),
    );
  }

  @override
  Future<ApiResult<UserModel>> updateProfile(UpdateProfileRequest request) async {
    return _apiService.put<UserModel>(
      CommonEndpoints.updateProfile,
      data: request.toJson(),
      mapper: (json) => UserModel.fromJson(json),
    );
  }
}
