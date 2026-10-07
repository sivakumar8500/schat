// mason make page --name video_call
import 'dart:async';
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
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/call_screen/src/presentation/widgets/animated_glowing_border_card.dart';

/// 1-to-1 & Group Video Call Page — renders RTCVideoView with sleek participant sheet,
/// compact action buttons, and active speaker glow matching AudioCallPage design.
/// mason make page --name video_call
class VideoCallPage extends StatefulWidget {
  final String conversationId;
  final String contactName;
  final Color contactColor;
  final String recipientId;
  final bool isOutgoing;
  final String? profilePictureUrl;
  final String? myProfilePictureUrl;
  final bool isGroup;
  final String? groupName;
  final List<UserModel> extraParticipants;

  const VideoCallPage({
    super.key,
    required this.conversationId,
    required this.contactName,
    required this.contactColor,
    required this.recipientId,
    this.isOutgoing = true,
    this.profilePictureUrl,
    this.myProfilePictureUrl,
    this.isGroup = false,
    this.groupName,
    this.extraParticipants = const [],
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
  StreamSubscription? _remoteStreamSubscription;
  StreamSubscription? _callSignalSubscription;
  bool _isNavigating = false;

  late AnimationController _fadeController;
  bool _controlsVisible = true;
  Timer? _controlsTimer;
  bool _isLocalVideoSmall = true;

  double? _pipX;
  double? _pipY;
  int _lastButtonTap = 0;

  void _safeTap(VoidCallback onTap) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastButtonTap < 400) return;
    _lastButtonTap = now;
    onTap();
  }

