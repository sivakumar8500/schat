// mason make widget --name incoming_call_dialog
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/injection.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_bloc.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_event.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_state.dart';
import 'package:schat/features/call_screen/src/presentation/audio_call_page.dart';
import 'package:schat/features/call_screen/src/presentation/video_call_page.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/permission_helper.dart';
import 'package:schat/utils/common_notifications.dart';

/// Full-screen incoming call dialog shown when `call_incoming` is received.
/// mason make widget --name incoming_call_dialog
class IncomingCallDialog extends StatefulWidget {
  final Map<String, dynamic> incomingEvent;
  final String callerName;
  final Color callerColor;
  final bool isVideo;
  final String conversationId;
  final String recipientId;
  final String? profilePictureUrl;

  const IncomingCallDialog({
    super.key,
    required this.incomingEvent,
    required this.callerName,
    required this.callerColor,
    required this.isVideo,
    required this.conversationId,
    required this.recipientId,
    this.profilePictureUrl,
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

  void _accept(BuildContext context) async {
    final hasPermission = await PermissionHelper.checkCallPermissions(isVideo: widget.isVideo);
    if (!hasPermission) {
      if (mounted) {
        context.showErrorNotification(widget.isVideo 
            ? 'Camera and Microphone permissions are required for video calls'
            : 'Microphone permission is required for audio calls');
      }
      return;
    }
    
    if (!mounted) return;
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
                  profilePictureUrl: widget.profilePictureUrl,
                  myProfilePictureUrl: getIt<StorageService>().getProfilePic(),
                )
              : AudioCallPage(
                  conversationId: widget.conversationId,
                  contactName: widget.callerName,
                  contactColor: widget.callerColor,
                  recipientId: widget.recipientId,
                  isOutgoing: false,
                  profilePictureUrl: widget.profilePictureUrl,
                  myProfilePictureUrl: getIt<StorageService>().getProfilePic(),
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

  /// Called when the caller cancels before the callee answers.
  void _onCallerHungUp(BuildContext context) {
    // Stop ringtone
    context.read<CallWebRtcBloc>(); // ensure bloc is available
    // Dismiss the CallKit / system notification if any
    FlutterCallkitIncoming.endAllCalls();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CallWebRtcBloc, CallWebRtcState>(
      listenWhen: (previous, current) {
        // Dismiss if call ended / errored while we are still ringing
        return current is CallEnded ||
            current is CallError ||
            current is CallIdle;
      },
      listener: (context, state) {
        _onCallerHungUp(context);
      },
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: (widget.profilePictureUrl != null &&
                    widget.profilePictureUrl!.isNotEmpty)
                ? Image.network(
                    widget.profilePictureUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => _buildFallbackBackground(),
                  )
                : _buildFallbackBackground(),
          ),
          // Blur and overlay
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
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

              // Calling icon with ripple rings
              SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ripple ring 1
                    AnimatedBuilder(
                      animation: _ring1,
                      builder: (_, _) => _buildRing(_ring1.value),
                    ),
                    // Ripple ring 2
                    AnimatedBuilder(
                      animation: _ring2,
                      builder: (_, _) => _buildRing(_ring2.value),
                    ),
                    // Ripple ring 3
                    AnimatedBuilder(
                      animation: _ring3,
                      builder: (_, _) => _buildRing(_ring3.value),
                    ),
                    // Ringing Icon
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: (widget.profilePictureUrl != null &&
                                  widget.profilePictureUrl!.isNotEmpty)
                              ? Image.network(
                                  widget.profilePictureUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) =>
                                      _buildFallbackIcon(),
                                )
                              : _buildFallbackIcon(),
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
      ],
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
            color: Colors.white.withValues(alpha: 0.25),
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

  Widget _buildFallbackIcon() {
    return Center(
      child: Icon(
        widget.isVideo ? CommonIcons.videocam : CommonIcons.phone,
        color: Colors.white,
        size: 48,
      ),
    );
  }

  Widget _buildFallbackBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
        ),
      ),
    );
  }
}
