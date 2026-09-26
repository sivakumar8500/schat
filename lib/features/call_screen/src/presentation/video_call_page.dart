// mason make page --name video_call
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:schat/features/call_screen/src/presentation/audio_call_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:schat/core/network/connectivity_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:schat/features/call_screen/src/domain/web_rtc_service.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_bloc.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_event.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_state.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/features/dashboard_screen/src/presentation/user_list_page.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';

/// 1-to-1 Video Call Page — renders real RTCVideoView for remote and local streams.
/// mason make page --name video_call
class VideoCallPage extends StatefulWidget {
  final String conversationId;
  final String contactName;
  final Color contactColor;
  final String recipientId;
  final bool isOutgoing;
  final String? profilePictureUrl;
  final String? myProfilePictureUrl;

  const VideoCallPage({
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
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage>
    with TickerProviderStateMixin {
  final WebRtcService _webRtcService = getIt<WebRtcService>();
  int _seconds = 0;
  Timer? _timer;
  bool _isNetworkConnected = true;
  StreamSubscription? _connectivitySubscription;

  late AnimationController _fadeController;
  bool _controlsVisible = true;
  Timer? _controlsTimer;
  bool _isLocalVideoSmall = true;

  double? _pipX;
  double? _pipY;

  @override
  void initState() {
    super.initState();
    try {
      WakelockPlus.enable();
    } catch (e) {
      debugPrint('Wakelock error in VideoCallPage: $e');
    }

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );

    getIt<ConnectivityRepository>().currentConnectivity.then((result) {
      final connected = result.any((r) => r != ConnectivityResult.none);
      if (mounted) {
        setState(() {
          _isNetworkConnected = connected;
        });
      }
    });
    _connectivitySubscription = getIt<ConnectivityRepository>().onConnectivityChanged.listen((result) {
      final connected = result.any((r) => r != ConnectivityResult.none);
      if (mounted) {
        setState(() {
          _isNetworkConnected = connected;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<CallWebRtcBloc>();
      bloc.add(const SetCallMinimizedEvent(false));

      // Re-initialize timer if the call is already active
      final activeState = bloc.state;
      if (activeState is CallActive) {
        final activeStart = bloc.activeCallStart;
        if (activeStart != null) {
          setState(() {
            _seconds = DateTime.now().difference(activeStart).inSeconds;
          });
        }
        _startTimer();
      }

      if (widget.isOutgoing) {
        bloc.add(InitiateCallEvent(
          conversationId: widget.conversationId,
          isVideo: true,
          contactName: widget.contactName,
          profilePictureUrl: widget.profilePictureUrl,
        ));
      }
    });

    _scheduleControlsHide();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          final activeStart = context.read<CallWebRtcBloc>().activeCallStart;
          if (activeStart != null) {
            _seconds = DateTime.now().difference(activeStart).inSeconds;
          } else {
            _seconds++;
          }
        });
      }
    });
  }

