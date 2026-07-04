import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:schat/features/profile_screen/src/presentation/profile_page.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/features/auth_screen/src/domain/repositories/auth_repository.dart';
import 'package:schat/injection.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/subscription_screen/src/domain/repositories/subscription_repository.dart';
import 'package:schat/utils/theme_controller.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/features/profile_screen/src/domain/models/update_profile_request.dart';
import 'package:schat/utils/common_icons.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}
class MockSubscriptionRepository extends Mock implements SubscriptionRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockProfileRepository mockProfileRepository;
  late MockSubscriptionRepository mockSubRepo;
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    registerFallbackValue(UpdateProfileRequest(username: ''));
  });

  setUp(() async {
    mockProfileRepository = MockProfileRepository();
    mockSubRepo = MockSubscriptionRepository();
    mockAuthRepository = MockAuthRepository();

    await getIt.reset();
    getIt.registerSingleton<ProfileRepository>(mockProfileRepository);
    getIt.registerSingleton<SubscriptionRepository>(mockSubRepo);
    getIt.registerSingleton<AuthRepository>(mockAuthRepository);
    getIt.registerSingleton<ThemeController>(ThemeController());

    when(() => mockSubRepo.getSubscriptionPlans()).thenAnswer((_) async => const Success([]));
    final now = DateTime.now().toIso8601String();
    when(() => mockProfileRepository.getProfile()).thenAnswer((_) async => Success(
          UserModel(
            id: '1', 
            phoneNumber: '1234567890', 
            isSubscribed: false,
            isActive: true,
            isOnline: true,
            createdAt: now,
            updatedAt: now,
          ),
        ));

    SharedPreferences.setMockInitialValues({});
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: ProfilePage(),
    );
  }

  testWidgets('renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Complete Profile'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Save Profile'), findsOneWidget);
    expect(find.byIcon(CommonIcons.person), findsOneWidget);
  });

  testWidgets('shows validation error when username is empty', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Username cannot be empty'), findsOneWidget);
  });

  testWidgets('shows validation error when username is < 3 characters', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ab');
    await tester.tap(find.text('Save Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Username must be at least 3 characters long'), findsOneWidget);
  });

  testWidgets('shows validation error when username does not start with alphabetical char', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '1abc');
    await tester.tap(find.text('Save Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Username must start with an alphabetical character'), findsOneWidget);
  });

  testWidgets('shows validation error when username starts with special character', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '@abc');
    await tester.tap(find.text('Save Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Username must start with an alphabetical character'), findsOneWidget);
  });

  testWidgets('limits username textfield length to 60', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final textFieldFinder = find.byType(TextField);
    final longUsername = 'a' * 100;
    await tester.enterText(textFieldFinder, longUsername);
    await tester.pump();

    final TextField textField = tester.widget(textFieldFinder);
    expect(textField.controller?.text.length, 60);
  });

  testWidgets('submits successfully when username starts with alphabetical char and is valid', (WidgetTester tester) async {
    final now = DateTime.now().toIso8601String();
    when(() => mockProfileRepository.updateProfile(any())).thenAnswer((_) async => Success(
          UserModel(
            id: '1', 
            phoneNumber: '1234567890', 
            isSubscribed: false,
            isActive: true,
            isOnline: true,
            createdAt: now,
            updatedAt: now,
          ),
        ));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'a1@ _#');
    await tester.tap(find.text('Save Profile'));
    await tester.pumpAndSettle();

    verify(() => mockProfileRepository.updateProfile(any())).called(1);
  });
}
