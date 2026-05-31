import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schat/features/call_screen/src/presentation/video_call_page.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: VideoCallPage(
        contactName: 'Bob',
      ),
    );
  }

  testWidgets('VideoCallPage displays controls and contact name', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    
    expect(find.byIcon(Icons.videocam_rounded), findsOneWidget);
    expect(find.byIcon(Icons.call_end_rounded), findsOneWidget);
  });

  testWidgets('VideoCallPage toggles video off', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Tap video button
    await tester.tap(find.byIcon(Icons.videocam_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.videocam_off_rounded), findsOneWidget);
  });
}
