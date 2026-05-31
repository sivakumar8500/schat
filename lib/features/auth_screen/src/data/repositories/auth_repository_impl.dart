import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/features/auth_screen/src/domain/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  // ignore: unused_field
  final Dio _dio;

  AuthRepositoryImpl(this._dio);

  @override
  Future<bool> sendOtp(String mobile) async {
    try {
      // final response = await _dio.post('/auth/send-otp', data: {'mobile': mobile});
      // return response.statusCode == 200;

      // Simulating network request for now
      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e) {
      // Handle DioException here
      return false;
    }
  }

  @override
  Future<bool> verifyOtp(String mobile, String otp) async {
    try {
      // final response = await _dio.post('/auth/verify-otp', data: {'mobile': mobile, 'otp': otp});
      // return response.statusCode == 200;

      // Simulating network request for now
      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e) {
      return false;
    }
  }
}
