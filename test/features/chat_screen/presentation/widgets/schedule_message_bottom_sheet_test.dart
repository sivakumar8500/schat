import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/schedule_message_bottom_sheet.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('ScheduleMessageBottomSheet Widget Tests', () {
    testWidgets('renders schedule message title and form fields', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const ScheduleMessageBottomSheet(contactName: 'Test Contact'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Scheduled Messages'), findsOneWidget);
      expect(find.text('Test Contact'), findsOneWidget);
      expect(find.text('Schedule New'), findsOneWidget);
      expect(find.text('Scheduled (0)'), findsOneWidget);
      expect(find.text('MESSAGE TYPE'), findsOneWidget);
      expect(find.text('Confirm & Schedule'), findsOneWidget);
    });

    testWidgets('shows validation error when submitting empty text and no file', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const ScheduleMessageBottomSheet(contactName: 'Test Contact'),
        ),
      );
      await tester.pumpAndSettle();

      final submitBtn = find.text('Confirm & Schedule');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a message or attach a file.'), findsOneWidget);
    });
  });
}
