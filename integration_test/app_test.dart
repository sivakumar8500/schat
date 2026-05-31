import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:schat/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End App Flow', () {
    testWidgets('App launches, navigates through splash, intro, and reaches dashboard', (tester) async {
      // Clear preferences to ensure we see the intro screen
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Launch the app
      app.main();
      
      // Wait for the 3-second splash screen to finish
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Verify we are on the IntroPage and see the first text
      expect(find.text('Welcome to Schat'), findsOneWidget);

      // Tap Next to go to Page 2
      final nextButton = find.text('Next');
      await tester.tap(nextButton);
      await tester.pumpAndSettle();
      expect(find.text('Secure Messaging'), findsOneWidget);

      // Tap Next to go to Page 3
      await tester.tap(nextButton);
      await tester.pumpAndSettle();
      expect(find.text('Let\'s Get Started!'), findsOneWidget);

      // Tap Done to navigate to Dashboard
      final doneButton = find.text('Done');
      await tester.tap(doneButton);
      await tester.pumpAndSettle();

      // Verify we are on the Dashboard
      expect(find.text('Schat'), findsOneWidget); // AppBar title
      expect(find.byType(ListView), findsOneWidget); // Chat list
      expect(find.byType(BottomNavigationBar), findsOneWidget); // Bottom Nav
    });
  });
}
