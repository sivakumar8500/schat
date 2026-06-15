import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/features/dashboard_screen/src/data/repositories/dashboard_repository_impl.dart';
import 'package:schat/features/dashboard_screen/src/domain/chat_model.dart';
import 'package:schat/utils/common_endpoints.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late DashboardRepositoryImpl repository;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    repository = DashboardRepositoryImpl(mockApiService);
  });

  group('getChats', () {
    final chatData = [
      {
        'id': '1',
        'is_group': false,
        'created_at': 'now',
        'updated_at': 'now',
        'recipient': {
          'id': 'r1',
          'phone_number': '1234567890',
          'is_active': true,
          'is_online': false,
          'is_subscribed': true,
          'created_at': 'now',
          'updated_at': 'now',
        }
      }
    ];

    test('should return list of ChatModel when API call is successful', () async {
      // arrange
      when(() => mockApiService.call<List<ChatModel>>(
            path: any(named: 'path'),
            method: any(named: 'method'),
            mapper: any(named: 'mapper'),
          )).thenAnswer((_) async => ApiResult.success([
            ChatModel.fromJson(chatData[0])
          ]));

      // act
      final result = await repository.getChats();

      // assert
      expect(result, isA<Success<List<ChatModel>>>());
      expect((result as Success).data.length, 1);
      verify(() => mockApiService.call<List<ChatModel>>(
            path: CommonEndpoints.getChats,
            method: 'GET',
            mapper: any(named: 'mapper'),
          ));
    });

    test('should return failure when API call fails', () async {
      // arrange
      when(() => mockApiService.call<List<ChatModel>>(
            path: any(named: 'path'),
            method: any(named: 'method'),
            mapper: any(named: 'mapper'),
          )).thenAnswer((_) async => ApiResult.failure('Error'));

      // act
      final result = await repository.getChats();

      // assert
      expect(result, isA<Failure<List<ChatModel>>>());
      expect((result as Failure).message, 'Error');
    });
  });
}
