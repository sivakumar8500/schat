import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:schat/features/call_screen/src/domain/web_rtc_service.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_bloc.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_event.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_state.dart';
import 'package:schat/injection.dart';

/// Full-frame edge-to-edge PiP view that renders ONLY the active call window.
/// Displays video stream (or caller avatar + duration for audio / camera off calls)
/// without any surrounding scaffold, app bars, or chats.
class PipCallView extends StatelessWidget {
  final CallWebRtcState state;
  const PipCallView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state is! CallActive && state is! CallConnecting) {
      return const SizedBox.shrink();
    }

    final bool isVideo = state is CallActive
        ? (state as CallActive).isVideo
        : (state as CallConnecting).isVideo;
    final String conversationId = state is CallActive
        ? (state as CallActive).conversationId
        : (state as CallConnecting).conversationId;
    final String contactName = state is CallActive
        ? (state as CallActive).contactName
        : (state as CallConnecting).contactName;
    final String? profilePictureUrl = state is CallActive
        ? (state as CallActive).profilePictureUrl
        : (state as CallConnecting).profilePictureUrl;
    final bool isConnected = state is CallActive;
    final bool isRemoteVideoOff =
        state is CallActive && (state as CallActive).isRemoteVideoOff;
    final DateTime? startedAt = state is CallActive
        ? ((state as CallActive).startedAt ??
            getIt<CallWebRtcBloc>().activeCallStart ??
            DateTime.now())
        : null;

    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Main Content (Video or Audio Call Card) ───
          if (isVideo && isConnected && !isRemoteVideoOff)
            Positioned.fill(
              child: RTCVideoView(
                getIt<WebRtcService>().remoteRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                mirror: false,
              ),
            )
          else
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0F2027),
                      Color(0xFF203A43),
                      Color(0xFF2C5364),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: const Color(0xFF00873C),
                        backgroundImage: profilePictureUrl != null &&
                                profilePictureUrl.isNotEmpty
                            ? NetworkImage(profilePictureUrl)
                            : null,
                        child: (profilePictureUrl == null ||
                                profilePictureUrl.isEmpty)
                            ? Text(
                                contactName.isNotEmpty
                                    ? contactName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          contactName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isRemoteVideoOff)
                        const Text(
                          'Camera Off',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                            decoration: TextDecoration.none,
                          ),
                        )
                      else if (isConnected && startedAt != null)
                        _PipCallTimerText(startedAt: startedAt)
                      else
                        const Text(
                          'Connecting...',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                            decoration: TextDecoration.none,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // ─── Top Live / Calling Indicator Badge ───
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF00873C).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isVideo ? Icons.videocam : Icons.call,
                    color: Colors.white,
                    size: 10,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    isConnected ? 'Live' : 'Calling',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── End Call Button ───
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                context.read<CallWebRtcBloc>().add(HangUpCallEvent(conversationId));
              },
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_end,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PipCallTimerText extends StatefulWidget {
  final DateTime startedAt;
  const _PipCallTimerText({required this.startedAt});

  @override
  State<_PipCallTimerText> createState() => _PipCallTimerTextState();
}

class _PipCallTimerTextState extends State<_PipCallTimerText> {
  late Stream<int> _timerStream;

  @override
  void initState() {
    super.initState();
    _timerStream = Stream.periodic(const Duration(seconds: 1), (i) => i);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _timerStream,
      builder: (context, snapshot) {
        final duration = DateTime.now().difference(widget.startedAt);
        return Text(
          _formatDuration(duration),
          style: const TextStyle(
            color: Color(0xFF00FF87),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        );
      },
    );
  }
}
