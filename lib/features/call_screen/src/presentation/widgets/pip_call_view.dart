import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/call_screen/src/domain/web_rtc_service.dart';
import 'package:schat/features/call_screen/src/presentation/audio_call_page.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_bloc.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_event.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_state.dart';
import 'package:schat/features/call_screen/src/presentation/video_call_page.dart';
import 'package:schat/injection.dart';
import 'package:schat/main.dart';

/// Full-frame edge-to-edge PiP view that renders ONLY the active call window.
/// Displays video stream (or caller avatar + duration for audio / camera off calls)
/// without any surrounding scaffold, app bars, or chats.
class PipCallView extends StatelessWidget {
  final CallWebRtcState state;
  const PipCallView({super.key, required this.state});

  void _openFullCallWindow(BuildContext context) {
    try {
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        const MethodChannel('com.sdpi.schat/pip').invokeMethod('exitPip');
      }
    } catch (_) {}

    final bloc = context.read<CallWebRtcBloc>();
    bloc.add(const SetSystemPipModeEvent(false));
    bloc.add(const SetCallMinimizedEvent(false));

    final currentState = bloc.state;
    if (currentState is! CallActive && currentState is! CallConnecting) return;

    final bool isVideo = currentState is CallActive
        ? currentState.isVideo
        : (currentState as CallConnecting).isVideo;
    final String conversationId = currentState is CallActive
        ? currentState.conversationId
        : (currentState as CallConnecting).conversationId;
    final String contactName = currentState is CallActive
        ? currentState.contactName
        : (currentState as CallConnecting).contactName;
    final String recipientId = currentState is CallActive
        ? currentState.recipientId
        : (currentState as CallConnecting).recipientId;
    final String? profilePictureUrl = currentState is CallActive
        ? currentState.profilePictureUrl
        : (currentState as CallConnecting).profilePictureUrl;

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: isVideo
              ? VideoCallPage(
                  conversationId: conversationId,
                  contactName: contactName,
                  contactColor: const Color(0xFF00873C),
                  recipientId: recipientId,
                  isOutgoing: false,
                  profilePictureUrl: profilePictureUrl,
                  myProfilePictureUrl:
                      getIt<StorageService>().getProfilePic(),
                )
              : AudioCallPage(
                  conversationId: conversationId,
                  contactName: contactName,
                  contactColor: const Color(0xFF00873C),
                  recipientId: recipientId,
                  isOutgoing: false,
                  profilePictureUrl: profilePictureUrl,
                  myProfilePictureUrl:
                      getIt<StorageService>().getProfilePic(),
                ),
        ),
      ),
    );
  }

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
    final bool isLocalVideoOff =
        state is CallActive ? (state as CallActive).isVideoOff : false;
    final bool isFrontCamera = state is CallActive
        ? (state as CallActive).isFrontCamera
        : (state is CallConnecting
            ? (state as CallConnecting).isFrontCamera
            : true);
    final DateTime? startedAt = state is CallActive
        ? ((state as CallActive).startedAt ??
            getIt<CallWebRtcBloc>().activeCallStart ??
            DateTime.now())
        : null;

    final webRtcService = getIt<WebRtcService>();
    final bool hasRemoteVideo = isVideo &&
        isConnected &&
        !isRemoteVideoOff &&
        webRtcService.remoteRenderer.srcObject != null;
    final bool hasLocalVideo = isVideo &&
        !isLocalVideoOff &&
        webRtcService.localRenderer.srcObject != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openFullCallWindow(context),
      child: Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
          // ─── Main Content (Video or Audio Call Card) ───
          if (hasRemoteVideo)
            Positioned.fill(
              child: RTCVideoView(
                webRtcService.remoteRenderer,
                key: ValueKey('pip_remote_${webRtcService.remoteRenderer.textureId}'),
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                mirror: false,
              ),
            )
          else if (hasLocalVideo)
            Positioned.fill(
              child: RTCVideoView(
                webRtcService.localRenderer,
                key: ValueKey('pip_local_main_${webRtcService.localRenderer.textureId}'),
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                mirror: isFrontCamera,
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
                        radius: 30,
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
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          contactName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (isRemoteVideoOff && isConnected)
                        const Text(
                          'Camera Off',
                          style: TextStyle(
                            fontSize: 10,
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
                            fontSize: 10,
                            color: Colors.white70,
                            decoration: TextDecoration.none,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // ─── Local Video Inset (when remote is active) ───
          if (hasRemoteVideo && hasLocalVideo)
            Positioned(
              bottom: 8,
              left: 8,
              width: 36,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white54, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: RTCVideoView(
                  webRtcService.localRenderer,
                  key: ValueKey('pip_local_inset_${webRtcService.localRenderer.textureId}'),
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  mirror: isFrontCamera,
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
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_end,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
          ),
        ],
      ),
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
