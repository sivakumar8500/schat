import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/auth_screen/src/presentation/mobile_entry_page.dart';
import 'package:schat/features/auth_screen/src/domain/repositories/auth_repository.dart';
import 'package:schat/injection.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() async {
    mockAuthRepository = MockAuthRepository();
    // Clear and register mock
    await getIt.reset();
    getIt.registerSingleton<AuthRepository>(mockAuthRepository);
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: MobileEntryPage(),
    );
  }

  testWidgets('renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Verify redesigned elements
    expect(find.text("Let's "), findsOneWidget);
    expect(find.text("you in."), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('+91'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('shows validation error when mobile is empty', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Tap Continue
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Please enter a valid 10-digit number.'), findsOneWidget);
  });

  testWidgets('navigates to OtpVerifyPage on valid input directly', (WidgetTester tester) async {
    when(() => mockAuthRepository.sendOtp(any()))
        .thenAnswer((_) async => const Success(true));

    await tester.pumpWidget(createWidgetUnderTest());

    // Enter a valid phone number
    await tester.enterText(find.byType(TextField), '9999999999');
    
    // Tap Continue
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle(); // Wait for navigation

    // Should have navigated to OtpVerifyPage
    expect(find.text('Enter the '), findsOneWidget);
  });
}
