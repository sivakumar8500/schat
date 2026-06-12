import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schat/features/dashboard_screen/src/presentation/widgets/empty_chats_view.dart';
import 'package:schat/utils/theme_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockThemeController extends ThemeController {
  MockThemeController(super.prefs);
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<ThemeController>()) {
      getIt.registerSingleton<ThemeController>(ThemeController(prefs));
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

    expect(find.text('No active chats'), findsOneWidget);
    expect(find.text('Ready to chat? Tap below to start a conversation and stay connected with friends and family!'), findsOneWidget);
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
