import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:schat/features/intro_screen/intro_screen.dart';
import 'package:schat/features/auth_screen/src/domain/repositories/auth_repository.dart';
import 'package:schat/injection.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockAuthRepository = MockAuthRepository();
    await getIt.reset();
    getIt.registerSingleton<AuthRepository>(mockAuthRepository);
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: IntroPage(),
    );
  }

  testWidgets('IntroPage renders new landing screen correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Verify key titles and texts exist
    expect(find.text('Secure chats'), findsOneWidget);
    expect(find.text('Best in Privacy'), findsOneWidget);
    expect(
      find.text('Messages that disappear. Calls that can\'t be tapped. Files only you control.'),
      findsOneWidget,
    );

    // Verify buttons and visual items
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('IntroPage navigates to MobileEntryPage on Get started button tap', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Tap Get started
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // Verify MobileEntryPage renders
    expect(find.text("Let's "), findsOneWidget);
    expect(find.text("you in."), findsOneWidget);

    // Verify shared preferences is updated
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('hasSeenIntro'), true);
  });

  testWidgets('IntroPage navigates to MobileEntryPage on Sign in tap', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Tap Sign in
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    // Verify MobileEntryPage renders
    expect(find.text("Let's "), findsOneWidget);
    expect(find.text("you in."), findsOneWidget);

    // Verify shared preferences is updated
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('hasSeenIntro'), true);
  });
}
