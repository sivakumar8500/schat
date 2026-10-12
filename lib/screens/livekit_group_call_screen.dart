import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../features/call_screen/src/domain/call_sound_service.dart';
import '../features/call_screen/src/presentation/bloc/call_webrtc_bloc.dart';
import '../features/call_screen/src/presentation/bloc/call_webrtc_event.dart';
import '../injection.dart';
import '../services/livekit_call_service.dart';

class LiveKitGroupCallScreen extends StatefulWidget {
  final String apiBaseUrl;
  final String authToken;
  final String roomName;
  final String groupTitle;
  final bool isVideoCall;

  const LiveKitGroupCallScreen({
    super.key,
    required this.apiBaseUrl,
    required this.authToken,
    required this.roomName,
    required this.groupTitle,
    this.isVideoCall = true,
  });

  @override
  State<LiveKitGroupCallScreen> createState() => _LiveKitGroupCallScreenState();
}

class _LiveKitGroupCallScreenState extends State<LiveKitGroupCallScreen> {
  final LiveKitCallService _callService = LiveKitCallService();
  Room? _room;
  EventsListener<RoomEvent>? _listener;

  bool _isConnecting = true;
  String? _errorMessage;

  bool _isMicMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;

  List<Participant> _participants = [];

  @override
  void initState() {
    super.initState();
    _isCameraOff = !widget.isVideoCall;
    try {
      if (getIt.isRegistered<CallSoundService>()) {
        getIt<CallSoundService>().stopAll();
      }
    } catch (_) {}
    try {
      WakelockPlus.enable();
    } catch (_) {}
    _initCall();
  }

