import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/subscription_screen/subscription_screen.dart';
import 'package:schat/features/subscription_screen/src/domain/models/subscription_plan_model.dart';
import 'package:schat/features/subscription_screen/src/domain/repositories/subscription_repository.dart';
import 'package:schat/injection.dart';

class MockSubscriptionRepository extends Mock implements SubscriptionRepository {}

void main() {
  late MockSubscriptionRepository mockRepo;

  setUp(() async {
    await getIt.reset();
    mockRepo = MockSubscriptionRepository();
    getIt.registerSingleton<SubscriptionRepository>(mockRepo);
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: SubscriptionPage(),
    );
  }

  testWidgets('SubscriptionPage displays plans and allows selection', (WidgetTester tester) async {
    when(() => mockRepo.getSubscriptionPlans()).thenAnswer(
      (_) async => const Success([
        SubscriptionPlanModel(
          id: '1',
          name: 'Basic Test',
          price: 0,
          description: 'Desc',
          billingCycle: 'monthly',
          isActive: true,
        ),
      ]),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Basic Test'), findsOneWidget);

    // Select plan
    await tester.tap(find.text('Basic Test'));
    await tester.pumpAndSettle();
    
    // Check if Continue button is visible
    expect(find.text('Continue'), findsOneWidget);
  });
}
