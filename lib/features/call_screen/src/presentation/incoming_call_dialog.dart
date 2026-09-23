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

  void _accept() async {
    final bloc = context.read<CallWebRtcBloc>();
    final nav = Navigator.of(context);
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
    bloc.add(AnswerCallEvent(widget.incomingEvent));
    nav.pop();
    nav.push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
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

  void _decline() {
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

              // Bottom Actions: Decline + Slide to Answer
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Decline quick button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSmallActionButton(
                          icon: Icons.alarm,
                          label: 'Remind Me',
                          onTap: () {},
                        ),
                        _buildSmallActionButton(
                          icon: Icons.message_rounded,
                          label: 'Message',
                          onTap: () {},
                        ),
                        _buildSmallActionButton(
                          icon: CommonIcons.callEnd,
                          label: 'Decline',
                          color: const Color(0xFFFF3B30),
                          onTap: _decline,
                        ),
                      ],
                    ),
                    CommonSpaces.h32,
                    // Dual Swipe / Slide Call Actions
                    DualSlideCallActions(
                      isVideo: widget.isVideo,
                      onAccepted: _accept,
                      onDeclined: _decline,
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

  Widget _buildSmallActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: (color ?? Colors.white).withValues(alpha: color != null ? 0.25 : 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: (color ?? Colors.white).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color ?? Colors.white, size: 24),
          ),
          CommonSpaces.h8,
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

/// Interactive Dual Slide / Swipe Call Actions:
/// - Slide Right-to-Left (<<<) on the Accept button to answer.
/// - Slide Left-to-Right (>>>) on the Decline button to decline.
/// - Tap directly or swipe either side.
class DualSlideCallActions extends StatefulWidget {
  final VoidCallback onAccepted;
  final VoidCallback onDeclined;
  final bool isVideo;

  const DualSlideCallActions({
    super.key,
    required this.onAccepted,
    required this.onDeclined,
    required this.isVideo,
  });

  @override
  State<DualSlideCallActions> createState() => _DualSlideCallActionsState();
}

class _DualSlideCallActionsState extends State<DualSlideCallActions>
    with SingleTickerProviderStateMixin {
  double _acceptDrag = 0.0; // Positive value representing pixels dragged to the left
  double _declineDrag = 0.0; // Positive value representing pixels dragged to the right
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _shimmerAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double buttonSize = 72.0;
    const double maxDragDistance = 90.0;
    const double threshold = 65.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Decline (Swipe Left-to-Right >>> or Tap)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: buttonSize + maxDragDistance,
              height: buttonSize,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Track background when dragging
                  if (_declineDrag > 0)
                    Positioned(
                      left: 0,
                      top: 6,
                      bottom: 6,
                      width: buttonSize + _declineDrag,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(buttonSize / 2),
                          border: Border.all(
                            color: const Color(0xFFFF3B30).withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                      ),
                    ),

                  // Shimmering Arrow indicators pointing right >>>
                  Positioned(
                    left: buttonSize + 6,
                    child: AnimatedBuilder(
                      animation: _shimmerAnimation,
                      builder: (context, _) {
                        return Opacity(
                          opacity: _shimmerAnimation.value,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chevron_right_rounded, color: Colors.white60, size: 20),
                              Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 20),
                              Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Draggable Decline Button
                  Positioned(
                    left: _declineDrag,
                    child: GestureDetector(
                      onTap: widget.onDeclined,
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _declineDrag = (_declineDrag + details.delta.dx).clamp(0.0, maxDragDistance);
                        });
                      },
                      onHorizontalDragEnd: (details) {
                        if (_declineDrag >= threshold) {
                          widget.onDeclined();
                        } else {
                          setState(() {
                            _declineDrag = 0.0;
                          });
                        }
                      },
                      child: Container(
                        width: buttonSize,
                        height: buttonSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF3B30), Color(0xFFD70015)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF3B30).withValues(alpha: 0.45),
                              blurRadius: 18,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CommonIcons.callEnd,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CommonSpaces.h10,
            const Text(
              'Decline',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),

        // Accept (Swipe Right-to-Left <<< or Tap)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: buttonSize + maxDragDistance,
              height: buttonSize,
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  // Track background when dragging
                  if (_acceptDrag > 0)
                    Positioned(
                      right: 0,
                      top: 6,
                      bottom: 6,
                      width: buttonSize + _acceptDrag,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(buttonSize / 2),
                          border: Border.all(
                            color: const Color(0xFF34C759).withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                      ),
                    ),

                  // Shimmering Arrow indicators pointing left <<<
                  Positioned(
                    right: buttonSize + 6,
                    child: AnimatedBuilder(
                      animation: _shimmerAnimation,
                      builder: (context, _) {
                        return Opacity(
                          opacity: _shimmerAnimation.value,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
                              Icon(Icons.chevron_left_rounded, color: Colors.white70, size: 20),
                              Icon(Icons.chevron_left_rounded, color: Colors.white60, size: 20),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Draggable Accept Button
                  Positioned(
                    right: _acceptDrag,
                    child: GestureDetector(
                      onTap: widget.onAccepted,
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          // Dragging to the left means negative dx, which increases _acceptDrag
                          _acceptDrag = (_acceptDrag - details.delta.dx).clamp(0.0, maxDragDistance);
                        });
                      },
                      onHorizontalDragEnd: (details) {
                        if (_acceptDrag >= threshold) {
                          widget.onAccepted();
                        } else {
                          setState(() {
                            _acceptDrag = 0.0;
                          });
                        }
                      },
                      child: Container(
                        width: buttonSize,
                        height: buttonSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF34C759), Color(0xFF248A3D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF34C759).withValues(alpha: 0.5),
                              blurRadius: 18,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.isVideo ? CommonIcons.videocam : CommonIcons.phone,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CommonSpaces.h10,
            const Text(
              'Accept',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
