abstract class AuthRepository {
  Future<bool> sendOtp(String mobile);
  Future<bool> verifyOtp(String mobile, String otp);
}
