import 'package:schat/core/network/api_result.dart';

abstract class AuthRepository {
  Future<ApiResult<bool>> sendOtp(String mobile, {String? appSignature});
  Future<ApiResult<bool>> verifyOtp(String mobile, String otp, String deviceId);
  Future<void> logout();
}
