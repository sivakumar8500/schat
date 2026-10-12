import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_endpoints.dart';

class LiveKitCallService {
  static final LiveKitCallService instance = LiveKitCallService();

  Room? _room;
  EventsListener<RoomEvent>? _listener;

  final ValueNotifier<List<Participant>> participantsNotifier =
      ValueNotifier<List<Participant>>([]);
  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isConnectingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  Room? get room => _room;
  bool get isConnected => _room != null && isConnectedNotifier.value;

  /// 1. Request OS Permissions
  Future<bool> requestPermissions({bool isVideo = true}) async {
    final micStatus = await Permission.microphone.request();
    if (isVideo) {
      final camStatus = await Permission.camera.request();
      return micStatus.isGranted && camStatus.isGranted;
    }
    return micStatus.isGranted;
  }

  /// 2. Fetch LiveKit Token from FastAPI Backend
  Future<Map<String, dynamic>> fetchToken({
    required String baseUrl,
    required String authToken,
    required String roomName,
    String callType = 'video',
  }) async {
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final url = cleanBase.endsWith('/api/v1')
        ? Uri.parse('$cleanBase/calls/token')
        : Uri.parse('$cleanBase/api/v1/calls/token');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'room_name': roomName,
        'call_type': callType,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final serverUrl = (data['server_url'] ?? data['url'] ?? '').toString();
      if (serverUrl.contains('your-livekit-server.com') ||
          serverUrl.contains('yourdomain.com') ||
          serverUrl.isEmpty) {
        throw Exception(
          'LiveKit server URL is not configured on the backend.\n\n'
          'The backend returned placeholder URL "$serverUrl".\n\n'
          'Please update LIVEKIT_URL, LIVEKIT_API_KEY, and LIVEKIT_API_SECRET in your backend server .env file.',
        );
      }
      return data;
    } else {
      throw Exception('Failed to obtain LiveKit token: ${response.body}');
    }
  }

  /// 3. Connect to LiveKit Room
  Future<Room> connectToRoom({
    required String serverUrl,
    required String token,
    bool enableVideo = true,
    bool enableAudio = true,
  }) async {
    isConnectingNotifier.value = true;
    errorNotifier.value = null;

    final roomOptions = RoomOptions(
      adaptiveStream: true,
      dynacast: true,
      defaultVideoPublishOptions: const VideoPublishOptions(
        simulcast: true,
        videoEncoding: VideoEncoding(
          maxBitrate: 1500000,
          maxFramerate: 30,
        ),
      ),
    );

    final connectOptions = ConnectOptions(
      autoSubscribe: true,
      rtcConfiguration: const RTCConfiguration(
        iceServers: [
          RTCIceServer(urls: [
            'stun:stun.l.google.com:19302',
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302',
          ]),
        ],
      ),
      timeouts: const Timeouts(
        connection: Duration(seconds: 30),
        debounce: Duration(milliseconds: 100),
        publish: Duration(seconds: 30),
        peerConnection: Duration(seconds: 30),
        iceRestart: Duration(seconds: 30),
      ),
    );

    _room = Room(roomOptions: roomOptions);
    _listener = _room!.createListener();
    _setupListeners();

    try {
      await _room!.connect(serverUrl, token, connectOptions: connectOptions);

      // Publish local media
      if (enableAudio) {
        await _room!.localParticipant?.setMicrophoneEnabled(true);
      }
      if (enableVideo) {
        await _room!.localParticipant?.setCameraEnabled(true);
      }

      isConnectedNotifier.value = true;
      isConnectingNotifier.value = false;
      _updateParticipants();
      return _room!;
    } catch (e) {
      isConnectingNotifier.value = false;
      isConnectedNotifier.value = false;
      errorNotifier.value = e.toString();
      debugPrint('LiveKit Room.connect error: $e');
      rethrow;
    }
  }

  void _setupListeners() {
    if (_listener == null) return;

    _listener!
      ..on<RoomEvent>((_) => _updateParticipants())
      ..on<ParticipantConnectedEvent>((_) => _updateParticipants())
      ..on<ParticipantDisconnectedEvent>((_) => _updateParticipants())
      ..on<TrackSubscribedEvent>((_) => _updateParticipants())
      ..on<TrackUnsubscribedEvent>((_) => _updateParticipants())
      ..on<TrackMutedEvent>((_) => _updateParticipants())
      ..on<TrackUnmutedEvent>((_) => _updateParticipants())
      ..on<ActiveSpeakersChangedEvent>((_) => _updateParticipants());
  }

  void _updateParticipants() {
    if (_room == null) {
      participantsNotifier.value = [];
      return;
    }
    final list = <Participant>[];
    if (_room!.localParticipant != null) {
      list.add(_room!.localParticipant!);
    }
    list.addAll(_room!.remoteParticipants.values);
    participantsNotifier.value = list;
  }

  /// Automatically initiates or joins a 1-to-1 or group call via LiveKit SFU
  Future<bool> joinCall({
    required String conversationId,
    bool isVideo = true,
  }) async {
    return joinGroupCall(conversationId: conversationId, isVideo: isVideo);
  }

  /// Automatically initiates or joins a group call via LiveKit SFU
  Future<bool> joinGroupCall({
    required String conversationId,
    bool isVideo = true,
  }) async {
    final token = getIt<StorageService>().getAccessToken();
    if (token == null || token.isEmpty) {
      debugPrint('LiveKitCallService: No auth token found');
      return false;
    }

    final hasPerm = await requestPermissions(isVideo: isVideo);
    if (!hasPerm) return false;

    try {
      final tokenData = await fetchToken(
        baseUrl: CommonEndpoints.baseUrl,
        authToken: token,
        roomName: 'convo_$conversationId',
        callType: isVideo ? 'video' : 'audio',
      );

      final liveKitToken = tokenData['token'] as String;
      final serverUrl = (tokenData['server_url'] ?? tokenData['url']) as String;

      await connectToRoom(
        serverUrl: serverUrl,
        token: liveKitToken,
        enableVideo: isVideo,
        enableAudio: true,
      );
      return true;
    } catch (e) {
      debugPrint('LiveKitCallService: failed to join group call: $e');
      return false;
    }
  }

  /// Toggle Microphone
  Future<void> toggleMicrophone(bool enabled) async {
    await _room?.localParticipant?.setMicrophoneEnabled(enabled);
    _updateParticipants();
  }

  /// Toggle Camera
  Future<void> toggleCamera(bool enabled) async {
    await _room?.localParticipant?.setCameraEnabled(enabled);
    _updateParticipants();
  }

  /// Switch Front/Back Camera
  Future<void> switchCamera() async {
    final track = _room?.localParticipant?.videoTrackPublications.firstOrNull?.track;
    if (track is LocalVideoTrack) {
      final options = track.currentOptions;
      if (options is CameraCaptureOptions) {
        await track.setCameraPosition(options.cameraPosition.switched());
      } else {
        await track.setCameraPosition(CameraPosition.back);
      }
    }
  }

  /// Get active video track from first remote participant with active video
  VideoTrack? getActiveRemoteVideoTrack() {
    if (_room == null) return null;
    for (final participant in _room!.remoteParticipants.values) {
      final pub = participant.videoTrackPublications.firstOrNull;
      if (pub != null && !pub.muted && pub.track is VideoTrack) {
        return pub.track as VideoTrack;
      }
    }
    return null;
  }

  /// Get local participant's video track
  VideoTrack? getLocalVideoTrack() {
    final pub = _room?.localParticipant?.videoTrackPublications.firstOrNull;
    if (pub != null && !pub.muted && pub.track is VideoTrack) {
      return pub.track as VideoTrack;
    }
    return null;
  }

  /// Disconnect and Clean Up
  Future<void> disconnect() async {
    try {
      await _listener?.dispose();
      await _room?.disconnect();
      await _room?.dispose();
    } catch (e) {
      debugPrint('Error disconnecting LiveKit: $e');
    } finally {
      _room = null;
      _listener = null;
      isConnectedNotifier.value = false;
      isConnectingNotifier.value = false;
      participantsNotifier.value = [];
    }
  }
}