  @override
  void initState() {
    super.initState();
    CallWebRtcBloc.isCallScreenMounted = true;
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

    _remoteStreamSubscription = _webRtcService.remoteStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });

    _callSignalSubscription = _webRtcService.callSignalState.listen((_) {
      if (mounted) {
        setState(() {});
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

      if (widget.isOutgoing && bloc.state is! CallActive && bloc.state is! CallConnecting) {
        bloc.add(InitiateCallEvent(
          conversationId: widget.conversationId,
          isVideo: true,
          contactName: widget.contactName,
          recipientId: widget.recipientId,
          profilePictureUrl: widget.profilePictureUrl,
          isGroup: widget.isGroup,
          groupName: widget.groupName,
          extraParticipants: widget.extraParticipants,
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
    _controlsTimer = Timer(const Duration(seconds: 5), () {
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
  }

  @override
  void dispose() {
    CallWebRtcBloc.isCallScreenMounted = false;
    _timer?.cancel();
    _controlsTimer?.cancel();
    _fadeController.dispose();
    _connectivitySubscription?.cancel();
    _remoteStreamSubscription?.cancel();
    _callSignalSubscription?.cancel();

    // Notify bloc that page is being closed (minimized if call still active)
    if (!_isNavigating) {
      try {
        final bloc = getIt<CallWebRtcBloc>();
        if (bloc.state is CallActive || bloc.state is CallConnecting) {
          bloc.add(const SetCallMinimizedEvent(true));
        }
      } catch (e) {
        debugPrint('Error setting minimized state in dispose: $e');
      }
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    CallWebRtcBloc.isCallScreenMounted = true;
    return BlocListener<CallWebRtcBloc, CallWebRtcState>(
      listener: (context, state) {
        if (state is CallActive && _timer == null) {
          _startTimer();
          _scheduleControlsHide();
        }
        if (state is CallEnded || state is CallRejected || state is CallError) {
          if (!_isNavigating) {
            _isNavigating = true;
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          }
        }
        if (state is CallActive) {
          if (state.switchRequestedCallType == 'audio') {
            _showSwitchRequestDialog(context, state);
          }
          if (!state.isVideo && !_isNavigating) {
            _isNavigating = true;
            context.read<CallWebRtcBloc>().add(const SetCallMinimizedEvent(false));
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
                    isGroup: widget.isGroup,
                    groupName: widget.groupName,
                    extraParticipants: widget.extraParticipants,
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

          final bool isSystemPip = (state is CallActive && state.isSystemPip) ||
              (state is CallConnecting && state.isSystemPip);

          final bool isGroupCall = widget.isGroup ||
              (state is CallActive && state.isGroup) ||
              (state is CallConnecting && state.isGroup);

          return PopScope(
            canPop: true,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop && !_isNavigating) {
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
                behavior: HitTestBehavior.translucent,
                onTap: _showControls,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: isSystemPip
                          ? Container(color: Colors.black)
                          : (isGroupCall
                              ? _buildGroupVideoGrid(state, isVideoOff, isFrontCamera, isMuted)
                              : (state is CallActive
                                  ? (_isLocalVideoSmall
                                      ? (state.isRemoteVideoOff
                                          ? _buildRemoteVideoOffPlaceholder(state)
                                          : RTCVideoView(
                                              _webRtcService.remoteRenderer,
                                              key: ValueKey('main_remote_${_webRtcService.remoteRenderer.textureId}'),
                                              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                                              mirror: false,
                                            ))
                                      : (isVideoOff
                                          ? _buildLocalVideoOffPlaceholder()
                                          : RTCVideoView(
                                              _webRtcService.localRenderer,
                                              key: ValueKey('main_local_${_webRtcService.localRenderer.textureId}'),
                                              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                                              mirror: isFrontCamera,
                                            )))
                                  : (isVideoOff
                                      ? _buildWaitingScreen()
                                      : RTCVideoView(
                                          _webRtcService.localRenderer,
                                          key: ValueKey('main_local_${_webRtcService.localRenderer.textureId}'),
                                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                                          mirror: isFrontCamera,
                                        )))),
                    ),

                    // ─── Gradient overlays ───
                    Positioned.fill(
                      child: IgnorePointer(
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

                    // ─── Small Video (Picture-in-Picture) (only in 1-on-1 calls) ───
                    if (!isGroupCall && state is CallActive)
                      _buildSmallVideoPiP(state, isVideoOff, isFrontCamera),

                    // ─── Bottom Control Bar (fades) ───
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
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
                width: 90,
                height: 90,
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
                  size: 38,
                ),
              ),
              CommonSpaces.h24,
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: context.colors.pureWhite.withValues(alpha: 0.65),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Minimize Button
            _buildFrostedButton(
              icon: Icons.keyboard_arrow_down_rounded,
              onTap: () {
                context.read<CallWebRtcBloc>().add(const SetCallMinimizedEvent(true));
                Navigator.of(context).pop();
              },
            ),
            CommonSpaces.w12,
            // Center Title & Status
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: context.titleMedium.copyWith(
                      color: context.colors.pureWhite,
                      fontSize: 16,
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
                              ? const Color(0xFF34C759)
                              : context.colors.pureWhite.withValues(alpha: 0.70),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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
            CommonSpaces.w12,
            // Right Action Button: Add Participant
            _buildFrostedButton(
              icon: CommonIcons.addCall,
              onTap: _openAddUserDialog,
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
  }

  Widget _buildFrostedButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () => _safeTap(onTap),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
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
              child: (state?.isSystemPip ?? false)
                  ? const SizedBox.shrink()
                  : (_isLocalVideoSmall
                      ? (isVideoOff
                          ? _buildLocalVideoOffPlaceholder()
                          : RTCVideoView(
                              _webRtcService.localRenderer,
                              key: ValueKey('inset_local_${_webRtcService.localRenderer.textureId}'),
                              mirror: isFrontCamera,
                              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                            ))
                      : (state == null || state.isRemoteVideoOff
                          ? _buildRemoteVideoOffPlaceholder(state)
                          : RTCVideoView(
                              _webRtcService.remoteRenderer,
                              key: ValueKey('inset_remote_${_webRtcService.remoteRenderer.textureId}'),
                              mirror: false,
                              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                            ))),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalVideoOffPlaceholder() {
    final myPic = (widget.myProfilePictureUrl != null && widget.myProfilePictureUrl!.isNotEmpty)
        ? widget.myProfilePictureUrl
        : getIt<StorageService>().getProfilePic();
    final myName = getIt<StorageService>().getUsername() ?? 'You';

    return Container(
      color: const Color(0xFF141419),
      child: Center(
        child: CircleAvatar(
          radius: 36,
          backgroundColor: const Color(0xFF00873C),
          backgroundImage: (myPic != null && myPic.isNotEmpty)
              ? NetworkImage(myPic)
              : null,
          child: (myPic == null || myPic.isEmpty)
              ? Text(
                  myName.isNotEmpty ? myName[0].toUpperCase() : 'Y',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
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
                width: 90,
                height: 90,
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
                  size: 38,
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
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Camera On/Off
          _buildPillButton(
            icon: isVideoOff ? CommonIcons.videocamOff : CommonIcons.videocam,
            isActive: isVideoOff,
            size: 38,
            onTap: () => context
                .read<CallWebRtcBloc>()
                .add(const ToggleCameraCallEvent()),
          ),
          // Flip / Switch Camera
          _buildPillButton(
            icon: CommonIcons.flipCamera,
            isActive: false,
            size: 38,
            onTap: () => context
                .read<CallWebRtcBloc>()
                .add(const SwitchCameraCallEvent()),
          ),
          // Speaker Toggle — Green when on
          _buildPillButton(
            icon: isSpeakerOn ? CommonIcons.volumeUp : CommonIcons.volumeDown,
            isActive: isSpeakerOn,
            activeColor: const Color(0xFF34C759),
            size: 38,
            onTap: () => context
                .read<CallWebRtcBloc>()
                .add(const ToggleSpeakerCallEvent()),
          ),
          // Mute Toggle
          _buildPillButton(
            icon: isMuted ? CommonIcons.micOff : CommonIcons.mic,
            isActive: isMuted,
            size: 38,
            onTap: () => context
                .read<CallWebRtcBloc>()
                .add(const ToggleMuteCallEvent()),
          ),
          // End Call
          _buildPillButton(
            icon: CommonIcons.callEnd,
            isActive: true,
            activeColor: const Color(0xFFFF3B30),
            size: 42,
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
    double size = 38,
  }) {
    return GestureDetector(
      onTap: () => _safeTap(onTap),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isActive
              ? (activeColor ?? const Color(0xFF3A3A3C))
              : const Color(0xFF3A3A3C),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.46),
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

  Widget _buildGroupVideoGrid(CallWebRtcState state, bool isVideoOff, bool isFrontCamera, bool isMuted) {
    final List<Widget> connectedTiles = [];
    final List<_ParticipantInfo> allParticipants = [];

    // Local user ("You")
    final bool localSpeaking = !isMuted && (state is CallActive || state is CallConnecting);
    final myPic = (widget.myProfilePictureUrl != null && widget.myProfilePictureUrl!.isNotEmpty)
        ? widget.myProfilePictureUrl
        : getIt<StorageService>().getProfilePic();

    allParticipants.add(_ParticipantInfo(
      id: 'local_user',
      name: 'You',
      avatarUrl: myPic,
      isLocal: true,
      isConnected: true,
      isSpeaking: localSpeaking,
      isMuted: isMuted,
      isVideoOff: isVideoOff,
    ));

    connectedTiles.add(_buildGridTile(
      child: isVideoOff
          ? _buildLocalVideoOffPlaceholder()
          : RTCVideoView(
              _webRtcService.localRenderer,
              key: ValueKey('grid_local_${_webRtcService.localRenderer.textureId}'),
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              mirror: isFrontCamera,
            ),
      label: 'You',
      isMuted: isMuted,
      avatarUrl: myPic,
      isSpeaking: localSpeaking,
    ));

    // Participants
    final extra = state is CallActive
        ? state.extraParticipants
        : (state is CallConnecting ? state.extraParticipants : widget.extraParticipants);

    final connectedIds = state is CallActive
        ? state.connectedParticipantIds
        : (state is CallConnecting ? state.connectedParticipantIds : const <String>{});
    final disconnectedIds = state is CallActive
        ? state.disconnectedParticipantIds
        : (state is CallConnecting ? state.disconnectedParticipantIds : const <String>{});

    if (extra.isNotEmpty) {
      for (final user in extra) {
        final isConnectedPeer = connectedIds.any((id) => id.toLowerCase() == user.id.toLowerCase());
        final isDisconnectedPeer = disconnectedIds.any((id) => id.toLowerCase() == user.id.toLowerCase());
        final isUserMuted = state is CallActive
            ? state.mutedParticipantIds.contains(user.id)
            : false;
        final isRemoteSpeaking = isConnectedPeer && !isUserMuted;
        final isRemoteVidOff = state is CallActive
            ? (state.videoOffParticipantIds.contains(user.id) || state.isRemoteVideoOff)
            : false;

        allParticipants.add(_ParticipantInfo(
          id: user.id,
          name: user.displayName,
          avatarUrl: user.profilePictureUrl,
          isConnected: isConnectedPeer,
          isDisconnected: isDisconnectedPeer,
          isMuted: isUserMuted,
          isVideoOff: isRemoteVidOff,
          isSpeaking: isRemoteSpeaking,
          rawUser: user,
        ));

        if (isConnectedPeer) {
          // Eagerly initialize mesh peer renderer if not yet initialized
          _webRtcService.getOrCreatePeerRenderer(user.id);
          final peerRenderer = _webRtcService.getPeerRenderer(user.id) ?? _webRtcService.remoteRenderer;

          connectedTiles.add(_buildGridTile(
            child: isRemoteVidOff
                ? _buildRemoteParticipantPlaceholder(user.displayName, user.profilePictureUrl, isSpeaking: isRemoteSpeaking)
                : RTCVideoView(
                    peerRenderer,
                    key: ValueKey('grid_peer_${user.id}_${peerRenderer.textureId}'),
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    mirror: false,
                    filterQuality: FilterQuality.medium,
                  ),
            label: user.displayName,
            isMuted: isUserMuted,
            avatarUrl: user.profilePictureUrl,
            isSpeaking: isRemoteSpeaking,
          ));
        }
      }
    } else {
      if (state is CallActive) {
        final isUserMuted = state.mutedParticipantIds.contains(state.recipientId) || state.isRemoteMuted;
        final isRemoteSpeaking = !isUserMuted;
        final isRemoteVidOff = state.videoOffParticipantIds.contains(state.recipientId) || state.isRemoteVideoOff;
        _webRtcService.getOrCreatePeerRenderer(state.recipientId);
        final peerRenderer = _webRtcService.getPeerRenderer(state.recipientId) ?? _webRtcService.remoteRenderer;

        allParticipants.add(_ParticipantInfo(
          id: state.recipientId,
          name: state.contactName,
          avatarUrl: widget.profilePictureUrl,
          isConnected: true,
          isMuted: isUserMuted,
          isVideoOff: isRemoteVidOff,
          isSpeaking: isRemoteSpeaking,
        ));

        connectedTiles.add(_buildGridTile(
          child: isRemoteVidOff
              ? _buildRemoteParticipantPlaceholder(state.contactName, widget.profilePictureUrl, isSpeaking: isRemoteSpeaking)
              : RTCVideoView(
                  peerRenderer,
                  key: ValueKey('grid_remote_${peerRenderer.textureId}'),
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  mirror: false,
                  filterQuality: FilterQuality.medium,
                ),
          label: state.contactName,
          isMuted: isUserMuted,
          avatarUrl: widget.profilePictureUrl,
          isSpeaking: isRemoteSpeaking,
        ));
      }
    }

    final connectedCount = allParticipants.where((p) => p.isConnected).length;
    final waitingCount = allParticipants.where((p) => !p.isConnected).length;
    final count = connectedTiles.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 60, 12, 76),
        child: Column(
          children: [
            // ─── Top Main Grid: Connected Users ───
            Expanded(
              child: count <= 1
                  ? connectedTiles.first
                  : (count == 2
                      ? Column(
                          children: [
                            Expanded(child: connectedTiles[0]),
                            const SizedBox(height: 10),
                            Expanded(child: connectedTiles[1]),
                          ],
                        )
                      : GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.88,
                          children: connectedTiles,
                        )),
            ),

            const SizedBox(height: 6),

            // ─── BOTTOM STACKED PARTICIPANTS CHIP ───
            _buildStackedParticipantsChip(
              context,
              allParticipants,
              connectedCount,
              waitingCount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStackedParticipantsChip(
    BuildContext context,
    List<_ParticipantInfo> allParticipants,
    int connectedCount,
    int waitingCount,
  ) {
    return GestureDetector(
      onTap: () => _showParticipantsBottomSheet(context, allParticipants),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildAvatarStack(allParticipants),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Participants (${allParticipants.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (waitingCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orangeAccent.withValues(alpha: 0.6),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '$waitingCount calling',
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$connectedCount joined',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStack(List<_ParticipantInfo> participants) {
    final displayList = participants.take(4).toList();
    final remaining = participants.length - displayList.length;

    return SizedBox(
      height: 28,
      width: 28 + (displayList.length - 1) * 16.0 + (remaining > 0 ? 20.0 : 0.0),
      child: Stack(
        children: [
          for (int i = 0; i < displayList.length; i++)
            Positioned(
              left: i * 16.0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1E2922), width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: displayList[i].isConnected
                      ? const Color(0xFF00873C)
                      : Colors.grey.shade700,
                  backgroundImage: (displayList[i].avatarUrl != null &&
                          displayList[i].avatarUrl!.isNotEmpty)
                      ? NetworkImage(displayList[i].avatarUrl!)
                      : null,
                  child: (displayList[i].avatarUrl == null ||
                          displayList[i].avatarUrl!.isEmpty)
                      ? Text(
                          displayList[i].name.isNotEmpty
                              ? displayList[i].name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          if (remaining > 0)
            Positioned(
              left: displayList.length * 16.0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.25),
                  border: Border.all(color: const Color(0xFF1E2922), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '+$remaining',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showParticipantsBottomSheet(
    BuildContext context,
    List<_ParticipantInfo> allParticipants,
  ) {
    final connectedList = allParticipants.where((p) => p.isConnected).toList();
    final waitingList = allParticipants.where((p) => !p.isConnected).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.70,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF161B22),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Call Participants (${allParticipants.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _openAddUserDialog();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00873C),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00873C).withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CommonIcons.addCall, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Add',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white12, height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    if (connectedList.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: Text(
                          'CONNECTED (${connectedList.length})',
                          style: TextStyle(
                            color: const Color(0xFF34C759).withValues(alpha: 0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      ...connectedList.map((p) => _buildParticipantSheetTile(p)),
                      const SizedBox(height: 12),
                    ],
                    if (waitingList.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: Text(
                          'WAITING / DISCONNECTED (${waitingList.length})',
                          style: TextStyle(
                            color: Colors.orangeAccent.withValues(alpha: 0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      ...waitingList.map((p) => _buildParticipantSheetTile(p)),
                    ],
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(sheetContext).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticipantSheetTile(_ParticipantInfo p) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: p.isConnected
              ? (p.isSpeaking ? const Color(0xFF00FF87).withValues(alpha: 0.4) : Colors.white10)
              : (p.isDisconnected ? Colors.redAccent.withValues(alpha: 0.3) : Colors.white10),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: p.isConnected ? const Color(0xFF00873C) : Colors.grey.shade700,
            backgroundImage: (p.avatarUrl != null && p.avatarUrl!.isNotEmpty)
                ? NetworkImage(p.avatarUrl!)
                : null,
            child: (p.avatarUrl == null || p.avatarUrl!.isEmpty)
                ? Text(
                    p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.name + (p.isLocal ? ' (You)' : ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                if (p.isConnected) ...[
                  Row(
                    children: [
                      if (p.isSpeaking) ...[
                        _buildMiniEqualizer(),
                        const SizedBox(width: 6),
                        const Text(
                          'Speaking',
                          style: TextStyle(
                            color: Color(0xFF00FF87),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else if (p.isMuted) ...[
                        const Icon(CommonIcons.micOff, size: 12, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        const Text(
                          'Muted',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF34C759),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Connected',
                          style: TextStyle(
                            color: Color(0xFF34C759),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      if (!p.isDisconnected) ...[
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            color: Color(0xFF34C759),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Calling...',
                          style: TextStyle(
                            color: Color(0xFF34C759),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        const Icon(Icons.call_end_rounded, size: 12, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        const Text(
                          'Disconnected',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!p.isConnected && p.rawUser != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                context.read<CallWebRtcBloc>().add(ReinviteParticipantCallEvent(p.rawUser!));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00873C),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00873C).withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CommonIcons.videocam, size: 11, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Call Again',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGridTile({
    required Widget child,
    required String label,
    required bool isMuted,
    String? avatarUrl,
    bool isSpeaking = false,
  }) {
    return AnimatedGlowingBorderCard(
      isSpeaking: isSpeaking,
      borderRadius: 16,
      borderWidth: 2.5,
      padding: EdgeInsets.zero,
      baseColor: const Color(0xFF1E1E24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14.5),
            child: child,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14.5)),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 8,
            child: Row(
              children: [
                if (isSpeaking) ...[
                  _buildMiniEqualizer(),
                  const SizedBox(width: 5),
                ],
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
                if (isMuted) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CommonIcons.micOff,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniEqualizer() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 3.0, end: 11.0),
          duration: Duration(milliseconds: 260 + (i * 80)),
          builder: (_, h, _) => Container(
            width: 2.5,
            height: h,
            margin: const EdgeInsets.symmetric(horizontal: 1.2),
            decoration: BoxDecoration(
              color: const Color(0xFF34C759),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRemoteParticipantPlaceholder(String name, String? avatarUrl, {bool isSpeaking = false}) {
    return Container(
      color: const Color(0xFF141419),
      child: Center(
        child: _SpeakerPulsingAvatar(
          avatarUrl: avatarUrl,
          displayName: name,
          isSpeaking: isSpeaking,
          isMuted: false,
          radius: 34,
        ),
      ),
    );
  }
}

class _ParticipantInfo {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isLocal;
  final bool isConnected;
  final bool isDisconnected;
  final bool isMuted;
  final bool isVideoOff;
  final bool isSpeaking;
  final UserModel? rawUser;

  const _ParticipantInfo({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isLocal = false,
    this.isConnected = false,
    this.isDisconnected = false,
    this.isMuted = false,
    this.isVideoOff = false,
    this.isSpeaking = false,
    this.rawUser,
  });
}

class _SpeakerPulsingAvatar extends StatefulWidget {
  final String? avatarUrl;
  final String displayName;
  final bool isSpeaking;
  final bool isMuted;
  final double radius;

  const _SpeakerPulsingAvatar({
    this.avatarUrl,
    required this.displayName,
    required this.isSpeaking,
    required this.isMuted,
    required this.radius,
  });

  @override
  State<_SpeakerPulsingAvatar> createState() => _SpeakerPulsingAvatarState();
}

class _SpeakerPulsingAvatarState extends State<_SpeakerPulsingAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.isSpeaking) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _SpeakerPulsingAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (!widget.isSpeaking && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double avatarSize = widget.radius * 2;
    final double outerSize = avatarSize + 26;

    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.isSpeaking) ...[
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final v1 = _pulseController.value;
                final v2 = (_pulseController.value + 0.5) % 1.0;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: avatarSize + (22 * v1),
                      height: avatarSize + (22 * v1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00FF87).withValues(alpha: (1.0 - v1) * 0.7),
                          width: 1.5,
                        ),
                        color: const Color(0xFF00FF87).withValues(alpha: (1.0 - v1) * 0.12),
                      ),
                    ),
                    Container(
                      width: avatarSize + (14 * v2),
                      height: avatarSize + (14 * v2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF34C759).withValues(alpha: (1.0 - v2) * 0.8),
                          width: 1.5,
                        ),
                        color: const Color(0xFF34C759).withValues(alpha: (1.0 - v2) * 0.15),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isSpeaking ? const Color(0xFF00FF87) : Colors.white.withValues(alpha: 0.25),
                width: widget.isSpeaking ? 2.5 : 1.5,
              ),
              boxShadow: widget.isSpeaking
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00FF87).withValues(alpha: 0.45),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                      ),
                    ],
            ),
            child: CircleAvatar(
              radius: widget.radius,
              backgroundColor: const Color(0xFF00873C),
              backgroundImage: (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
                  ? NetworkImage(widget.avatarUrl!)
                  : null,
              child: (widget.avatarUrl == null || widget.avatarUrl!.isEmpty)
                  ? Text(
                      widget.displayName.isNotEmpty ? widget.displayName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.radius * 0.65,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          if (widget.isMuted)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: const Icon(
                  CommonIcons.micOff,
                  size: 11,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
