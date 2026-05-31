import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schat/features/payment_screen/src/presentation/payment_success_page.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    getIt.registerSingleton<ThemeController>(ThemeController());
    SharedPreferences.setMockInitialValues({});
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: PaymentSuccessPage(),
    );
  }

  testWidgets('PaymentSuccessPage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Wait for the first frame
    await tester.pump();

    expect(find.text('Payment Successful!'), findsOneWidget);
    expect(find.text('Your subscription is now active.'), findsOneWidget);
    expect(find.textContaining('Redirecting to dashboard in'), findsOneWidget);
    expect(find.byType(Icon), findsWidgets);
  });
}
