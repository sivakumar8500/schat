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
      when(() => mockDio.request(
            CommonEndpoints.sendOtp,
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: {'success': true},
            statusCode: 200,
            requestOptions: RequestOptions(path: CommonEndpoints.sendOtp),
          ));

      final result = await repository.sendOtp(mobile);

      expect(result is Success<bool>, isTrue);
      expect((result as Success<bool>).data, isTrue);
    });

    test('should return Failure when API fails', () async {
      when(() => mockDio.request(
            CommonEndpoints.sendOtp,
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
            requestOptions: RequestOptions(path: CommonEndpoints.sendOtp),
            response: Response(
              data: {'message': 'Too many requests'},
              statusCode: 429,
              requestOptions: RequestOptions(path: CommonEndpoints.sendOtp),
            ),
            type: DioExceptionType.badResponse,
          ));

      final result = await repository.sendOtp(mobile);

      expect(result is Failure, isTrue);
      expect((result as Failure).message, 'Too many requests');
    });
  });

  group('verifyOtp', () {
    const mobile = '9030303030';
    const otp = '887765';
    const deviceId = 'ljonhonouuoi';

    test('should return Success(true) when successful', () async {
      when(() => mockDio.request(
            CommonEndpoints.verifyOtp,
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: {
              'access_token': 'access',
              'refresh_token': 'refresh',
              'token_type': 'Bearer',
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: CommonEndpoints.verifyOtp),
          ));
      
      when(() => mockStorageService.saveTokens(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
      )).thenAnswer((_) async => {});

      final result = await repository.verifyOtp(mobile, otp, deviceId);

      expect(result is Success<bool>, isTrue);
      expect((result as Success<bool>).data, isTrue);
    });

    test('should return Failure when OTP is invalid', () async {
      when(() => mockDio.request(
            CommonEndpoints.verifyOtp,
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
            requestOptions: RequestOptions(path: CommonEndpoints.verifyOtp),
            response: Response(
              data: {'message': 'Invalid OTP'},
              statusCode: 400,
              requestOptions: RequestOptions(path: CommonEndpoints.verifyOtp),
            ),
            type: DioExceptionType.badResponse,
          ));

      final result = await repository.verifyOtp(mobile, otp, deviceId);

      expect(result is Failure, isTrue);
      expect((result as Failure).message, 'Invalid OTP');
    });
  });
}