  void _scheduleControlsHide() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        final state = context.read<CallWebRtcBloc>().state;
        if (state is CallActive) {
          setState(() => _controlsVisible = false);
          _fadeController.reverse();
        }
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
    // Do NOT pop here — the BlocListener below will pop once CallEnded is emitted.
    // This ensures call_hangup is sent to the server before the page is disposed.
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controlsTimer?.cancel();
    _fadeController.dispose();
    _connectivitySubscription?.cancel();
    
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<CallWebRtcBloc, CallWebRtcState>(
      listener: (context, state) {
        if (state is CallActive && _timer == null) {
          _startTimer();
          _scheduleControlsHide();
        }
        if (state is CallEnded || state is CallRejected || state is CallError) {
          Navigator.of(context).maybePop();
        }
        if (state is CallActive) {
          if (state.switchRequestedCallType == 'audio') {
             _showSwitchRequestDialog(context, state);
          }
          if (!state.isVideo) {
             // Downgraded to audio call! Switch UI.
             Navigator.of(context).pushReplacement(
               MaterialPageRoute(
                 builder: (_) => BlocProvider.value(
                   value: context.read<CallWebRtcBloc>(),
                   child: AudioCallPage(
                     conversationId: widget.conversationId,
                     contactName: widget.contactName,
                     contactColor: widget.contactColor,
                     recipientId: widget.recipientId,
                     isOutgoing: widget.isOutgoing,
                     profilePictureUrl: widget.profilePictureUrl,
                     myProfilePictureUrl: widget.myProfilePictureUrl,
                   ),
                 ),
               ),
             );
          }
        }
      },
      child: BlocBuilder<CallWebRtcBloc, CallWebRtcState>(
        builder: (context, state) {
          final isMuted = state is CallActive ? state.isMuted : false;
          final isVideoOff = state is CallActive ? state.isVideoOff : false;
          bool isFrontCamera = true;
          if (state is CallActive) {
            isFrontCamera = state.isFrontCamera;
          } else if (state is CallConnecting) {
            isFrontCamera = state.isFrontCamera;
          } else if (state is CallRinging) {
            isFrontCamera = state.isFrontCamera;
          }

          return PopScope(
            canPop: true,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) {
                try {
                  final bloc = context.read<CallWebRtcBloc>();
                  if (bloc.state is CallActive || bloc.state is CallConnecting) {
                    bloc.add(const SetCallMinimizedEvent(true));
                  }
                } catch (_) {}
              }
            },
            child: Scaffold(
              backgroundColor: context.colors.pureBlack,
              body: GestureDetector(
                onTap: _showControls,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: state is CallActive
                          ? (_isLocalVideoSmall
                              ? (state.isRemoteVideoOff 
                                  ? _buildRemoteVideoOffPlaceholder(state)
                                  : RTCVideoView(
                                      _webRtcService.remoteRenderer,
                                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                                      mirror: false,
                                    ))
                              : (isVideoOff
                                  ? _buildLocalVideoOffPlaceholder()
                                  : RTCVideoView(
                                      _webRtcService.localRenderer,
                                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                                      mirror: isFrontCamera,
                                    )))
                          : (isVideoOff
                              ? _buildWaitingScreen()
                              : RTCVideoView(
                                  _webRtcService.localRenderer,
                                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                                  mirror: isFrontCamera,
                                )),
                    ),

                    // ─── Gradient overlays ───
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [
                              context.colors.pureBlack.withValues(alpha: 0.5),
                              context.colors.transparent,
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
                              context.colors.pureBlack.withValues(alpha: 0.7),
                              context.colors.transparent,
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

                    // ─── Top Left Minimize Button ───
                    Positioned(
                      top: 10,
                      left: 16,
                      child: SafeArea(
                        child: FadeTransition(
                          opacity: _fadeController,
                          child: _buildFrostedButton(
                            icon: CommonIcons.minimize,
                            onTap: () {
                              try {
                                if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
                                  const MethodChannel('com.sdpi.schat/pip').invokeMethod('enterPip');
                                }
                              } catch (_) {}
                              context.read<CallWebRtcBloc>().add(const SetCallMinimizedEvent(true));
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
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

                    // ─── Extra Participants Floating Overlay ───
                    if (state is CallActive && state.extraParticipants.isNotEmpty)
                      Positioned(
                        top: 130,
                        left: 16,
                        right: 70,
                        child: FadeTransition(
                          opacity: _fadeController,
                          child: _buildExtraParticipantsOverlay(context, state.extraParticipants),
                        ),
                      )
                    else if (state is CallConnecting && state.extraParticipants.isNotEmpty)
                      Positioned(
                        top: 130,
                        left: 16,
                        right: 70,
                        child: FadeTransition(
                          opacity: _fadeController,
                          child: _buildExtraParticipantsOverlay(context, state.extraParticipants),
                        ),
                      ),

                    // ─── Small Video (Picture-in-Picture) ───
                    if (state is CallActive)
                      _buildSmallVideoPiP(state, isVideoOff, isFrontCamera),

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
            ),
          );
        },
      ),
    );
  }

  Widget _buildExtraParticipantsOverlay(
      BuildContext context, List<UserModel> participants) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: participants.map((user) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFF00873C),
                  backgroundImage: (user.profilePictureUrl != null &&
                          user.profilePictureUrl!.isNotEmpty)
                      ? NetworkImage(user.profilePictureUrl!)
                      : null,
                  child: (user.profilePictureUrl == null ||
                          user.profilePictureUrl!.isEmpty)
                      ? Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.displayName,
                      style: context.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'Calling...',
                      style: context.bodySmall.copyWith(
                        color: const Color(0xFF34C759),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Stack(
      children: [
        if (widget.profilePictureUrl != null && widget.profilePictureUrl!.isNotEmpty) ...[
          Positioned.fill(
            child: Image.network(
              widget.profilePictureUrl!,
              fit: BoxFit.cover,
            ),
          ),
          // Dark overlay (no blur)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
        ] else ...[
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2C3E50), Color(0xFF000000)],
                ),
              ),
            ),
          ),
        ],
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  CommonIcons.videocam,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              CommonSpaces.h32,
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: context.colors.pureWhite.withValues(alpha: 0.54),
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopHeader(BuildContext context, CallWebRtcState state) {
    final statusText = !_isNetworkConnected
        ? (state is CallActive ? 'Reconnecting...' : 'Waiting for network...')
        : state is CallActive
            ? _formattedTime
            : state is CallConnecting
                ? 'Calling...'
                : 'Ringing';

    String title = state is CallActive ? state.contactName : widget.contactName;
    if (state is CallActive && state.extraParticipants.isNotEmpty) {
      title = '$title, ${state.extraParticipants.map((u) => u.displayName).join(", ")}';
    } else if (state is CallConnecting && state.extraParticipants.isNotEmpty) {
      title = '$title, ${state.extraParticipants.map((u) => u.displayName).join(", ")}';
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.titleMedium.copyWith(
                color: context.colors.pureWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: context.colors.pureBlack.withValues(alpha: 0.54), blurRadius: 8)],
              ),
            ),
            CommonSpaces.h4,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  statusText,
                  style: context.bodyMedium.copyWith(
                    color: state is CallActive
                        ? context.colors.success
                        : context.colors.pureWhite.withValues(alpha: 0.70),
                    fontSize: 14,
                    shadows: [Shadow(color: context.colors.pureBlack.withValues(alpha: 0.45), blurRadius: 6)],
                  ),
                ),
                if (state is CallActive && state.isRemoteMuted) ...[
                  CommonSpaces.w8,
                  Icon(CommonIcons.micOff, size: 14, color: context.colors.error),
                  CommonSpaces.w4,
                  Text(
                    'MUTED',
                    style: context.bodySmall.copyWith(
                      color: context.colors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddUserDialog() async {
    final bloc = context.read<CallWebRtcBloc>();
    final state = bloc.state;
    final List<String> currentExcludeIds = [widget.recipientId];
    if (state is CallActive) {
      currentExcludeIds.addAll(state.extraParticipants.map((u) => u.id));
    } else if (state is CallConnecting) {
      currentExcludeIds.addAll(state.extraParticipants.map((u) => u.id));
    }

    final selectedUsers = await showModalBottomSheet<List<UserModel>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(sheetContext).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(sheetContext).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: UserListPage(
            isPicker: true,
            excludeUserIds: currentExcludeIds,
          ),
        ),
      ),
    );

    if (!mounted || selectedUsers == null || selectedUsers.isEmpty) return;

    bloc.add(AddParticipantsCallEvent(selectedUsers));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Calling ${selectedUsers.map((u) => u.displayName).join(", ")}...'),
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFF00873C),
      ),
    );
  }

  Widget _buildTopRightButtons(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildFrostedButton(
            icon: CommonIcons.addCall,
            onTap: _openAddUserDialog,
          ),
          CommonSpaces.h12,
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
          color: context.colors.pureWhite.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(
              color: context.colors.pureWhite.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: context.colors.pureBlack.withValues(alpha: 0.2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: context.colors.pureWhite, size: 20),
      ),
    );
  }

  Widget _buildSmallVideoPiP(CallActive? state, bool isVideoOff, bool isFrontCamera) {
    return Positioned(
      top: _pipY ?? 80,
      left: _pipX,
      right: _pipX == null ? 72 : null,
      child: SafeArea(
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _pipX ??= MediaQuery.of(context).size.width - 72 - 110;
              _pipX = (_pipX! + details.delta.dx).clamp(0.0, MediaQuery.of(context).size.width - 110.0);
              
              _pipY ??= 80;
              _pipY = (_pipY! + details.delta.dy).clamp(0.0, MediaQuery.of(context).size.height - 160.0);
            });
          },
          onTap: () {
            if (state != null) {
              setState(() {
                _isLocalVideoSmall = !_isLocalVideoSmall;
              });
            }
          },
          child: Container(
            width: 110,
            height: 160,
            decoration: BoxDecoration(
              color: context.colors.videoCallBarBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.pureWhite.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: context.colors.pureBlack.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _isLocalVideoSmall
                  ? (isVideoOff
                      ? _buildLocalVideoOffPlaceholder()
                      : RTCVideoView(
                          _webRtcService.localRenderer,
                          mirror: isFrontCamera,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ))
                  : (state == null || state.isRemoteVideoOff
                      ? _buildRemoteVideoOffPlaceholder(state)
                      : RTCVideoView(
                          _webRtcService.remoteRenderer,
                          mirror: false,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        )),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalVideoOffPlaceholder() {
    return Container(
      color: context.colors.pureBlack.withValues(alpha: 0.87),
      child: Center(
        child: (widget.myProfilePictureUrl != null &&
                widget.myProfilePictureUrl!.isNotEmpty)
            ? ClipOval(
                child: Image.network(
                  widget.myProfilePictureUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Icon(
                      CommonIcons.person,
                      color: context.colors.pureWhite.withValues(alpha: 0.54),
                      size: 48),
                ),
              )
            : Icon(CommonIcons.person,
                color: context.colors.pureWhite.withValues(alpha: 0.54), size: 48),
      ),
    );
  }

  Widget _buildRemoteVideoOffPlaceholder(CallActive? state) {
    return Stack(
      children: [
        if (widget.profilePictureUrl != null && widget.profilePictureUrl!.isNotEmpty) ...[
          Positioned.fill(
            child: Image.network(
              widget.profilePictureUrl!,
              fit: BoxFit.cover,
            ),
          ),
          // Dark overlay (no blur)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
        ] else ...[
          Positioned.fill(
            child: Container(
              color: context.colors.pureBlack,
            ),
          ),
        ],
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  CommonIcons.videocamOff,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              CommonSpaces.h24,
              Text(
                'Video Paused',
                style: context.bodyMedium.copyWith(
                  color: context.colors.pureWhite.withValues(alpha: 0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlBar(BuildContext context, bool isMuted, bool isVideoOff,
      CallWebRtcState state) {
    final isSpeakerOn = state is CallActive
        ? state.isSpeakerOn
        : (state is CallConnecting
            ? state.isSpeakerOn
            : (state is CallRinging ? state.isSpeakerOn : true));
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.colors.videoCallBarBackground,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: context.colors.pureBlack.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBarButton(
            icon: isVideoOff ? CommonIcons.videocamOff : CommonIcons.videocam,
            isActive: isVideoOff,
            onTap: () => context
                .read<CallWebRtcBloc>()
                .add(const ToggleCameraCallEvent()),
          ),
          _buildBarButton(
            icon: isSpeakerOn ? CommonIcons.volumeUp : CommonIcons.volumeDown,
            isActive: isSpeakerOn,
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
              ? (activeColor ?? context.colors.videoCallButtonBackground)
              : context.colors.videoCallButtonBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: context.colors.pureWhite, size: size * 0.42),
      ),
    );
  }

  bool _isSwitchDialogShowing = false;
  
  void _showSwitchRequestDialog(BuildContext context, CallActive state) {
    if (_isSwitchDialogShowing) return;
    _isSwitchDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Audio Call Request', style: TextStyle(color: Colors.white)),
        content: Text('${state.contactName} is requesting to switch to an audio call.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _isSwitchDialogShowing = false;
              context.read<CallWebRtcBloc>().add(const RespondToCallSwitchEvent(false));
            },
            child: const Text('Decline', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _isSwitchDialogShowing = false;
              context.read<CallWebRtcBloc>().add(const RespondToCallSwitchEvent(true));
            },
            child: const Text('Accept', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }
}
