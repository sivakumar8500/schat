import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/features/profile_screen/src/data/repositories/profile_repository_impl.dart';
import 'package:schat/features/profile_screen/src/domain/models/update_profile_request.dart';
import 'package:dio/dio.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late ProfileRepositoryImpl repository;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    repository = ProfileRepositoryImpl(mockApiService);
  });

  group('ProfileRepositoryImpl', () {
    test('updateProfile returns success', () async {
      final request = UpdateProfileRequest(username: 'testuser');
      
      when(() => mockApiService.put(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(
                data: {'status': 'success', 'data': {'id': '1', 'username': 'testuser'}},
                statusCode: 200,
                requestOptions: RequestOptions(path: ''),
              ));

      final result = await repository.updateProfile(request);
      expect(result is Success, isTrue);
    });
  });
}
