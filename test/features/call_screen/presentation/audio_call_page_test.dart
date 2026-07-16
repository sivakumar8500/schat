import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:schat/features/call_screen/src/presentation/audio_call_page.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_bloc.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_event.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_state.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/core/network/connectivity_repository.dart';

class MockCallWebRtcBloc extends MockBloc<CallWebRtcEvent, CallWebRtcState>
    implements CallWebRtcBloc {}

class MockConnectivityRepository extends Mock implements ConnectivityRepository {}

void main() {
  final getIt = GetIt.instance;
  late MockCallWebRtcBloc mockCallWebRtcBloc;

  setUp(() async {
    await getIt.reset();
    mockCallWebRtcBloc = MockCallWebRtcBloc();
    when(() => mockCallWebRtcBloc.stream).thenAnswer((_) => const Stream.empty());
    getIt.registerSingleton<CallWebRtcBloc>(mockCallWebRtcBloc);

    final mockConnectivityRepository = MockConnectivityRepository();
    when(() => mockConnectivityRepository.currentConnectivity).thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(() => mockConnectivityRepository.onConnectivityChanged).thenAnswer((_) => const Stream.empty());
    getIt.registerSingleton<ConnectivityRepository>(mockConnectivityRepository);
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
    expect(find.byIcon(CommonIcons.phone), findsOneWidget);
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
        contactName: 'Alice',
        recipientId: 'test_recipient',
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    // Pump 2 seconds to allow the delayed animation-start timers in initState to complete
    await tester.pump(const Duration(seconds: 2));

    expect(find.byIcon(CommonIcons.micOff), findsOneWidget);
  });
}
