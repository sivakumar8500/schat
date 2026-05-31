import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:schat/features/profile_screen/src/data/repositories/profile_repository_impl.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late ProfileRepositoryImpl repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = ProfileRepositoryImpl(mockDio);
  });

  group('ProfileRepositoryImpl', () {
    test('updateProfile returns true after delay', () async {
      final result = await repository.updateProfile('testuser', null);
      expect(result, isTrue);
    });
  });
}
