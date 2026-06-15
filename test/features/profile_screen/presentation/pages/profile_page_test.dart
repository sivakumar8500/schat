import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:schat/features/profile_screen/src/presentation/profile_page.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/injection.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/subscription_screen/src/domain/repositories/subscription_repository.dart';
import 'package:schat/utils/theme_controller.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}
class MockSubscriptionRepository extends Mock implements SubscriptionRepository {}

void main() {
  late MockProfileRepository mockProfileRepository;
  late MockSubscriptionRepository mockSubRepo;

  setUp(() async {
    mockProfileRepository = MockProfileRepository();
    mockSubRepo = MockSubscriptionRepository();
    await getIt.reset();
    getIt.registerSingleton<ProfileRepository>(mockProfileRepository);
    getIt.registerSingleton<SubscriptionRepository>(mockSubRepo);
    getIt.registerSingleton<ThemeController>(ThemeController());
    when(() => mockSubRepo.getSubscriptionPlans()).thenAnswer((_) async => const Success([]));
    SharedPreferences.setMockInitialValues({});
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: ProfilePage(),
    );
  }

  testWidgets('renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Complete Profile'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Save Profile'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget); // Placeholder avatar
  });

  testWidgets('shows validation error when username is empty', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('Save Profile'));
    await tester.pump();

    expect(find.text('Please enter a username'), findsOneWidget);
  });
}
