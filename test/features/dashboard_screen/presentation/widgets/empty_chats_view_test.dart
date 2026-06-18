import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schat/features/dashboard_screen/src/presentation/widgets/empty_chats_view.dart';
import 'package:schat/utils/theme_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<ThemeController>()) {
      getIt.registerSingleton<ThemeController>(ThemeController());
    }
  });

  Widget createWidgetUnderTest({VoidCallback? onChatNowPressed}) {
    return MaterialApp(
      home: Scaffold(
        body: EmptyChatsView(onChatNowPressed: onChatNowPressed ?? () {}),
      ),
    );
  }

  testWidgets('renders EmptyChatsView with illustration and button', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Start your message'), findsOneWidget);
    expect(find.text('Start conversation with other employee in your organization.'), findsOneWidget);
    expect(find.text('Chat Now'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('calls onChatNowPressed when button is tapped', (WidgetTester tester) async {
    bool wasPressed = false;
    await tester.pumpWidget(createWidgetUnderTest(onChatNowPressed: () {
      wasPressed = true;
    }));

    await tester.tap(find.text('Chat Now'));
    await tester.pump();

    expect(wasPressed, isTrue);
  });
}
