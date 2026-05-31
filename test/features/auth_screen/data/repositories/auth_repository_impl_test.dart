import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:schat/features/auth_screen/src/data/repositories/auth_repository_impl.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late AuthRepositoryImpl repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = AuthRepositoryImpl(mockDio);
  });

  group('AuthRepositoryImpl', () {
    test('sendOtp returns true after delay', () async {
      // Currently the impl is just a mock that delays and returns true.
      final result = await repository.sendOtp('9999999999');
      expect(result, isTrue);
    });

    test('verifyOtp returns true after delay', () async {
      final result = await repository.verifyOtp('9999999999', '123456');
      expect(result, isTrue);
    });
  });
}
