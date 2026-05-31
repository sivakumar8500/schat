import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:schat/features/splash_screen/splash_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: SplashPage(),
    );
  }

  testWidgets('SplashPage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Verify UI
    expect(find.text('Schat'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Let the timer finish
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
