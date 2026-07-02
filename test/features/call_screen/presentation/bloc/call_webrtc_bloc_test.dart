import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:schat/features/call_screen/src/domain/web_rtc_service.dart';
import 'package:schat/features/call_screen/src/domain/call_sound_service.dart';
import 'package:schat/core/notifications/call_notification_service.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_bloc.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_event.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_state.dart';
import 'package:schat/injection.dart';

class MockWebRtcService extends Mock implements WebRtcService {}
class MockChatSocketRepository extends Mock implements ChatSocketRepository {}
class MockCallSoundService extends Mock implements CallSoundService {}
class MockCallNotificationService extends Mock implements CallNotificationService {}
class MockStorageService extends Mock implements StorageService {}

void main() {
  late CallWebRtcBloc bloc;
  late MockWebRtcService mockWebRtcService;
  late MockChatSocketRepository mockRepository;
  late MockCallSoundService mockSoundService;
  late MockCallNotificationService mockNotificationService;
  late MockStorageService mockStorageService;
  late StreamController<dynamic> socketStreamController;

  setUpAll(() {
    registerFallbackValue(const CallIdle());
  });

  setUp(() {
    mockWebRtcService = MockWebRtcService();
    mockRepository = MockChatSocketRepository();
    mockSoundService = MockCallSoundService();
    mockNotificationService = MockCallNotificationService();
    mockStorageService = MockStorageService();
    socketStreamController = StreamController<dynamic>.broadcast();

    when(() => mockRepository.onMessage).thenAnswer((_) => socketStreamController.stream);
    when(() => mockNotificationService.onCallAnswered).thenAnswer((_) => const Stream.empty());
    when(() => mockWebRtcService.activeConversationId).thenReturn('test_conv');
    when(() => mockWebRtcService.cleanup()).thenAnswer((_) async {});
    when(() => mockWebRtcService.toggleMute(any())).thenReturn(null);
    when(() => mockWebRtcService.toggleVideo(any())).thenReturn(null);

    getIt.allowReassignment = true;
    getIt.registerSingleton<CallSoundService>(mockSoundService);
    getIt.registerSingleton<CallNotificationService>(mockNotificationService);
    getIt.registerSingleton<StorageService>(mockStorageService);

    bloc = CallWebRtcBloc(mockWebRtcService, mockRepository);
  });

  tearDown(() {
    bloc.close();
    socketStreamController.close();
  });

  group('CallWebRtcBloc Mute/Video Toggling', () {
    const initialState = CallActive(
      conversationId: 'test_conv',
      contactName: 'Alice',
      recipientId: 'recip_id',
      isVideo: true,
    );

    blocTest<CallWebRtcBloc, CallWebRtcState>(
      'emits updated state and sends socket message when ToggleMuteCallEvent is added',
      build: () => bloc,
      seed: () => initialState,
      act: (bloc) => bloc.add(const ToggleMuteCallEvent()),
      verify: (bloc) {
        verify(() => mockWebRtcService.toggleMute(true)).called(1);
        verify(() => mockRepository.emit('message', {
          'type': 'call_toggle_mute',
          'conversation_id': 'test_conv',
          'is_muted': true,
          'mute_type': 'audio',
        })).called(1);
      },
      expect: () => [
        isA<CallActive>().having((s) => s.isMuted, 'isMuted', true),
      ],
    );

    blocTest<CallWebRtcBloc, CallWebRtcState>(
      'emits updated state and sends socket message when ToggleCameraCallEvent is added',
      build: () => bloc,
      seed: () => initialState,
      act: (bloc) => bloc.add(const ToggleCameraCallEvent()),
      verify: (bloc) {
        verify(() => mockWebRtcService.toggleVideo(true)).called(1);
        verify(() => mockRepository.emit('message', {
          'type': 'call_toggle_mute',
          'conversation_id': 'test_conv',
          'is_muted': true,
          'mute_type': 'video',
        })).called(1);
      },
      expect: () => [
        isA<CallActive>().having((s) => s.isVideoOff, 'isVideoOff', true),
      ],
    );

    blocTest<CallWebRtcBloc, CallWebRtcState>(
      'updates remote mute status when call_mute_status_updated is received (audio)',
      build: () => bloc,
      seed: () => initialState,
      act: (bloc) {
        socketStreamController.add({
          'type': 'call_mute_status_updated',
          'conversation_id': 'test_conv',
          'is_muted': true,
          'mute_type': 'audio',
          'sender_id': 'recip_id',
        });
      },
      expect: () => [
        isA<CallActive>().having((s) => s.isRemoteMuted, 'isRemoteMuted', true),
      ],
    );

    blocTest<CallWebRtcBloc, CallWebRtcState>(
      'updates remote video status when call_mute_status_updated is received (video)',
      build: () => bloc,
      seed: () => initialState,
      act: (bloc) {
        socketStreamController.add({
          'type': 'call_mute_status_updated',
          'conversation_id': 'test_conv',
          'is_muted': true,
          'mute_type': 'video',
          'sender_id': 'recip_id',
        });
      },
      expect: () => [
        isA<CallActive>().having((s) => s.isRemoteVideoOff, 'isRemoteVideoOff', true),
      ],
    );
  });
}
