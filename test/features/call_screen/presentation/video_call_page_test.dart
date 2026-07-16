import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:schat/features/call_screen/src/domain/web_rtc_service.dart';
import 'package:schat/features/call_screen/src/presentation/video_call_page.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_bloc.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_event.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_state.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/core/network/connectivity_repository.dart';

class MockCallWebRtcBloc extends MockBloc<CallWebRtcEvent, CallWebRtcState>
    implements CallWebRtcBloc {}

class MockWebRtcService extends Mock implements WebRtcService {}
class MockRTCVideoRenderer extends Mock implements RTCVideoRenderer {}
class MockConnectivityRepository extends Mock implements ConnectivityRepository {}

void main() {
  final getIt = GetIt.instance;
  late MockCallWebRtcBloc mockCallWebRtcBloc;
  late MockWebRtcService mockWebRtcService;
  late MockRTCVideoRenderer mockLocalRenderer;
  late MockRTCVideoRenderer mockRemoteRenderer;

  setUp(() async {
    await getIt.reset();
    mockCallWebRtcBloc = MockCallWebRtcBloc();
    mockWebRtcService = MockWebRtcService();
    mockLocalRenderer = MockRTCVideoRenderer();
    mockRemoteRenderer = MockRTCVideoRenderer();

    when(() => mockCallWebRtcBloc.stream).thenAnswer((_) => const Stream.empty());

    // Stub renderVideo, textureId, and value to prevent Null Pointer / Type errors in RTCVideoView
    when(() => mockLocalRenderer.renderVideo).thenReturn(false);
    when(() => mockRemoteRenderer.renderVideo).thenReturn(false);
    when(() => mockLocalRenderer.textureId).thenReturn(0);
    when(() => mockRemoteRenderer.textureId).thenReturn(0);
    when(() => mockLocalRenderer.value).thenReturn(const RTCVideoValue());
    when(() => mockRemoteRenderer.value).thenReturn(const RTCVideoValue());

    when(() => mockWebRtcService.localRenderer).thenReturn(mockLocalRenderer);
    when(() => mockWebRtcService.remoteRenderer).thenReturn(mockRemoteRenderer);
    when(() => mockWebRtcService.callSignalState).thenAnswer((_) => const Stream.empty());

    getIt.registerSingleton<WebRtcService>(mockWebRtcService);
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
        child: const VideoCallPage(
          conversationId: 'test_conv',
          recipientId: 'test_recip',
          contactName: 'Bob',
          contactColor: Colors.blue,
          isOutgoing: false,
        ),
      ),
    );
  }

  testWidgets('VideoCallPage displays controls and contact name', (WidgetTester tester) async {
    when(() => mockCallWebRtcBloc.state).thenReturn(const CallIdle());

    await tester.pumpWidget(createWidgetUnderTest());
    // Pump 5 seconds to allow controls timer and animations to trigger/settle
    await tester.pump(const Duration(seconds: 5));

    expect(find.text('Bob'), findsOneWidget);
    expect(find.byIcon(CommonIcons.videocam), findsWidgets);
    expect(find.byIcon(CommonIcons.callEnd), findsOneWidget);
  });
}