  Future<void> _initCall() async {
    try {
      // 1. Request permissions
      final hasPermission = await _callService.requestPermissions(
        isVideo: widget.isVideoCall,
      );
      if (!hasPermission) {
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _errorMessage = 'Microphone and Camera permissions are required.';
          });
        }
        return;
      }

      // 2. Fetch Token from FastAPI
      final tokenData = await _callService.fetchToken(
        baseUrl: widget.apiBaseUrl,
        authToken: widget.authToken,
        roomName: widget.roomName,
        callType: widget.isVideoCall ? 'video' : 'audio',
      );

      final token = tokenData['token'] as String;
      final serverUrl = (tokenData['server_url'] ?? tokenData['url']) as String;

      // 3. Connect to LiveKit Room
      final room = await _callService.connectToRoom(
        serverUrl: serverUrl,
        token: token,
        enableVideo: widget.isVideoCall,
        enableAudio: true,
      );

      if (!mounted) return;

      _room = room;
      _listener = room.createListener();

      _setupListeners();
      _updateParticipants();

      // Enable speakerphone by default for group calls
      try {
        await Hardware.instance.setSpeakerphoneOn(_isSpeakerOn);
      } catch (e) {
        debugPrint('LiveKit: Error setting speakerphone: $e');
      }

      setState(() {
        _isConnecting = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _errorMessage = e.toString();
        });
      }
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
      ..on<TrackMutedEvent>((_) => setState(() {}))
      ..on<TrackUnmutedEvent>((_) => setState(() {}))
      ..on<ActiveSpeakersChangedEvent>((_) => setState(() {}));
  }

  void _updateParticipants() {
    if (_room == null || !mounted) return;
    final list = <Participant>[];
    if (_room!.localParticipant != null) {
      list.add(_room!.localParticipant!);
    }
    list.addAll(_room!.remoteParticipants.values);
    setState(() {
      _participants = list;
    });
  }

  Future<void> _toggleMic() async {
    final newMute = !_isMicMuted;
    await _callService.toggleMicrophone(!newMute);
    if (mounted) {
      setState(() {
        _isMicMuted = newMute;
      });
    }
  }

  Future<void> _toggleCamera() async {
    final newOff = !_isCameraOff;
    await _callService.toggleCamera(!newOff);
    if (mounted) {
      setState(() {
        _isCameraOff = newOff;
      });
    }
  }

  Future<void> _toggleSpeaker() async {
    final newSpeaker = !_isSpeakerOn;
    try {
      await Hardware.instance.setSpeakerphoneOn(newSpeaker);
      if (mounted) {
        setState(() {
          _isSpeakerOn = newSpeaker;
        });
      }
    } catch (e) {
      debugPrint('LiveKit: Toggle speaker error: $e');
    }
  }

  Future<void> _hangUp() async {
    try {
      if (getIt.isRegistered<CallWebRtcBloc>()) {
        final convoId = widget.roomName.startsWith('convo_')
            ? widget.roomName.substring('convo_'.length)
            : widget.roomName;
        getIt<CallWebRtcBloc>().add(HangUpCallEvent(convoId));
      }
    } catch (_) {}
    try {
      WakelockPlus.disable();
    } catch (_) {}
    await _callService.disconnect();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    try {
      WakelockPlus.disable();
    } catch (_) {}
    _callService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnecting) {
      return Scaffold(
        backgroundColor: const Color(0xFF121826),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.tealAccent),
              const SizedBox(height: 20),
              Text(
                'Connecting to ${widget.groupTitle}...',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121826),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.groupTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_participants.length} connected',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (widget.isVideoCall && !_isCameraOff)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: _callService.switchCamera,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildParticipantGrid()),
            _buildControlBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantGrid() {
    final count = _participants.length;
    if (count == 0) {
      return const Center(
        child: Text(
          'Waiting for members...',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    int crossAxisCount = 1;
    if (count == 2) {
      crossAxisCount = 1;
    } else if (count <= 4) {
      crossAxisCount = 2;
    } else if (count <= 9) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 4;
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: _participants.length,
        itemBuilder: (context, index) {
          final participant = _participants[index];
          return _buildParticipantTile(participant);
        },
      ),
    );
  }

  Widget _buildParticipantTile(Participant participant) {
    final isSpeaking = participant.isSpeaking;
    final name = (participant.name.isNotEmpty) ? participant.name : participant.identity;

    // Get video track publication
    final videoPub = participant.videoTrackPublications.firstOrNull;
    final hasVideo = videoPub != null && !videoPub.muted && videoPub.track != null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSpeaking ? Colors.tealAccent : Colors.white10,
          width: isSpeaking ? 3 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (hasVideo && videoPub.track is VideoTrack)
            VideoTrackRenderer(
              videoPub.track as VideoTrack,
              fit: rtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          else
            Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: Colors.teal.withValues(alpha: 0.3),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.tealAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    participant.isMuted ? Icons.mic_off : Icons.mic,
                    size: 14,
                    color: participant.isMuted ? Colors.redAccent : Colors.tealAccent,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      participant is LocalParticipant ? 'You' : name,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mic Toggle
          IconButton(
            icon: Icon(_isMicMuted ? Icons.mic_off : Icons.mic),
            color: _isMicMuted ? Colors.redAccent : Colors.white,
            iconSize: 28,
            onPressed: _toggleMic,
          ),
          // Speaker Toggle
          IconButton(
            icon: Icon(_isSpeakerOn ? Icons.volume_up : Icons.volume_down),
            color: _isSpeakerOn ? Colors.tealAccent : Colors.white,
            iconSize: 28,
            onPressed: _toggleSpeaker,
          ),
          // Camera Toggle
          if (widget.isVideoCall)
            IconButton(
              icon: Icon(_isCameraOff ? Icons.videocam_off : Icons.videocam),
              color: _isCameraOff ? Colors.redAccent : Colors.white,
              iconSize: 28,
              onPressed: _toggleCamera,
            ),
          // Hangup Button
          FloatingActionButton(
            backgroundColor: Colors.redAccent,
            onPressed: _hangUp,
            child: const Icon(Icons.call_end, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
