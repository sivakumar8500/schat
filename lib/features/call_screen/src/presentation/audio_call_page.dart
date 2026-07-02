// mason make page --name audio_call
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_bloc.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_event.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_state.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';

/// 1-to-1 Audio Call Page — wired to WebRTC via CallWebRtcBloc.
/// mason make page --name audio_call
class AudioCallPage extends StatefulWidget {
  final String conversationId;
  final String contactName;
  final Color contactColor;
  final String recipientId;
  final bool isOutgoing;
  final String? profilePictureUrl;
  final String? myProfilePictureUrl;

  const AudioCallPage({
    super.key,
    required this.conversationId,
    required this.contactName,
    required this.contactColor,
    required this.recipientId,
    this.isOutgoing = true,
    this.profilePictureUrl,
    this.myProfilePictureUrl,
  });

  @override
  State<AudioCallPage> createState() => _AudioCallPageState();
}

class _AudioCallPageState extends State<AudioCallPage>
    with TickerProviderStateMixin {
  int _seconds = 0;
  Timer? _timer;

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _ring1Controller;
  late AnimationController _ring2Controller;
  late AnimationController _ring3Controller;
  late Animation<double> _ring1;
  late Animation<double> _ring2;
  late Animation<double> _ring3;

  @override
  void initState() {
    super.initState();
    _setupAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CallWebRtcBloc>().add(const SetCallMinimizedEvent(false));
      // If outgoing call, initiate WebRTC
      if (widget.isOutgoing) {
        context.read<CallWebRtcBloc>().add(InitiateCallEvent(
          conversationId: widget.conversationId,
          isVideo: false,
          contactName: widget.contactName,
          profilePictureUrl: widget.profilePictureUrl,
        ));
      }
    });
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _ring1Controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _ring2Controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _ring3Controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _ring2Controller.value = 0.25;
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _ring3Controller.value = 0.5;
    });

    _ring1 = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ring1Controller, curve: Curves.easeOut));
    _ring2 = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ring2Controller, curve: Curves.easeOut));
    _ring3 = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ring3Controller, curve: Curves.easeOut));
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _ring1Controller.dispose();
    _ring2Controller.dispose();
    _ring3Controller.dispose();
    
    // Notify bloc that page is being closed (minimized if call still active)
    try {
      final bloc = getIt<CallWebRtcBloc>();
      if (bloc.state is CallActive || bloc.state is CallConnecting) {
        bloc.add(const SetCallMinimizedEvent(true));
      }
    } catch (e) {
      debugPrint('Error setting minimized state in dispose: $e');
    }

    super.dispose();
  }

  String get _formattedTime {
    final int minutes = _seconds ~/ 60;
    final int remainingSeconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _statusLabel(CallWebRtcState state) {
    if (state is CallConnecting) return 'Calling...';
    if (state is CallActive) return _formattedTime;
    if (state is CallEnded) return 'Call Ended';
    if (state is CallRejected) return state.reason;
    if (state is CallError) return 'Connection Error';
    return 'Ringing...';
  }

  void _onHangUp(BuildContext context) {
    context.read<CallWebRtcBloc>().add(HangUpCallEvent(widget.conversationId));
    Navigator.of(context).pop();
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
          final isSpeaker = state is CallActive ? state.isSpeakerOn : false;

          return Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFF0FDF4),
                    widget.contactColor.withValues(alpha: 0.08),
                    const Color(0xFFE8F5E9),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // ─── Header ───
                    _buildHeader(context),
                    
                    const Spacer(),

                    // ─── Avatar with ripple rings + Name & Status ───
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 300,
                          height: 300,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _ring1,
                                builder: (_, _) => _buildRing(_ring1.value),
                              ),
                              AnimatedBuilder(
                                animation: _ring2,
                                builder: (_, _) => _buildRing(_ring2.value),
                              ),
                              AnimatedBuilder(
                                animation: _ring3,
                                builder: (_, _) => _buildRing(_ring3.value),
                              ),
                              ScaleTransition(
                                scale: _pulseAnimation,
                                child: Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: widget.contactColor.withValues(alpha: 0.18),
                                    border: Border.all(
                                      color: widget.contactColor.withValues(alpha: 0.5),
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.contactColor.withValues(alpha: 0.3),
                                        blurRadius: 40,
                                        spreadRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: (widget.profilePictureUrl != null &&
                                            widget.profilePictureUrl!.isNotEmpty)
                                        ? ClipOval(
                                            child: Image.network(
                                              widget.profilePictureUrl!,
                                              width: 160,
                                              height: 160,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Text(
                                                widget.contactName
                                                    .substring(0, 1)
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 72,
                                                  fontWeight: FontWeight.bold,
                                                  color: widget.contactColor,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Text(
                                            widget.contactName
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 72,
                                              fontWeight: FontWeight.bold,
                                              color: widget.contactColor,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              // Active speaking wave bars
                              if (state is CallActive)
                                Positioned(
                                  bottom: 60,
                                  child: _buildSpeakingIndicator(),
                                ),
                            ],
                          ),
                        ),
                        CommonSpaces.h24,
                        Text(
                          state is CallActive ? state.contactName : widget.contactName,
                          textAlign: TextAlign.center,
                          style: context.h2.copyWith(
                            fontSize: 32,
                            color: const Color(0xFF1A1A1A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        CommonSpaces.h8,
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Column(
                            key: ValueKey(_statusLabel(state)),
                            children: [
                              Text(
                                _statusLabel(state),
                                textAlign: TextAlign.center,
                                style: context.titleMedium.copyWith(
                                  color: state is CallActive
                                      ? const Color(0xFF34C759)
                                      : Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (state is CallActive && state.isRemoteMuted)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(CommonIcons.micOff,
                                          size: 14, color: Colors.redAccent),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Muted',
                                        style: context.bodySmall.copyWith(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // ─── Dark Pill Control Bar ───
                    _buildControlBar(context, isMuted, isSpeaker),
                    CommonSpaces.h32,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.black54, size: 26),
            ),
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(CommonIcons.addCall,
                color: Colors.black54, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildRing(double progress) {
    return Opacity(
      opacity: (1 - progress).clamp(0.0, 0.6),
      child: Container(
        width: 160 + (120 * progress),
        height: 160 + (120 * progress),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.contactColor.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSpeakingIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 4, end: 16),
          duration: Duration(milliseconds: 300 + (i * 80)),
          builder: (_, h, _) => Container(
            width: 4,
            height: h,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF34C759),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildControlBar(BuildContext context, bool isMuted, bool isSpeaker) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // More
          _buildPillButton(
            icon: CommonIcons.moreHoriz,
            isActive: false,
            onTap: () {},
          ),
          // Camera (switch to video)
          _buildPillButton(
            icon: CommonIcons.videocam,
            isActive: false,
            onTap: () {},
          ),
          // Speaker — green when active
          _buildPillButton(
            icon: isSpeaker ? CommonIcons.volumeUp : CommonIcons.volumeDown,
            isActive: true,
            activeColor: const Color(0xFF34C759),
            onTap: () => context
                .read<CallWebRtcBloc>()
                .add(const ToggleSpeakerCallEvent()),
          ),
          // Mute
          _buildPillButton(
            icon: isMuted ? CommonIcons.micOff : CommonIcons.mic,
            isActive: isMuted,
            onTap: () =>
                context.read<CallWebRtcBloc>().add(const ToggleMuteCallEvent()),
          ),
          // End call
          _buildPillButton(
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

  Widget _buildPillButton({
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
