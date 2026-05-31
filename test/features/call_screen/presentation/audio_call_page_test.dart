import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schat/features/call_screen/src/presentation/audio_call_page.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: AudioCallPage(
        contactName: 'Alice',
        contactColor: Colors.pink,
      ),
    );
  }

  testWidgets('AudioCallPage displays contact name and buttons', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('A'), findsOneWidget); // Initial in avatar
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    expect(find.byIcon(Icons.call_end_rounded), findsOneWidget);
    expect(find.byIcon(Icons.volume_down_rounded), findsOneWidget);
  });

  testWidgets('AudioCallPage toggles mute button', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    
    // Tap mute
    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.mic_off_rounded), findsOneWidget);
  });
}
