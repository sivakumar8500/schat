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
import 'package:schat/features/dashboard_screen/src/presentation/user_list_page.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:schat/features/call_screen/src/presentation/video_call_page.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/call_screen/src/presentation/widgets/animated_glowing_border_card.dart';

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
      debugPrint('Wakelock error in AudioCallPage: $e');
    }

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
          recipientId: widget.recipientId,
          profilePictureUrl: widget.profilePictureUrl,
          isGroup: widget.isGroup,
          groupName: widget.groupName,
          extraParticipants: widget.extraParticipants,
        ));
      }
    });
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
    CallWebRtcBloc.isCallScreenMounted = false;
    _timer?.cancel();
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
    CallWebRtcBloc.isCallScreenMounted = true;
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
                    
                    if (isGroupCall) ...[
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
                      const SizedBox(height: 12),

                      // ─── WhatsApp 1-on-1 End-to-End Encrypted + Name & Status ───
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'End-to-end encrypted',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.65),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          state is CallActive ? state.contactName : widget.contactName,
                          textAlign: TextAlign.center,
                          style: context.h2.copyWith(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
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
                                    ? Colors.white.withValues(alpha: 0.90)
                                    : Colors.white.withValues(alpha: 0.75),
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
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
    final List<_ParticipantInfo> allParticipants = [];

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

    allParticipants.add(_ParticipantInfo(
      id: 'local_user',
      name: 'You',
      avatarUrl: myPic,
      isLocal: true,
      isConnected: true,
      isSpeaking: localSpeaking,
      isMuted: isMuted,
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
        final isDisconnected = disconnectedIds.any((id) => id.toLowerCase() == user.id.toLowerCase());
        final isUserMuted = state is CallActive
            ? state.mutedParticipantIds.contains(user.id)
            : false;
        final isRemoteSpeaking = isConnected && !isUserMuted;

        allParticipants.add(_ParticipantInfo(
          id: user.id,
          name: user.displayName,
          avatarUrl: user.profilePictureUrl,
          isConnected: isConnected,
          isDisconnected: isDisconnected,
          isMuted: isUserMuted,
          isSpeaking: isRemoteSpeaking,
          rawUser: user,
        ));

        if (isConnected) {
          connectedCards.add(_buildAudioUserCard(
            name: user.displayName,
            avatarUrl: user.profilePictureUrl,
            isMuted: isUserMuted,
            status: isRemoteSpeaking ? 'Speaking' : 'Muted',
            isSpeaking: isRemoteSpeaking,
          ));
        }
      }
    } else {
      // Fallback if extra participants not yet populated
      if (state is CallActive) {
        final isUserMuted = state.mutedParticipantIds.contains(state.recipientId) || state.isRemoteMuted;
        final isRemoteSpeaking = !isUserMuted;

        allParticipants.add(_ParticipantInfo(
          id: state.recipientId,
          name: state.contactName,
          avatarUrl: widget.profilePictureUrl,
          isConnected: true,
          isMuted: isUserMuted,
          isSpeaking: isRemoteSpeaking,
        ));

        connectedCards.add(_buildAudioUserCard(
          name: state.contactName,
          avatarUrl: widget.profilePictureUrl,
          isMuted: isUserMuted,
          status: isRemoteSpeaking ? 'Speaking' : 'Muted',
          isSpeaking: isRemoteSpeaking,
        ));
      }
    }

    final connectedCount = allParticipants.where((p) => p.isConnected).length;
    final waitingCount = allParticipants.where((p) => !p.isConnected).length;

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

          // ─── BOTTOM STACKED PARTICIPANTS CHIP ───
          _buildStackedParticipantsChip(
            context,
            allParticipants,
            connectedCount,
            waitingCount,
          ),
        ],
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
        margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.60),
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
  }

  Widget _buildAudioUserCard({
    required String name,
    String? avatarUrl,
    required bool isMuted,
    required String status,
    bool isSpeaking = false,
  }) {
    return AnimatedGlowingBorderCard(
      isSpeaking: isSpeaking,
      borderRadius: 20,
      borderWidth: 2.5,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SpeakerPulsingAvatar(
            avatarUrl: avatarUrl,
            displayName: name,
            isSpeaking: isSpeaking,
            isMuted: isMuted,
            radius: 34,
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
                  ? const Color(0xFF00FF7F)
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

  Widget _buildControlBar(BuildContext context, bool isMuted, bool isSpeaker) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
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
          // Camera (switch to video) - only the host can request switch to video
          if (widget.isOutgoing)
            _buildPillButton(
              icon: CommonIcons.videocam,
              isActive: false,
              size: 38,
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
            size: 38,
            onTap: () => context
                .read<CallWebRtcBloc>()
                .add(const ToggleSpeakerCallEvent()),
          ),
          // Mute
          _buildPillButton(
            icon: isMuted ? CommonIcons.micOff : CommonIcons.mic,
            isActive: isMuted,
            size: 38,
            onTap: () =>
                context.read<CallWebRtcBloc>().add(const ToggleMuteCallEvent()),
          ),
          // End call
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

class _ParticipantInfo {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isLocal;
  final bool isConnected;
  final bool isDisconnected;
  final bool isMuted;
  final bool isSpeaking;
  final UserModel? rawUser;

  _ParticipantInfo({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isLocal = false,
    required this.isConnected,
    this.isDisconnected = false,
    this.isMuted = false,
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
    required this.avatarUrl,
    required this.displayName,
    required this.isSpeaking,
    this.isMuted = false,
    this.radius = 32.0,
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
                    // Outer ripple
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
                    // Inner ripple
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
          // Main Avatar
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
