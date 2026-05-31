import 'package:flutter_test/flutter_test.dart';
import 'package:schat/features/subscription_screen/src/data/repositories/subscription_repository_impl.dart';

void main() {
  late SubscriptionRepositoryImpl repository;

  setUp(() {
    repository = SubscriptionRepositoryImpl();
  });

  group('SubscriptionRepositoryImpl', () {
    test('getSubscriptionPlans returns list of plans', () async {
      final plans = await repository.getSubscriptionPlans();
      expect(plans, isNotEmpty);
      expect(plans.length, 3);
      expect(plans.first.name, 'Basic');
    });
  });
}
