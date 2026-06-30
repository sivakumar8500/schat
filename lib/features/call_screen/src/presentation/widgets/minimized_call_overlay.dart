import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_bloc.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_state.dart';
import 'package:schat/features/call_screen/src/presentation/audio_call_page.dart';
import 'package:schat/features/call_screen/src/presentation/video_call_page.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/main.dart';

class MinimizedCallOverlay extends StatelessWidget {
  const MinimizedCallOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CallWebRtcBloc, CallWebRtcState>(
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

        final bool isVideo = state is CallActive ? state.isVideo : (state as CallConnecting).isVideo;
        final String conversationId = state is CallActive ? state.conversationId : (state as CallConnecting).conversationId;
        final String contactName = state is CallActive ? state.contactName : (state as CallConnecting).contactName;
        final String recipientId = state is CallActive ? state.recipientId : (state as CallConnecting).recipientId;

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 400),
                tween: Tween(begin: -100.0, end: 0.0),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, value),
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTap: () {
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
                                )
                              : AudioCallPage(
                                  conversationId: conversationId,
                                  contactName: contactName,
                                  contactColor: context.colors.primary,
                                  recipientId: recipientId,
                                  isOutgoing: false,
                                ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: context.colors.success,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _PulsingIcon(isVideo: isVideo),
                        CommonSpaces.w12,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Ongoing ${isVideo ? 'Video' : 'Audio'} Call',
                                style: context.bodySmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                contactName,
                                style: context.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.touch_app_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  final bool isVideo;
  const _PulsingIcon({required this.isVideo});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.9, end: 1.1).animate(_controller),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
        ),
        child: Icon(
          widget.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
