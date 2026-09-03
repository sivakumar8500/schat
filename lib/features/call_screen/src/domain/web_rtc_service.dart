// mason make usecase --name web_rtc_service
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:schat/core/network/connectivity_repository.dart';
import 'package:schat/injection.dart';

/// Represents the signaling state of the WebRTC call.
enum CallSignalState { idle, connecting, ringing, active, ended, rejected, busy }

/// Singleton service managing the full WebRTC peer-to-peer call lifecycle.
/// mason make usecase --name web_rtc_service
@lazySingleton
class WebRtcService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final List<dynamic> _remoteCandidateQueue = [];

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  String? _activeConversationId;
  bool _renderersInitialized = false;
  Timer? _reconnectTimer;
  StreamSubscription? _connectivitySubscription;

  final _localStreamController = StreamController<MediaStream?>.broadcast();
  final _remoteStreamController = StreamController<MediaStream?>.broadcast();
  final _callSignalController = StreamController<CallSignalState>.broadcast();

  Stream<MediaStream?> get localStream => _localStreamController.stream;
  Stream<MediaStream?> get remoteStream => _remoteStreamController.stream;
  Stream<CallSignalState> get callSignalState => _callSignalController.stream;

  String? get activeConversationId => _activeConversationId;

  static const Map<String, dynamic> _peerConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
      {'urls': 'stun:stun4.l.google.com:19302'},
    ],
  };

  static const Map<String, dynamic> _offerConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  // ─────────────────────────────────────────────
  // RENDERERS
  // ─────────────────────────────────────────────

  Future<void> initRenderers() async {
    if (!_renderersInitialized) {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
      _renderersInitialized = true;
      
      // Set audio mode for communication
      try {
        // Note: setAudioMode might not be available in all plugin versions
        // or might have been moved.
      } catch (e) {
        debugPrint('WebRTC: setAudioMode failed: $e');
      }
    }
  }

  // ─────────────────────────────────────────────
  // MAKE CALL (Caller side)
  // ─────────────────────────────────────────────

  Future<void> makeCall({
    required String conversationId,
    required bool isVideo,
    required ChatSocketRepository repository,
    String? callerName,
    String? profilePictureUrl,
  }) async {
    _activeConversationId = conversationId;
    await initRenderers();
    _callSignalController.add(CallSignalState.connecting);

    // 1. Capture local media
    _localStream = await _getUserMedia(isVideo: isVideo);
    
    // Log local tracks
    for (var track in _localStream!.getTracks()) {
      debugPrint('WebRTC: Local track: ${track.kind}, enabled: ${track.enabled}');
    }

    localRenderer.srcObject = _localStream;
    _localStreamController.add(_localStream);

    // 2. Create peer connection
    _peerConnection = await createPeerConnection(_peerConfig, _offerConstraints);
    _attachLocalTracks();
    _setupConnectionCallbacks(repository);

    // 3. Create and set local SDP offer
    final offer = await _peerConnection!.createOffer(_offerConstraints);
    await _peerConnection!.setLocalDescription(offer);

    // 4. Send call_initiate over WebSocket signaling
    repository.emit('message', {
      'type': 'call_initiate',
      'conversation_id': conversationId,
      'call_type': isVideo ? 'video' : 'audio',
      'caller_name': callerName,
      'profile_picture_url': profilePictureUrl,
      'offer': {
        'type': offer.type,
        'sdp': offer.sdp,
      },
    });

    debugPrint('WebRTC: call_initiate sent for conv=$conversationId');
  }

  // ─────────────────────────────────────────────
  // ANSWER CALL (Callee side)
  // ─────────────────────────────────────────────

  Future<void> answerCall({
    required Map<String, dynamic> incomingEvent,
    required ChatSocketRepository repository,
  }) async {
    final conversationId = incomingEvent['conversation_id'] as String;
    final messageId = incomingEvent['message_id'] ?? incomingEvent['messageId'];
    final callType = incomingEvent['call_type'] as String? ?? 'audio';
    final offerMap = incomingEvent['offer'] as Map<String, dynamic>;
    _activeConversationId = conversationId;

    await initRenderers();
    _callSignalController.add(CallSignalState.connecting);

    // Set audio mode for communication
    try {
      // Note: setAudioMode might not be available in all plugin versions
    } catch (e) {
      debugPrint('WebRTC: setAudioMode failed: $e');
    }

    // 1. Get callee's local media
    _localStream = await _getUserMedia(isVideo: callType == 'video');
    localRenderer.srcObject = _localStream;
    _localStreamController.add(_localStream);

    // 2. Create peer connection
    _peerConnection = await createPeerConnection(_peerConfig, _offerConstraints);
    _attachLocalTracks();
    _setupConnectionCallbacks(repository);

    // 3. Set remote description (the caller's SDP offer)
    final remoteOffer = RTCSessionDescription(offerMap['sdp'], offerMap['type']);
    await _peerConnection!.setRemoteDescription(remoteOffer);
    await _processRemoteCandidateQueue();

    // 4. Create and set local SDP answer
    final answer = await _peerConnection!.createAnswer(_offerConstraints);
    await _peerConnection!.setLocalDescription(answer);

    // 5. Send call_response with accept over WebSocket
    repository.emit('message', {
      'type': 'call_response',
      'conversation_id': conversationId,
      'message_id': messageId,
      'response': 'accept',
      'answer': {
        'type': answer.type,
        'sdp': answer.sdp,
      },
    });

    debugPrint('WebRTC: call_response (accept) sent for conv=$conversationId');
  }

  // ─────────────────────────────────────────────
  // REJECT CALL
  // ─────────────────────────────────────────────

  void rejectCall({
    required String conversationId,
    String? messageId,
    required ChatSocketRepository repository,
    String reason = 'reject',
  }) {
    repository.emit('message', {
      'type': 'call_response',
      'conversation_id': conversationId,
      'message_id': messageId,
      'response': reason,
      'answer': null,
    });
    _callSignalController.add(CallSignalState.rejected);
    debugPrint('WebRTC: call_response ($reason) sent for conv=$conversationId');
  }

  // ─────────────────────────────────────────────
  // HANDLE CALL ANSWERED (Caller side receives SDP answer)
  // ─────────────────────────────────────────────

  Future<void> handleCallAnswered(Map<String, dynamic> event) async {
    final response = event['response'] as String?;
    if (response == 'reject' || response == 'busy') {
      _callSignalController.add(
        response == 'busy' ? CallSignalState.busy : CallSignalState.rejected,
      );
      await cleanup();
      return;
    }

    final answerMap = event['answer'] as Map<String, dynamic>?;
    if (answerMap == null || _peerConnection == null) return;

    final remoteAnswer = RTCSessionDescription(answerMap['sdp'], answerMap['type']);
    await _peerConnection!.setRemoteDescription(remoteAnswer);
    await _processRemoteCandidateQueue();
    _callSignalController.add(CallSignalState.active);
    debugPrint('WebRTC: Remote answer set — call is ACTIVE');
  }

  // ─────────────────────────────────────────────
  // HANDLE REMOTE ICE CANDIDATE
  // ─────────────────────────────────────────────

  Future<void> handleRemoteIceCandidate(Map<String, dynamic> event) async {
    final candidateMap = event['candidate'] as Map<String, dynamic>?;
    if (candidateMap == null) return;

    final candidate = RTCIceCandidate(
      candidateMap['candidate'] as String,
      candidateMap['sdpMid'] as String?,
      candidateMap['sdpMLineIndex'] as int?,
    );

    if (_peerConnection == null) {
      debugPrint('WebRTC: PeerConnection null, queuing ICE candidate');
      _remoteCandidateQueue.add(candidate);
      return;
    }

    try {
      await _peerConnection!.addCandidate(candidate);
      debugPrint('WebRTC: Remote ICE candidate added successfully');
    } catch (e) {
      debugPrint('WebRTC: Error adding remote ICE candidate, queuing: $e');
      _remoteCandidateQueue.add(candidate);
    }
  }

  Future<void> _processRemoteCandidateQueue() async {
    if (_peerConnection == null || _remoteCandidateQueue.isEmpty) return;
    debugPrint('WebRTC: Processing ${_remoteCandidateQueue.length} queued ICE candidates');
    
    final List<dynamic> candidates = List.from(_remoteCandidateQueue);
    _remoteCandidateQueue.clear();

    for (var candidate in candidates) {
      try {
        await _peerConnection!.addCandidate(candidate);
        debugPrint('WebRTC: Queued ICE candidate added successfully');
      } catch (e) {
        debugPrint('WebRTC: Error adding queued ICE candidate: $e');
        _remoteCandidateQueue.add(candidate); // Re-queue if it still fails
      }
    }
  }

  // ─────────────────────────────────────────────
  // END CALL
  // ─────────────────────────────────────────────

  Future<void> endCall({
    required String conversationId,
    String? messageId,
    required ChatSocketRepository repository,
  }) async {
    repository.emit('message', {
      'type': 'call_hangup',
      'conversation_id': conversationId,
      'message_id': messageId,
    });
    _callSignalController.add(CallSignalState.ended);
    await cleanup();
    debugPrint('WebRTC: call_hangup sent — call ended');
  }

  // ─────────────────────────────────────────────
  // TOGGLE AUDIO MUTE
  // ─────────────────────────────────────────────

  void toggleMute(bool mute) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !mute;
    });
  }

  // ─────────────────────────────────────────────
  // TOGGLE VIDEO
  // ─────────────────────────────────────────────

  void toggleVideo(bool disable) {
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = !disable;
    });
  }

  // ─────────────────────────────────────────────
  // SWITCH CAMERA
  // ─────────────────────────────────────────────

  Future<void> switchCamera() async {
    try {
      final videoTrack = _localStream?.getVideoTracks().firstOrNull;
      if (videoTrack != null) {
        await Helper.switchCamera(videoTrack);
      }
    } catch (e) {
      debugPrint('WebRTC: switchCamera failed: $e');
    }
  }

  // ─────────────────────────────────────────────
  // TOGGLE SPEAKER
  // ─────────────────────────────────────────────

  Future<void> toggleSpeaker(bool speakerOn) async {
    try {
      // Ensure we are in communication mode before toggling speaker
      // Note: setAudioMode is being handled by the plugin or not available in this version
      await Helper.setSpeakerphoneOn(speakerOn);
      debugPrint('WebRTC: Speakerphone set to $speakerOn');
    } catch (e) {
      debugPrint('WebRTC: toggleSpeaker failed: $e');
    }
  }

  // ─────────────────────────────────────────────
  // MID-CALL SWITCHING
  // ─────────────────────────────────────────────

  Future<void> requestCallSwitch({
    required String callType,
    required ChatSocketRepository repository,
  }) async {
    if (_peerConnection == null || _activeConversationId == null) return;
    
    // Switch media stream
    final isVideo = callType == 'video';
    final newStream = await _getUserMedia(isVideo: isVideo);
    
    // Replace tracks
    final senders = await _peerConnection!.getSenders();
    for (var track in newStream.getTracks()) {
      final senderIndex = senders.indexWhere((s) => s.track?.kind == track.kind);
      if (senderIndex != -1) {
        await senders[senderIndex].replaceTrack(track);
      } else {
        await _peerConnection!.addTrack(track, newStream);
      }
    }
    
    // Cleanup old stream
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream = newStream;
    localRenderer.srcObject = _localStream;
    _localStreamController.add(_localStream);

    // Create new offer
    final offer = await _peerConnection!.createOffer(_offerConstraints);
    await _peerConnection!.setLocalDescription(offer);

    // Send request
    repository.emit('message', {
      'type': 'call_switch_request',
      'conversation_id': _activeConversationId,
      'call_type': callType,
      'sdp': {
        'type': offer.type,
        'sdp': offer.sdp,
      }
    });
  }

  Future<void> acceptCallSwitch({
    required bool isVideo,
    required ChatSocketRepository repository,
    Map<String, dynamic>? remoteOfferEvent,
    String? messageId,
  }) async {
    if (_peerConnection == null || _activeConversationId == null) return;
    
    // Set remote description if offer is provided
    if (remoteOfferEvent != null && remoteOfferEvent['sdp'] != null) {
      final sdpData = remoteOfferEvent['sdp'];
      final remoteOffer = RTCSessionDescription(sdpData['sdp'], sdpData['type']);
      await _peerConnection!.setRemoteDescription(remoteOffer);
    }
    
    // Get new media stream based on the requested switch
    final newStream = await _getUserMedia(isVideo: isVideo);
    
    // Replace tracks on existing peer connection
    final senders = await _peerConnection!.getSenders();
    for (var track in newStream.getTracks()) {
      final senderIndex = senders.indexWhere((s) => s.track?.kind == track.kind);
      if (senderIndex != -1) {
        await senders[senderIndex].replaceTrack(track);
      } else {
        await _peerConnection!.addTrack(track, newStream);
      }
    }
    
    // Cleanup old stream
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream = newStream;
    localRenderer.srcObject = _localStream;
    _localStreamController.add(_localStream);
    
    // Create new answer
    final answer = await _peerConnection!.createAnswer(_offerConstraints);
    await _peerConnection!.setLocalDescription(answer);

    final payload = <String, dynamic>{
      'type': 'call_switch_response',
      'conversation_id': _activeConversationId,
      'accepted': true,
      'call_type': isVideo ? 'video' : 'audio',
      'sdp': {
        'type': answer.type,
        'sdp': answer.sdp,
      },
    };
    if (messageId != null) payload['message_id'] = messageId;
    
    repository.emit('message', payload);
  }

  void rejectCallSwitch({
    required ChatSocketRepository repository,
    String? messageId,
  }) {
    if (_activeConversationId == null) return;
    
    final payload = <String, dynamic>{
      'type': 'call_switch_response',
      'conversation_id': _activeConversationId,
      'accepted': false,
    };
    if (messageId != null) payload['message_id'] = messageId;

    repository.emit('message', payload);
  }

  Future<void> handleCallSwitchResponded(Map<String, dynamic> event) async {
    final accepted = event['accepted'] == true || event['status'] == 'accepted';
    if (accepted) {
      final sdpData = event['sdp'] as Map<String, dynamic>?;
      if (sdpData != null && _peerConnection != null) {
        final answer = RTCSessionDescription(sdpData['sdp'], sdpData['type']);
        await _peerConnection!.setRemoteDescription(answer);
        await _processRemoteCandidateQueue();
      }
      
      // Update local stream if we requested switch
      final newType = event['call_type'] as String?;
      if (newType != null) {
        final isVideo = newType == 'video';
        // We already replaced tracks in requestCallSwitch, but just in case we need to refresh UI:
        debugPrint('WebRTC: Switch to $newType accepted');
      }
    } else {
      // Remote rejected the switch.
      debugPrint('WebRTC: Remote party rejected the switch');
    }
  }

  // ─────────────────────────────────────────────
  // CLEANUP
  // ─────────────────────────────────────────────

  Future<void> cleanup() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    if (_renderersInitialized) {
      try {
        localRenderer.srcObject = null;
        remoteRenderer.srcObject = null;
      } catch (e) {
        debugPrint('WebRTC: Error resetting renderers during cleanup: $e');
      }
    }

    _localStream?.getTracks().forEach((track) => track.stop());
    await _localStream?.dispose();
    _localStream = null;

    _remoteStream?.getTracks().forEach((track) => track.stop());
    await _remoteStream?.dispose();
    _remoteStream = null;

    await _peerConnection?.close();
    _peerConnection = null;
    _activeConversationId = null;
    _remoteCandidateQueue.clear();

    _localStreamController.add(null);
    _remoteStreamController.add(null);

    debugPrint('WebRTC: Cleanup complete');
  }

  // ─────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────

  Future<MediaStream> _getUserMedia({required bool isVideo}) async {
    final constraints = <String, dynamic>{
      'audio': true,
      'video': isVideo
          ? {
              'width': {'ideal': 640},
              'height': {'ideal': 480},
              'frameRate': {'ideal': 30},
              'facingMode': 'user',
            }
          : false,
    };
    try {
      return await navigator.mediaDevices.getUserMedia(constraints);
    } catch (e) {
      debugPrint('WebRTC: getUserMedia failed with constraints $constraints: $e');
      if (isVideo) {
        debugPrint('WebRTC: Retrying getUserMedia with standard video constraints...');
        try {
          return await navigator.mediaDevices.getUserMedia({
            'audio': true,
            'video': true,
          });
        } catch (e2) {
          debugPrint('WebRTC: Retrying getUserMedia with audio-only fallback...');
          return await navigator.mediaDevices.getUserMedia({
            'audio': true,
            'video': false,
          });
        }
      }
      rethrow;
    }
  }

  void _attachLocalTracks() {
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });
  }

  void _setupConnectionCallbacks(ChatSocketRepository repository) {
    // Send ICE candidates to the other peer via signaling
    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        repository.emit('message', {
          'type': 'ice_candidate',
          'conversation_id': _activeConversationId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      }
    };

    // Receive remote media track → render on remote renderer
    _peerConnection?.onTrack = (RTCTrackEvent event) {
      debugPrint('WebRTC: onTrack event - streams: ${event.streams.length}');
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        remoteRenderer.srcObject = _remoteStream;
        _remoteStreamController.add(_remoteStream);
        
        // Ensure ALL tracks are enabled
        _remoteStream?.getTracks().forEach((track) {
          debugPrint('WebRTC: Remote track: ${track.kind}, id: ${track.id}, enabled: ${track.enabled}');
          track.enabled = true;
        });

        _callSignalController.add(CallSignalState.active);
        debugPrint('WebRTC: Remote track received — rendering remote stream');
      }
    };

    _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint('WebRTC ICE State: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        if (_reconnectTimer == null) {
          debugPrint('WebRTC: Connection disrupted. Starting 30-second reconnection timer.');
          _reconnectTimer = Timer(const Duration(seconds: 30), () {
            debugPrint('WebRTC: Reconnection timer expired. Ending call.');
            _callSignalController.add(CallSignalState.ended);
          });
        }
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
                 state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        if (_reconnectTimer != null) {
          debugPrint('WebRTC: Connection restored. Reconnection timer cancelled.');
          _reconnectTimer?.cancel();
          _reconnectTimer = null;
        }
      }
    };

    // Also monitor internet connectivity state changes during the call
    _connectivitySubscription?.cancel();
    _connectivitySubscription = getIt<ConnectivityRepository>().onConnectivityChanged.listen((result) {
      final connected = result.any((r) => r != ConnectivityResult.none);
      debugPrint('WebRTC: Network status changed during call. Connected = $connected');
      if (!connected) {
        if (_reconnectTimer == null) {
          debugPrint('WebRTC: Network offline. Starting 30-second reconnection timer.');
          _reconnectTimer = Timer(const Duration(seconds: 30), () {
            debugPrint('WebRTC: Reconnection timer expired due to network loss. Ending call.');
            _callSignalController.add(CallSignalState.ended);
          });
        }
      } else {
        // Network reconnected
        if (_peerConnection != null) {
          _peerConnection!.getIceConnectionState().then((iceState) {
            if (iceState == RTCIceConnectionState.RTCIceConnectionStateConnected ||
                iceState == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
              if (_reconnectTimer != null) {
                debugPrint('WebRTC: Network online and ICE connected. Reconnection timer cancelled.');
                _reconnectTimer?.cancel();
                _reconnectTimer = null;
              }
            } else {
              // Wait up to 30s from the original disconnect event, WebRTC peer connection will perform ICE restart/reconnect automatically
              debugPrint('WebRTC: Network online but ICE state is $iceState. Reconnection timer remains active.');
            }
          });
        } else {
          // If PeerConnection was already cleared, stop timer
          _reconnectTimer?.cancel();
          _reconnectTimer = null;
        }
      }
    });
  }

  // Dispose all stream controllers (call when app closes)
  void disposeStreams() {
    _localStreamController.close();
    _remoteStreamController.close();
    _callSignalController.close();
  }
}
