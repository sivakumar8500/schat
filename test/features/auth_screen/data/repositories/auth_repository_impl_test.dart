import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/features/auth_screen/src/data/repositories/auth_repository_impl.dart';
import 'package:schat/utils/common_endpoints.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late AuthRepositoryImpl repository;
  late MockDio mockDio;
  late ApiService apiService;

  setUp(() {
    mockDio = MockDio();
    apiService = ApiService(mockDio);
    repository = AuthRepositoryImpl(apiService);
  });

  group('sendOtp', () {
    const mobile = '9030303030';

    test('should return ApiResult.success(true) when successful', () async {
      when(() => mockDio.post(
            CommonEndpoints.sendOtp,
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: {'status': 'success'},
            statusCode: 200,
            requestOptions: RequestOptions(path: CommonEndpoints.sendOtp),
          ));

      final result = await repository.sendOtp(mobile);

      expect(result, const ApiResult.success(true));
    });

    test('should return ApiResult.failure when API fails', () async {
      when(() => mockDio.post(
            CommonEndpoints.sendOtp,
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: {'message': 'Too many requests'},
            statusCode: 429,
            requestOptions: RequestOptions(path: CommonEndpoints.sendOtp),
          ));

      final result = await repository.sendOtp(mobile);

      expect(result, const ApiResult.failure('Too many requests'));
    });
  });

  group('verifyOtp', () {
    const mobile = '9030303030';
    const otp = '887765';
    const deviceId = 'ljonhonouuoi';

    test('should return ApiResult.success(true) when successful', () async {
      when(() => mockDio.post(
            CommonEndpoints.verifyOtp,
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: {'status': 'success'},
            statusCode: 200,
            requestOptions: RequestOptions(path: CommonEndpoints.verifyOtp),
          ));

      final result = await repository.verifyOtp(mobile, otp, deviceId);

      expect(result, const ApiResult.success(true));
    });

    test('should return ApiResult.failure when OTP is invalid', () async {
      when(() => mockDio.post(
            CommonEndpoints.verifyOtp,
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: {'message': 'Invalid OTP'},
            statusCode: 400,
            requestOptions: RequestOptions(path: CommonEndpoints.verifyOtp),
          ));

      final result = await repository.verifyOtp(mobile, otp, deviceId);

      expect(result, const ApiResult.failure('Invalid OTP'));
    });
  });
}
