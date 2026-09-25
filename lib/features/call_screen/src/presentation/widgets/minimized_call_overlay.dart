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
import 'package:schat/main.dart';

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
          bool isMinimized = false;
          if (state is CallActive) {
            isMinimized = state.isMinimized;
          } else if (state is CallConnecting) {
            isMinimized = state.isMinimized;
          }

          if (!isMinimized) {
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
          final DateTime? startedAt = state is CallActive
              ? state.startedAt
              : null;

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
                        ),
                ),
              ),
            );
          }

          return Positioned(
            top: _pipY ?? 80,
            left: _pipX,
            right: _pipX == null ? 16 : null,
            child: SafeArea(
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _pipX ??= MediaQuery.of(context).size.width - 16 - 120;
                    _pipX = (_pipX! + details.delta.dx)
                        .clamp(0.0, MediaQuery.of(context).size.width - 120.0);

                    _pipY ??= 80;
                    _pipY = (_pipY! + details.delta.dy)
                        .clamp(0.0, MediaQuery.of(context).size.height - 180.0);
                  });
                },
                onTap: onTapAction,
                child: Container(
                  width: 120,
                  height: 180,
                  decoration: BoxDecoration(
                    color: context.colors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF00873C).withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    children: [
                      if (isVideo)
                        RTCVideoView(
                          getIt<WebRtcService>().remoteRenderer,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          mirror: false,
                        )
                      else
                        Container(
                          color: context.colors.primary.withValues(alpha: 0.12),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: context.colors.primary,
                                  backgroundImage: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                                      ? NetworkImage(profilePictureUrl)
                                      : null,
                                  child: (profilePictureUrl == null || profilePictureUrl.isEmpty)
                                      ? Text(
                                          contactName.isNotEmpty ? contactName[0].toUpperCase() : '?',
                                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                        )
                                      : null,
                                ),
                                CommonSpaces.h8,
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    contactName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.bodySmall.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: context.colors.textPrimary,
                                    ),
                                  ),
                                ),
                                CommonSpaces.h4,
                                if (startedAt != null)
                                  _CallTimerText(startedAt: startedAt, color: const Color(0xFF00873C))
                                else
                                  Text(
                                    'Connecting...',
                                    style: context.bodySmall.copyWith(
                                      fontSize: 10,
                                      color: context.colors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      if (isVideo && startedAt == null)
                        const Center(
                          child: CircularProgressIndicator(color: Colors.white),
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
                              const Text(
                                'Live',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
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
          );
        },
      ),
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
          ),
        );
      },
    );
  }
}
