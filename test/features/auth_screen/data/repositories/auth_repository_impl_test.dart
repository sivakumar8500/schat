import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/auth_screen/src/data/repositories/auth_repository_impl.dart';
import 'package:schat/utils/common_endpoints.dart';

class MockDio extends Mock implements Dio {}
class MockStorageService extends Mock implements StorageService {}

void main() {
  late AuthRepositoryImpl repository;
  late MockDio mockDio;
  late MockStorageService mockStorageService;
  late ApiService apiService;

  setUp(() {
    mockDio = MockDio();
    mockStorageService = MockStorageService();
    apiService = ApiService(mockDio);
    repository = AuthRepositoryImpl(apiService, mockStorageService);
  });

  group('sendOtp', () {
    const mobile = '9030303030';

    test('should return Success(true) when successful', () async {
      when(() => mockDio.post(
            CommonEndpoints.sendOtp,
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: {'status': 'success'},
            statusCode: 200,
            requestOptions: RequestOptions(path: CommonEndpoints.sendOtp),
          ));

      final result = await repository.sendOtp(mobile);

      expect(result, const Success(true));
    });

    test('should return Failure when API fails', () async {
      when(() => mockDio.post(
            CommonEndpoints.sendOtp,
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: {'message': 'Too many requests'},
            statusCode: 429,
            requestOptions: RequestOptions(path: CommonEndpoints.sendOtp),
          ));

      final result = await repository.sendOtp(mobile);

      expect(result, const Failure('Too many requests'));
    });
  });

  group('verifyOtp', () {
    const mobile = '9030303030';
    const otp = '887765';
    const deviceId = 'ljonhonouuoi';

    test('should return Success(true) when successful', () async {
      when(() => mockDio.post(
            CommonEndpoints.verifyOtp,
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: {
              'status': 'success',
              'tokens': {
                'access_token': 'access',
                'refresh_token': 'refresh',
              }
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: CommonEndpoints.verifyOtp),
          ));
      
      when(() => mockStorageService.saveTokens(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
      )).thenAnswer((_) async => {});

      final result = await repository.verifyOtp(mobile, otp, deviceId);

      expect(result, const Success(true));
    });

    test('should return Failure when OTP is invalid', () async {
      when(() => mockDio.post(
            CommonEndpoints.verifyOtp,
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: {'message': 'Invalid OTP'},
            statusCode: 400,
            requestOptions: RequestOptions(path: CommonEndpoints.verifyOtp),
          ));

      final result = await repository.verifyOtp(mobile, otp, deviceId);

      expect(result, const Failure('Invalid OTP'));
    });
  });
}
