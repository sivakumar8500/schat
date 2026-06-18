import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/features/subscription_screen/src/data/repositories/subscription_repository_impl.dart';
import 'package:schat/utils/common_endpoints.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late SubscriptionRepositoryImpl repository;
  late MockDio mockDio;
  late ApiService apiService;

  setUp(() {
    mockDio = MockDio();
    apiService = ApiService(mockDio);
    repository = SubscriptionRepositoryImpl(apiService);
  });

  group('SubscriptionRepositoryImpl', () {
    test('getSubscriptionPlans returns list of plans', () async {
      final mockPlans = [
        {
          'id': '1',
          'name': 'Basic',
          'price': 0,
          'description': 'Basic plan',
          'billing_cycle': 'monthly',
          'is_active': true,
        },
      ];

      when(
        () => mockDio.request(
          CommonEndpoints.getPlans,
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: mockPlans,
          statusCode: 200,
          requestOptions: RequestOptions(path: CommonEndpoints.getPlans),
        ),
      );

      final result = await repository.getSubscriptionPlans();

      result.when(
        success: (plans) {
          expect(plans, isNotEmpty);
          expect(plans.length, 1);
          expect(plans.first.name, 'Basic');
        },
        failure: (error, statusCode) => fail('Should have succeeded: $error'),
      );
    });
  });
}
