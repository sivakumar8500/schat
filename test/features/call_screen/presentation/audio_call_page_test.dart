import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/features/call_screen/src/presentation/audio_call_page.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_bloc.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_event.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_state.dart';
import 'package:schat/utils/common_icons.dart';

class MockCallWebRtcBloc extends MockBloc<CallWebRtcEvent, CallWebRtcState>
    implements CallWebRtcBloc {}

void main() {
  late MockCallWebRtcBloc mockCallWebRtcBloc;

  setUp(() {
    mockCallWebRtcBloc = MockCallWebRtcBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<CallWebRtcBloc>.value(
        value: mockCallWebRtcBloc,
        child: const AudioCallPage(
          conversationId: 'test_conv',
          recipientId: 'test_recip',
          contactName: 'Alice',
          contactColor: Colors.pink,
          isOutgoing: false,
        ),
      ),
    );
  }

  testWidgets('AudioCallPage displays contact name and initial state elements', (WidgetTester tester) async {
    when(() => mockCallWebRtcBloc.state).thenReturn(const CallIdle());

    await tester.pumpWidget(createWidgetUnderTest());
    // Pump 2 seconds to allow the delayed animation-start timers in initState to complete
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('A'), findsOneWidget); // Initial in avatar
    expect(find.byIcon(CommonIcons.mic), findsOneWidget);
    expect(find.byIcon(CommonIcons.callEnd), findsOneWidget);
  });

  testWidgets('AudioCallPage displays muted status when call state has mute active', (WidgetTester tester) async {
    when(() => mockCallWebRtcBloc.state).thenReturn(
      const CallActive(
        conversationId: 'test_conv',
        isVideo: false,
        isMuted: true,
        isSpeakerOn: false,
        isVideoOff: false,
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    // Pump 2 seconds to allow the delayed animation-start timers in initState to complete
    await tester.pump(const Duration(seconds: 2));

    expect(find.byIcon(CommonIcons.micOff), findsOneWidget);
  });
}
