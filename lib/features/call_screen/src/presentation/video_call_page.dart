// mason make page --name video_call
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:schat/features/call_screen/src/domain/web_rtc_service.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_bloc.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_event.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_state.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_icons.dart';

/// 1-to-1 Video Call Page — renders real RTCVideoView for remote and local streams.
/// mason make page --name video_call
class VideoCallPage extends StatefulWidget {
  final String conversationId;
  final String contactName;
  final Color contactColor;
  final String recipientId;
  final bool isOutgoing;

  const VideoCallPage({
    super.key,
    required this.conversationId,
    required this.contactName,
    required this.contactColor,
    required this.recipientId,
    this.isOutgoing = true,
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage>
    with TickerProviderStateMixin {
  final WebRtcService _webRtcService = getIt<WebRtcService>();
  int _seconds = 0;
  Timer? _timer;

  late AnimationController _fadeController;
  bool _controlsVisible = true;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );

    if (widget.isOutgoing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<CallWebRtcBloc>().add(InitiateCallEvent(
          conversationId: widget.conversationId,
          isVideo: true,
        ));
      });
    }

    _scheduleControlsHide();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _seconds++);
    });
  }

  void _scheduleControlsHide() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _controlsVisible = false);
        _fadeController.reverse();
      }
    });
  }

  void _showControls() {
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _fadeController.forward();
    _scheduleControlsHide();
  }

  String get _formattedTime {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _onHangUp(BuildContext context) {
    context.read<CallWebRtcBloc>().add(HangUpCallEvent(widget.conversationId));
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controlsTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CallWebRtcBloc, CallWebRtcState>(
      listener: (context, state) {
        if (state is CallActive && _timer == null) {
          _startTimer();
        }
        if (state is CallEnded || state is CallRejected) {
          Navigator.of(context).maybePop();
        }
      },
      child: BlocBuilder<CallWebRtcBloc, CallWebRtcState>(
        builder: (context, state) {
          final isMuted = state is CallActive ? state.isMuted : false;
          final isVideoOff = state is CallActive ? state.isVideoOff : false;

          return Scaffold(
            backgroundColor: Colors.black,
            body: GestureDetector(
              onTap: _showControls,
              child: Stack(
                children: [
                  // ─── Remote Video (Full Screen) ───
                  Positioned.fill(
                    child: state is CallActive
                        ? RTCVideoView(
                            _webRtcService.remoteRenderer,
                            objectFit: RTCVideoViewObjectFit
                                .RTCVideoViewObjectFitCover,
                            mirror: false,
                          )
                        : _buildWaitingScreen(),
                  ),

                  // ─── Gradient overlays ───
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: [
                            Colors.black.withValues(alpha: 0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ─── Top Header (fades) ───
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: FadeTransition(
                      opacity: _fadeController,
                      child: _buildTopHeader(context, state),
                    ),
                  ),

                  // ─── Top Right Buttons ───
                  Positioned(
                    top: 80,
                    right: 16,
                    child: FadeTransition(
                      opacity: _fadeController,
                      child: _buildTopRightButtons(context),
                    ),
                  ),

                  // ─── Local Video PiP ───
                  _buildLocalVideoPiP(isVideoOff),

                  // ─── Bottom Control Bar ───
                  Positioned(
                    bottom: 40,
                    left: 24,
                    right: 24,
                    child: FadeTransition(
                      opacity: _fadeController,
                      child: _buildControlBar(context, isMuted, isVideoOff, state),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C3E50), Color(0xFF000000)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: widget.contactColor.withValues(alpha: 0.2),
              child: Text(
                widget.contactName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: widget.contactColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white54,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, CallWebRtcState state) {
    final statusText = state is CallActive
        ? _formattedTime
        : state is CallConnecting
            ? 'Calling...'
            : 'Ringing';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            Text(
              widget.contactName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              statusText,
              style: TextStyle(
                color: state is CallActive
                    ? const Color(0xFF34C759)
                    : Colors.white70,
                fontSize: 14,
                shadows: const [Shadow(color: Colors.black45, blurRadius: 6)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRightButtons(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildFrostedButton(
            icon: CommonIcons.addCall,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildFrostedButton(
            icon: CommonIcons.flipCamera,
            onTap: () => context
                .read<CallWebRtcBloc>()
                .add(const SwitchCameraCallEvent()),
          ),
        ],
      ),
    );
  }

  Widget _buildFrostedButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildLocalVideoPiP(bool isVideoOff) {
    return Positioned(
      top: 80,
      right: 72,
      child: SafeArea(
        child: Container(
          width: 110,
          height: 160,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: isVideoOff
                ? Container(
                    color: Colors.black87,
                    child: const Center(
                      child: Icon(CommonIcons.videocamOff,
                          color: Colors.white54, size: 32),
                    ),
                  )
                : RTCVideoView(
                    _webRtcService.localRenderer,
                    mirror: true,
                    objectFit:
                        RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlBar(BuildContext context, bool isMuted, bool isVideoOff,
      CallWebRtcState state) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBarButton(
            icon: CommonIcons.moreHoriz,
            isActive: false,
            onTap: () {},
          ),
          _buildBarButton(
            icon: isVideoOff ? CommonIcons.videocamOff : CommonIcons.videocam,
            isActive: isVideoOff,
            onTap: () => context
                .read<CallWebRtcBloc>()
                .add(const ToggleCameraCallEvent()),
          ),
          _buildBarButton(
            icon: CommonIcons.volumeUp,
            isActive: true,
            activeColor: const Color(0xFF34C759),
            onTap: () => context
                .read<CallWebRtcBloc>()
                .add(const ToggleSpeakerCallEvent()),
          ),
          _buildBarButton(
            icon: isMuted ? CommonIcons.micOff : CommonIcons.mic,
            isActive: isMuted,
            onTap: () => context
                .read<CallWebRtcBloc>()
                .add(const ToggleMuteCallEvent()),
          ),
          _buildBarButton(
            icon: CommonIcons.callEnd,
            isActive: true,
            activeColor: const Color(0xFFFF3B30),
            size: 56,
            onTap: () => _onHangUp(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBarButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    Color? activeColor,
    double size = 48,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isActive
              ? (activeColor ?? const Color(0xFF3A3A3C))
              : const Color(0xFF3A3A3C),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.42),
      ),
    );
  }
}
