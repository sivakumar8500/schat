import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:schat/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Connectivity and Auth Flow Test', () {
    testWidgets('App starts and shows splash then intro', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Check if we are on Splash or Intro
      // Since Splash navigates to Intro, we expect Intro eventually
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      expect(find.text('Get Started'), findsOneWidget);
    });

    // Note: Simulating connectivity changes in integration tests often requires 
    // platform-specific mocks or real device interaction which is limited here.
    // This test ensures the basic UI and DI are wired correctly.
  });
}
