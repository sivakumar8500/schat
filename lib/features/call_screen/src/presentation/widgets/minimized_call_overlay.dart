import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/injection.dart';
import 'package:schat/features/call_screen/src/domain/web_rtc_service.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_bloc.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_event.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_state.dart';
import 'package:schat/features/call_screen/src/presentation/audio_call_page.dart';
import 'package:schat/features/call_screen/src/presentation/video_call_page.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/main.dart';
import 'package:livekit_client/livekit_client.dart' show VideoTrack, VideoTrackRenderer;
import 'package:schat/services/livekit_call_service.dart';

class MinimizedCallOverlay extends StatefulWidget {
  const MinimizedCallOverlay({super.key});

  @override
  State<MinimizedCallOverlay> createState() => _MinimizedCallOverlayState();
}

class _MinimizedCallOverlayState extends State<MinimizedCallOverlay> {
  double? _pipX;
  double? _pipY;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: CallWebRtcBloc.isCallScreenMountedNotifier,
      builder: (context, isCallScreenMounted, _) {
        if (isCallScreenMounted) {
          return const SizedBox.shrink();
        }

        return BlocListener<CallWebRtcBloc, CallWebRtcState>(
          listenWhen: (previous, current) =>
              current is CallEnded || current is CallError || current is CallIdle,
          listener: (context, state) async {
            if (!kIsWeb) {
              try {
                await FlutterCallkitIncoming.endAllCalls();
              } catch (e) {
                debugPrint('MinimizedCallOverlay: endAllCalls failed: $e');
              }
            }
          },
          child: BlocBuilder<CallWebRtcBloc, CallWebRtcState>(
            builder: (context, state) {
              final bool isCallActiveOrConnecting = state is CallActive || state is CallConnecting;
              bool isSystemPip = false;
              bool isMinimized = false;
              if (state is CallActive) {
                isSystemPip = state.isSystemPip;
                isMinimized = state.isMinimized;
              } else if (state is CallConnecting) {
                isSystemPip = state.isSystemPip;
                isMinimized = state.isMinimized;
              }

              if (!isCallActiveOrConnecting || isSystemPip || !isMinimized || isCallScreenMounted) {
                return const SizedBox.shrink();
              }

          final bool isVideo = state is CallActive
              ? state.isVideo
              : (state as CallConnecting).isVideo;
          final String conversationId = state is CallActive
              ? state.conversationId
              : (state as CallConnecting).conversationId;
          final String contactName = state is CallActive
              ? state.contactName
              : (state as CallConnecting).contactName;
          final String recipientId = state is CallActive
              ? state.recipientId
              : (state as CallConnecting).recipientId;
          final String? profilePictureUrl = state is CallActive
              ? state.profilePictureUrl
              : (state as CallConnecting).profilePictureUrl;
          final bool isGroup = state is CallActive
              ? state.isGroup
              : (state as CallConnecting).isGroup;
          final String? groupName = state is CallActive
              ? state.groupName
              : (state as CallConnecting).groupName;
          final List<UserModel> extraParticipants = state is CallActive
              ? state.extraParticipants
              : (state as CallConnecting).extraParticipants;
          final bool isConnected = state is CallActive;
          final bool isRemoteVideoOff = state is CallActive && state.isRemoteVideoOff;
          final bool isLocalVideoOff = state is CallActive ? state.isVideoOff : false;
          final bool isFrontCamera = state is CallActive
              ? state.isFrontCamera
              : (state is CallConnecting ? state.isFrontCamera : true);
          final DateTime? startedAt = state is CallActive
              ? (state.startedAt ?? getIt<CallWebRtcBloc>().activeCallStart ?? DateTime.now())
              : null;

          final webRtcService = getIt<WebRtcService>();
          RTCVideoRenderer? activeRemoteRenderer;
          if (isGroup && webRtcService.peerRenderers.isNotEmpty) {
            for (final r in webRtcService.peerRenderers.values) {
              if (r.srcObject != null) {
                activeRemoteRenderer = r;
                break;
              }
            }
          }
          activeRemoteRenderer ??= webRtcService.remoteRenderer;

          final liveKitService = LiveKitCallService.instance;
          final VideoTrack? liveKitRemoteTrack = (isGroup && liveKitService.isConnected)
              ? liveKitService.getActiveRemoteVideoTrack()
              : null;
          final bool hasLiveKitVideo = isVideo && !isRemoteVideoOff && liveKitRemoteTrack != null;

          final bool hasRemoteVideo = isVideo &&
              isConnected &&
              !isRemoteVideoOff &&
              activeRemoteRenderer.srcObject != null;
          final bool hasLocalVideo = isVideo &&
              !isLocalVideoOff &&
              webRtcService.localRenderer.srcObject != null;

          final String displayName = isGroup
              ? (groupName != null && groupName.isNotEmpty ? groupName : contactName)
              : contactName;

          void onTapAction() {
            context.read<CallWebRtcBloc>().add(const SetCallMinimizedEvent(false));
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<CallWebRtcBloc>(),
                  child: isVideo
                      ? VideoCallPage(
                          conversationId: conversationId,
                          contactName: contactName,
                          contactColor: context.colors.primary,
                          recipientId: recipientId,
                          isOutgoing: false,
                          profilePictureUrl: profilePictureUrl,
                          myProfilePictureUrl:
                              getIt<StorageService>().getProfilePic(),
                          isGroup: isGroup,
                          groupName: groupName,
                          extraParticipants: extraParticipants,
                        )
                      : AudioCallPage(
                          conversationId: conversationId,
                          contactName: contactName,
                          contactColor: context.colors.primary,
                          recipientId: recipientId,
                          isOutgoing: false,
                          profilePictureUrl: profilePictureUrl,
                          myProfilePictureUrl:
                              getIt<StorageService>().getProfilePic(),
                          isGroup: isGroup,
                          groupName: groupName,
                          extraParticipants: extraParticipants,
                        ),
                ),
              ),
            );
          }

          final screenSize = MediaQuery.of(context).size;
          const double pipWidth = 120.0;
          const double pipHeight = 180.0;

          return Positioned(
            top: _pipY ?? 80,
            left: _pipX ?? (screenSize.width - pipWidth - 16),
            child: SafeArea(
              child: Material(
                type: MaterialType.transparency,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _pipX ??= screenSize.width - pipWidth - 16;
                      _pipX = (_pipX! + details.delta.dx)
                          .clamp(0.0, screenSize.width - pipWidth);

                      _pipY ??= 80;
                      _pipY = (_pipY! + details.delta.dy)
                          .clamp(0.0, screenSize.height - pipHeight - 60.0);
                    });
                  },
                  onTap: onTapAction,
                  child: Container(
                    width: pipWidth,
                    height: pipHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF00873C).withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      children: [
                        if (hasLiveKitVideo)
                          Positioned.fill(
                            child: VideoTrackRenderer(
                              liveKitRemoteTrack,
                              fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                            ),
                          )
                        else if (hasRemoteVideo)
                          Positioned.fill(
                            child: RTCVideoView(
                              activeRemoteRenderer,
                              key: ValueKey('overlay_remote_${activeRemoteRenderer.textureId}'),
                              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                              mirror: false,
                            ),
                          )
                        else if (hasLocalVideo)
                          Positioned.fill(
                            child: RTCVideoView(
                              webRtcService.localRenderer,
                              key: ValueKey('overlay_local_${webRtcService.localRenderer.textureId}'),
                              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                              mirror: isFrontCamera,
                            ),
                          )
                        else
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: const Color(0xFF00873C),
                                      backgroundImage: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                                          ? NetworkImage(profilePictureUrl)
                                          : null,
                                      child: (profilePictureUrl == null || profilePictureUrl.isEmpty)
                                          ? (isGroup
                                              ? const Icon(Icons.group, color: Colors.white, size: 24)
                                              : Text(
                                                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    decoration: TextDecoration.none,
                                                  ),
                                                ))
                                          : null,
                                    ),
                                    CommonSpaces.h8,
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                    CommonSpaces.h4,
                                    if (isRemoteVideoOff)
                                      const Text(
                                        'Camera Off',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF94A3B8),
                                          decoration: TextDecoration.none,
                                        ),
                                      )
                                    else if (isConnected && startedAt != null)
                                      _CallTimerText(startedAt: startedAt, color: const Color(0xFF4ADE80))
                                    else
                                      const Text(
                                        'Connecting...',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF94A3B8),
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (isVideo && !isConnected)
                          const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                          ),
                        // Top indicator badge
                        Positioned(
                          top: 6,
                          left: 6,
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
                                  isGroup ? 'Group' : (isConnected ? 'Live' : 'Calling'),
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
                        // End call button on floating window
                        Positioned(
                          bottom: 6,
                          right: 6,
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
                ),
              ),
            ),
          );
        },
      ),
    );
  },
);
}
}

class _CallTimerText extends StatefulWidget {
  final DateTime startedAt;
  final Color? color;
  const _CallTimerText({required this.startedAt, this.color});

  @override
  State<_CallTimerText> createState() => _CallTimerTextState();
}

class _CallTimerTextState extends State<_CallTimerText> {
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
          style: context.bodySmall.copyWith(
            color: widget.color ?? Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.none,
          ),
        );
      },
    );
  }
}
