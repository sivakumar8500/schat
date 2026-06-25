// mason make widget --name incoming_call_dialog
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_bloc.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_event.dart';
import 'package:schat/features/call_screen/src/presentation/audio_call_page.dart';
import 'package:schat/features/call_screen/src/presentation/video_call_page.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';

/// Full-screen incoming call dialog shown when `call_incoming` is received.
/// mason make widget --name incoming_call_dialog
class IncomingCallDialog extends StatefulWidget {
  final Map<String, dynamic> incomingEvent;
  final String callerName;
  final Color callerColor;
  final bool isVideo;
  final String conversationId;
  final String recipientId;

  const IncomingCallDialog({
    super.key,
    required this.incomingEvent,
    required this.callerName,
    required this.callerColor,
    required this.isVideo,
    required this.conversationId,
    required this.recipientId,
  });

  @override
  State<IncomingCallDialog> createState() => _IncomingCallDialogState();
}

class _IncomingCallDialogState extends State<IncomingCallDialog>
    with TickerProviderStateMixin {
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

    // Avatar pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Ripple rings
    _ring1Controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _ring2Controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _ring3Controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _ring2Controller.value = 0.22;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _ring3Controller.value = 0.44;
    });

    _ring1 = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ring1Controller, curve: Curves.easeOut));
    _ring2 = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ring2Controller, curve: Curves.easeOut));
    _ring3 = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ring3Controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ring1Controller.dispose();
    _ring2Controller.dispose();
    _ring3Controller.dispose();
    super.dispose();
  }

  void _accept(BuildContext context) {
    context.read<CallWebRtcBloc>().add(AnswerCallEvent(widget.incomingEvent));
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CallWebRtcBloc>(),
          child: widget.isVideo
              ? VideoCallPage(
                  conversationId: widget.conversationId,
                  contactName: widget.callerName,
                  contactColor: widget.callerColor,
                  recipientId: widget.recipientId,
                  isOutgoing: false,
                )
              : AudioCallPage(
                  conversationId: widget.conversationId,
                  contactName: widget.callerName,
                  contactColor: widget.callerColor,
                  recipientId: widget.recipientId,
                  isOutgoing: false,
                ),
        ),
      ),
    );
  }

  void _decline(BuildContext context) {
    context
        .read<CallWebRtcBloc>()
        .add(RejectCallEvent(widget.conversationId));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
              const Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              CommonSpaces.h60,

              // Call type label
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isVideo
                          ? CommonIcons.videocam
                          : CommonIcons.phone,
                      color: Colors.white70,
                      size: 16,
                    ),
                    CommonSpaces.w8,
                    Text(
                      widget.isVideo ? 'Incoming Video Call' : 'Incoming Audio Call',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              CommonSpaces.h24,

              // Caller name
              Text(
                widget.callerName,
                style: context.h2.copyWith(
                  fontSize: 34,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              CommonSpaces.h8,
              Text(
                'is calling you...',
                style: context.titleMedium.copyWith(
                  color: Colors.white60,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const Spacer(),

              // Avatar with ripple rings
              SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ripple ring 1
                    AnimatedBuilder(
                      animation: _ring1,
                      builder: (_, __) => _buildRing(_ring1.value),
                    ),
                    // Ripple ring 2
                    AnimatedBuilder(
                      animation: _ring2,
                      builder: (_, __) => _buildRing(_ring2.value),
                    ),
                    // Ripple ring 3
                    AnimatedBuilder(
                      animation: _ring3,
                      builder: (_, __) => _buildRing(_ring3.value),
                    ),
                    // Avatar
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.callerColor.withValues(alpha: 0.25),
                          border: Border.all(
                              color: widget.callerColor.withValues(alpha: 0.6),
                              width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: widget.callerColor.withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.callerName.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              color: widget.callerColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Accept / Decline buttons
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Decline
                    _buildCallButton(
                      icon: CommonIcons.callEnd,
                      color: const Color(0xFFFF3B30),
                      label: 'Decline',
                      onTap: () => _decline(context),
                    ),

                    // Accept
                    _buildCallButton(
                      icon: widget.isVideo
                          ? CommonIcons.videocam
                          : CommonIcons.phone,
                      color: const Color(0xFF34C759),
                      label: 'Accept',
                      onTap: () => _accept(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRing(double progress) {
    return Opacity(
      opacity: (1 - progress).clamp(0.0, 1.0),
      child: Container(
        width: 140 + (130 * progress),
        height: 140 + (130 * progress),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.callerColor.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          CommonSpaces.h12,
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
