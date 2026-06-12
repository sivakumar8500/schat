import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/auth_screen/src/data/models/send_otp_request.dart';
import 'package:schat/features/auth_screen/src/data/models/verify_otp_request.dart';
import 'package:schat/features/auth_screen/src/data/models/verify_otp_response.dart';
import 'package:schat/features/auth_screen/src/domain/repositories/auth_repository.dart';
import 'package:schat/utils/common_endpoints.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthRepositoryImpl(this._apiService, this._storageService);

  @override
  Future<ApiResult<bool>> sendOtp(String mobile) async {
    final request = SendOtpRequest(phoneNumber: mobile);
    return _apiService.post<bool>(
      CommonEndpoints.sendOtp,
      data: request.toJson(),
      mapper: (json) {
        if (json is Map<String, dynamic>) {
          return json['success'] == true;
        }
        return false;
      },
    );
  }

  @override
  Future<ApiResult<bool>> verifyOtp(String mobile, String otp, String deviceId) async {
    final request = VerifyOtpRequest(
      phoneNumber: mobile,
      otp: otp,
      deviceId: deviceId,
    );

    final result = await _apiService.post<VerifyOtpResponse>(
      CommonEndpoints.verifyOtp,
      data: request.toJson(),
      mapper: (json) => VerifyOtpResponse.fromJson(json),
    );

    return result.when(
      success: (response) async {
        await _storageService.saveTokens(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
        );
        return ApiResult.success(true);
      },
      failure: (message) => ApiResult.failure(message),
    );
  }

  @override
  Future<void> logout() async {
    await _storageService.clearTokens();
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
