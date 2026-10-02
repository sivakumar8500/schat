// mason make page --name audio_call
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/core/network/connectivity_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_bloc.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_event.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_state.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/features/dashboard_screen/src/presentation/user_list_page.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:schat/features/call_screen/src/presentation/video_call_page.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/core/storage/storage_service.dart';

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
  final bool isGroup;
  final String? groupName;
  final List<UserModel> extraParticipants;

  const AudioCallPage({
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
  State<AudioCallPage> createState() => _AudioCallPageState();
}

class _AudioCallPageState extends State<AudioCallPage>
    with TickerProviderStateMixin {
  int _seconds = 0;
  Timer? _timer;
  bool _isNetworkConnected = true;
  StreamSubscription? _connectivitySubscription;
  bool _isNavigating = false;

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
    try {
      WakelockPlus.enable();
    } catch (e) {
      debugPrint('Wakelock error in AudioCallPage: $e');
    }
    _setupAnimations();

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

      // If outgoing call, initiate WebRTC (only if not already connected or connecting)
      if (widget.isOutgoing && bloc.state is! CallActive && bloc.state is! CallConnecting) {
        bloc.add(InitiateCallEvent(
          conversationId: widget.conversationId,
          isVideo: false,
          contactName: widget.contactName,
          profilePictureUrl: widget.profilePictureUrl,
          isGroup: widget.isGroup,
          groupName: widget.groupName,
          extraParticipants: widget.extraParticipants,
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

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _ring1Controller.dispose();
    _ring2Controller.dispose();
    _ring3Controller.dispose();
    _connectivitySubscription?.cancel();
    
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

  String get _formattedTime {
    final int minutes = _seconds ~/ 60;
    final int remainingSeconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _statusLabel(CallWebRtcState state) {
    if (!_isNetworkConnected) {
      if (state is CallActive) {
        return 'Reconnecting...';
      } else {
        return 'Waiting for network...';
      }
    }
    if (state is CallConnecting) return 'Calling...';
    if (state is CallActive) return _formattedTime;
    if (state is CallEnded) return 'Call Ended';
    if (state is CallRejected) return state.reason;
    if (state is CallError) return 'Connection Error';
    return 'Ringing...';
  }

  void _onHangUp(BuildContext context) {
    context.read<CallWebRtcBloc>().add(HangUpCallEvent(widget.conversationId));
    // Do NOT pop here — the BlocListener below will pop once CallEnded is emitted.
    // This ensures call_hangup is sent to the server before the page is disposed.
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CallWebRtcBloc, CallWebRtcState>(
      listener: (context, state) {
        if (state is CallActive && _timer == null) {
          _startTimer();
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
          if (state.switchRequestedCallType == 'video') {
             _showSwitchRequestDialog(context, state);
          }
          if (state.isVideo && !_isNavigating) {
             _isNavigating = true;
             context.read<CallWebRtcBloc>().add(const SetCallMinimizedEvent(false));
             // Upgraded to video call! Switch UI.
             Navigator.of(context).pushReplacement(
               MaterialPageRoute(
                 builder: (_) => BlocProvider.value(
                   value: context.read<CallWebRtcBloc>(),
                   child: VideoCallPage(
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
          final isSpeaker = state is CallActive
              ? state.isSpeakerOn
              : (state is CallConnecting
                  ? state.isSpeakerOn
                  : (state is CallRinging ? state.isSpeakerOn : false));

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
                // Dark overlay (no blur)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
                // Content
                SafeArea(
                  child: Column(
                    children: [
                    // ─── Header ───
                    _buildHeader(context),
                    
                    if (widget.isGroup || (state is CallActive && (state.isGroup || state.extraParticipants.isNotEmpty)) || (state is CallConnecting && (state.isGroup || state.extraParticipants.isNotEmpty))) ...[
                      const SizedBox(height: 8),
                      Text(
                        _statusLabel(state),
                        textAlign: TextAlign.center,
                        style: context.titleMedium.copyWith(
                          color: state is CallActive
                              ? const Color(0xFF34C759)
                              : Colors.white.withValues(alpha: 0.70),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildGroupAudioLayout(context, state, isMuted),
                    ] else ...[
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
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.12),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 20,
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        CommonIcons.phone,
                                        color: Colors.white,
                                        size: 56,
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
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          CommonSpaces.h8,
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Column(
                              key: ValueKey('${state.runtimeType}_${state is CallActive ? (state).isRemoteMuted : false}'),
                              children: [
                                Text(
                                  _statusLabel(state),
                                  textAlign: TextAlign.center,
                                  style: context.titleMedium.copyWith(
                                    color: state is CallActive
                                        ? const Color(0xFF34C759)
                                        : Colors.white.withValues(alpha: 0.70),
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
                    ],

                    // ─── Dark Pill Control Bar ───
                    _buildControlBar(context, isMuted, isSpeaker),
                  ],
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



  Widget _buildGroupAudioLayout(BuildContext context, CallWebRtcState state, bool isMuted) {
    final List<Widget> connectedCards = [];
    final List<UserModel> callingParticipants = [];

    // Local user card ("You")
    final bool localSpeaking = !isMuted && (state is CallActive || state is CallConnecting);
    final myPic = (widget.myProfilePictureUrl != null && widget.myProfilePictureUrl!.isNotEmpty)
        ? widget.myProfilePictureUrl
        : getIt<StorageService>().getProfilePic();
    connectedCards.add(_buildAudioUserCard(
      name: 'You',
      avatarUrl: myPic,
      isMuted: isMuted,
      status: localSpeaking ? 'Speaking' : 'Connected',
      isSpeaking: localSpeaking,
    ));

    // Extra participants
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
        final isConnected = connectedIds.any((id) => id.toLowerCase() == user.id.toLowerCase());

        if (isConnected) {
          final remoteMuted = state is CallActive ? state.isRemoteMuted : false;
          final isRemoteSpeaking = !remoteMuted;
          connectedCards.add(_buildAudioUserCard(
            name: user.displayName,
            avatarUrl: user.profilePictureUrl,
            isMuted: remoteMuted,
            status: isRemoteSpeaking ? 'Speaking' : 'Connected',
            isSpeaking: isRemoteSpeaking,
          ));
        } else {
          callingParticipants.add(user);
        }
      }
    } else {
      // Fallback if extra participants not yet populated
      if (state is CallActive) {
        final isRemoteSpeaking = !state.isRemoteMuted;
        connectedCards.add(_buildAudioUserCard(
          name: state.contactName,
          avatarUrl: widget.profilePictureUrl,
          isMuted: state.isRemoteMuted,
          status: isRemoteSpeaking ? 'Speaking' : 'Connected',
          isSpeaking: isRemoteSpeaking,
        ));
      }
    }

    return Expanded(
      child: Column(
        children: [
          // ─── TOP SECTION: Connected / Lifted Users Grid ───
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: connectedCards.length == 1
                  ? Center(
                      child: SizedBox(
                        width: 220,
                        height: 200,
                        child: connectedCards.first,
                      ),
                    )
                  : GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.95,
                      children: connectedCards,
                    ),
            ),
          ),

          // ─── BOTTOM SECTION: Calling / Ringing / Disconnected Tray ───
          if (callingParticipants.isNotEmpty)
            _buildBottomCallingTray(context, callingParticipants, disconnectedIds),
        ],
      ),
    );
  }

  Widget _buildBottomCallingTray(
    BuildContext context,
    List<UserModel> participants,
    Set<String> disconnectedIds,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                CommonIcons.phone,
                size: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                'Waiting / Disconnected (${participants.length})',
                style: context.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: participants.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, index) {
                final user = participants[index];
                final isDisconnected = disconnectedIds.contains(user.id);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDisconnected
                        ? Colors.redAccent.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDisconnected
                          ? Colors.redAccent.withValues(alpha: 0.35)
                          : Colors.white.withValues(alpha: 0.20),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF00873C),
                        backgroundImage: (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty)
                            ? NetworkImage(user.profilePictureUrl!)
                            : null,
                        child: (user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty)
                            ? Text(
                                user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isDisconnected) ...[
                                const SizedBox(
                                  width: 9,
                                  height: 9,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Color(0xFF34C759),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Calling...',
                                  style: TextStyle(
                                    color: Color(0xFF34C759),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ] else ...[
                                const Text(
                                  'No answer',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      if (isDisconnected) ...[
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            context.read<CallWebRtcBloc>().add(ReinviteParticipantCallEvent(user));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                                Icon(CommonIcons.phone, size: 11, color: Colors.white),
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioUserCard({
    required String name,
    String? avatarUrl,
    required bool isMuted,
    required String status,
    bool isSpeaking = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSpeaking
            ? const Color(0xFF1E2922)
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSpeaking
              ? const Color(0xFF34C759)
              : Colors.white.withValues(alpha: 0.22),
          width: isSpeaking ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isSpeaking
                ? const Color(0xFF34C759).withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.25),
            blurRadius: isSpeaking ? 16 : 10,
            spreadRadius: isSpeaking ? 1 : 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (isSpeaking)
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF34C759),
                      width: 2,
                    ),
                  ),
                ),
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFF00873C),
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              if (isMuted)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CommonIcons.micOff,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSpeaking) ...[
                _buildMiniEqualizer(),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: TextStyle(
              color: isSpeaking
                  ? const Color(0xFF34C759)
                  : (status == 'Connected' ? const Color(0xFF34C759) : Colors.white60),
              fontSize: 11,
              fontWeight: isSpeaking ? FontWeight.bold : FontWeight.w500,
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              context.read<CallWebRtcBloc>().add(const SetCallMinimizedEvent(true));
              Navigator.of(context).pop();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white, size: 26),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _openAddUserDialog,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(CommonIcons.addCall,
                  color: Colors.white, size: 20),
            ),
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
            color: Colors.white.withValues(alpha: 0.25),
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
          // Camera (switch to video) - only the host can request switch to video
          if (widget.isOutgoing)
            _buildPillButton(
              icon: CommonIcons.videocam,
              isActive: false,
              onTap: () {
                if (context.read<CallWebRtcBloc>().state is CallActive) {
                  context.read<CallWebRtcBloc>().add(const RequestCallSwitchEvent('video'));
                }
              },
            ),
          // Speaker — green when active
          _buildPillButton(
            icon: isSpeaker ? CommonIcons.volumeUp : CommonIcons.volumeDown,
            isActive: isSpeaker,
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

  Widget _buildFallbackBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E293B),
            widget.contactColor.withValues(alpha: 0.2),
            const Color(0xFF0F172A),
          ],
        ),
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
        title: const Text('Video Call Request', style: TextStyle(color: Colors.white)),
        content: Text('${state.contactName} is requesting to switch to a video call.', style: const TextStyle(color: Colors.white70)),
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
