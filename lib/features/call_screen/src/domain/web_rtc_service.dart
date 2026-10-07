// mason make usecase --name web_rtc_service
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:schat/core/network/connectivity_repository.dart';
import 'package:schat/core/storage/storage_service.dart';
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

  // Multi-peer map for mesh connections in group calls
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, MediaStream> _remoteStreams = {};
  final Map<String, List<RTCIceCandidate>> _peerCandidateQueues = {};
  final Map<String, RTCVideoRenderer> _peerRenderers = {};

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  String? _activeConversationId;
  bool _renderersInitialized = false;
  bool _isCleaningUp = false;
  bool _isSwitchingCamera = false;
  bool _isTogglingSpeaker = false;
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
    'sdpSemantics': 'unified-plan',
    'bundlePolicy': 'max-bundle',
    'rtcpMuxPolicy': 'require',
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
    }
  }

  Future<RTCVideoRenderer> getOrCreatePeerRenderer(String peerId) async {
    if (_peerRenderers.containsKey(peerId)) {
      final existing = _peerRenderers[peerId]!;
      final stream = _remoteStreams[peerId];
      if (stream != null && existing.srcObject != stream) {
        existing.srcObject = stream;
      }
      return existing;
    }
    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    final stream = _remoteStreams[peerId];
    if (stream != null) {
      renderer.srcObject = stream;
    }
    _peerRenderers[peerId] = renderer;
    return renderer;
  }

  RTCVideoRenderer? getPeerRenderer(String peerId) {
    return _peerRenderers[peerId];
  }

  // ─────────────────────────────────────────────
  // MAKE CALL (Caller side)
  // ─────────────────────────────────────────────

  Future<void> makeCall({
    required String conversationId,
    required bool isVideo,
    required ChatSocketRepository repository,
    String? recipientId,
    String? callerName,
    String? profilePictureUrl,
    bool isGroup = false,
    String? groupName,
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

    final myId = getIt<StorageService>().getUserId()?.toString() ?? '';

    // 4. Send call_initiate over WebSocket signaling
    repository.emit('message', {
      'type': 'call_initiate',
      'conversation_id': conversationId,
      'call_type': isVideo ? 'video' : 'audio',
      'recipient_id': ?recipientId,
      'recipientId': ?recipientId,
      'sender_id': myId,
      'senderId': myId,
      'caller_name': callerName,
      'profile_picture_url': profilePictureUrl,
      'is_group': isGroup,
      'isGroup': isGroup,
      'group_name': ?groupName,
      'groupName': ?groupName,
      'offer': {
        'type': offer.type,
        'sdp': offer.sdp,
      },
    });

    debugPrint('WebRTC: call_initiate sent for conv=$conversationId (recipient=$recipientId, isGroup=$isGroup, sender=$myId)');
  }

  /// Retrieves the current local SDP offer or creates a new one for newly added/reinvited participants.
  Future<Map<String, dynamic>?> getCurrentOrNewOffer({bool? isVideo}) async {
    try {
      if (_peerConnection != null) {
        final localDesc = await _peerConnection!.getLocalDescription();
        if (localDesc != null && localDesc.sdp != null && localDesc.sdp!.isNotEmpty) {
          return {
            'type': localDesc.type,
            'sdp': localDesc.sdp,
          };
        }
        final offer = await _peerConnection!.createOffer(_offerConstraints);
        await _peerConnection!.setLocalDescription(offer);
        return {
          'type': offer.type,
          'sdp': offer.sdp,
        };
      } else {
        await initRenderers();
        if (_localStream == null) {
          _localStream = await _getUserMedia(isVideo: isVideo ?? false);
          localRenderer.srcObject = _localStream;
          _localStreamController.add(_localStream);
        }
        _peerConnection = await createPeerConnection(_peerConfig, _offerConstraints);
        _attachLocalTracks();
        if (getIt.isRegistered<ChatSocketRepository>()) {
          _setupConnectionCallbacks(getIt<ChatSocketRepository>());
        }
        final offer = await _peerConnection!.createOffer(_offerConstraints);
        await _peerConnection!.setLocalDescription(offer);
        return {
          'type': offer.type,
          'sdp': offer.sdp,
        };
      }
    } catch (e) {
      debugPrint('WebRTC: Error in getCurrentOrNewOffer: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // ANSWER CALL (Callee side)
  // ─────────────────────────────────────────────

  Future<void> answerCall({
    required Map<String, dynamic> incomingEvent,
    required ChatSocketRepository repository,
  }) async {
    final conversationId = (incomingEvent['conversation_id'] ?? incomingEvent['conversationId'] ?? '').toString();
    final messageId = incomingEvent['message_id'] ?? incomingEvent['messageId'];
    final callType = (incomingEvent['call_type'] ?? incomingEvent['callType']) as String? ?? 'audio';
    
    dynamic rawOffer = incomingEvent['offer'];
    Map<String, dynamic>? offerMap;
    if (rawOffer is Map) {
      offerMap = Map<String, dynamic>.from(rawOffer);
    } else if (rawOffer is String && rawOffer.isNotEmpty) {
      try {
        offerMap = jsonDecode(rawOffer) as Map<String, dynamic>?;
      } catch (e) {
        debugPrint('WebRTC: Error decoding offer string: $e');
      }
    }

    _activeConversationId = conversationId;

    await initRenderers();
    _callSignalController.add(CallSignalState.connecting);

    if (_peerConnection != null) {
      debugPrint('WebRTC: Disposing previous PeerConnection before answering new call');
      try {
        await _peerConnection!.close();
        await _peerConnection!.dispose();
      } catch (_) {}
      _peerConnection = null;
    }

    if (_localStream != null) {
      try {
        await _localStream!.dispose();
      } catch (_) {}
      _localStream = null;
    }

    // 1. Get callee's local media
    _localStream = await _getUserMedia(isVideo: callType == 'video');
    localRenderer.srcObject = _localStream;
    _localStreamController.add(_localStream);

    // 2. Create peer connection
    _peerConnection = await createPeerConnection(_peerConfig, _offerConstraints);
    _attachLocalTracks();
    _setupConnectionCallbacks(repository);

    Map<String, dynamic>? answerData;
    if (offerMap != null && offerMap['sdp'] != null && (offerMap['sdp'] as String).isNotEmpty) {
      // 3. Set remote description (the caller's SDP offer)
      final remoteOffer = RTCSessionDescription(offerMap['sdp'], offerMap['type'] ?? 'offer');
      await _peerConnection!.setRemoteDescription(remoteOffer);
      await _processRemoteCandidateQueue();

      // 4. Create and set local SDP answer
      final answer = await _peerConnection!.createAnswer(_offerConstraints);
      await _peerConnection!.setLocalDescription(answer);
      answerData = {
        'type': answer.type,
        'sdp': answer.sdp,
      };
    } else {
      // Fallback: If no remote offer was provided, generate local offer/description
      final offer = await _peerConnection!.createOffer(_offerConstraints);
      await _peerConnection!.setLocalDescription(offer);
      answerData = {
        'type': offer.type,
        'sdp': offer.sdp,
      };
    }

    final myId = getIt<StorageService>().getUserId()?.toString() ?? '';

    // 5. Send call_response with accept over WebSocket
    repository.emit('message', {
      'type': 'call_response',
      'conversation_id': conversationId,
      'message_id': messageId,
      'sender_id': myId,
      'senderId': myId,
      'response': 'accept',
      'answer': answerData,
    });

    debugPrint('WebRTC: call_response (accept) sent for conv=$conversationId from $myId');
  }

  // ─────────────────────────────────────────────
  // REJECT CALL
  // ─────────────────────────────────────────────

  Future<void> rejectCall({
    required String conversationId,
    String? messageId,
    required ChatSocketRepository repository,
    String reason = 'reject',
  }) async {
    final myId = getIt<StorageService>().getUserId()?.toString() ?? '';
    repository.emit('message', {
      'type': 'call_response',
      'conversation_id': conversationId,
      'message_id': messageId,
      'sender_id': myId,
      'senderId': myId,
      'response': reason,
      'answer': null,
    });
    _callSignalController.add(CallSignalState.rejected);
    await cleanup();
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
  // MESH PEER-TO-PEER GROUP SIGNALING
  // ─────────────────────────────────────────────

  Future<void> createOfferForPeer({
    required String peerId,
    required String conversationId,
    required ChatSocketRepository repository,
    bool isVideo = false,
  }) async {
    try {
      debugPrint('WebRTC: createOfferForPeer started for peerId=$peerId (isVideo=$isVideo)');
      final myId = getIt<StorageService>().getUserId()?.toString() ?? '';
      _localStream ??= await _getUserMedia(isVideo: isVideo);

      // Close previous connection to this specific peer if any
      if (_peerConnections.containsKey(peerId)) {
        try {
          await _peerConnections[peerId]?.close();
          await _peerConnections[peerId]?.dispose();
        } catch (_) {}
        _peerConnections.remove(peerId);
      }

      final pc = await createPeerConnection(_peerConfig, _offerConstraints);
      _peerConnections[peerId] = pc;
      
      _localStream?.getTracks().forEach((track) {
        pc.addTrack(track, _localStream!);
      });

      pc.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate.candidate != null) {
          repository.emit('message', {
            'type': 'ice_candidate',
            'conversation_id': conversationId,
            'target_user_id': peerId,
            'recipient_id': peerId,
            'sender_id': myId,
            'senderId': myId,
            'from': myId,
            'user_id': myId,
            'candidate': {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            },
          });
        }
      };

      pc.onIceConnectionState = (RTCIceConnectionState state) {
        debugPrint('WebRTC ICE State for peer $peerId: $state');
        if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
            state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
          try {
            pc.restartIce();
          } catch (e) {
            debugPrint('WebRTC: restartIce failed for peer $peerId: $e');
          }
        }
      };

      pc.onTrack = (RTCTrackEvent event) async {
        debugPrint('WebRTC: onTrack from mesh peer $peerId, streams: ${event.streams.length}, track kind: ${event.track.kind}');
        event.track.enabled = true;
        if (event.streams.isNotEmpty) {
          final stream = event.streams.first;
          _remoteStreams[peerId] = stream;
          for (var track in stream.getTracks()) {
            track.enabled = true;
          }
          final renderer = await getOrCreatePeerRenderer(peerId);
          renderer.srcObject = stream;
          _remoteStreamController.add(stream);
        }
        _callSignalController.add(CallSignalState.active);
      };

      final offer = await pc.createOffer(_offerConstraints);
      await pc.setLocalDescription(offer);

      repository.emit('message', {
        'type': 'call_offer',
        'conversation_id': conversationId,
        'target_user_id': peerId,
        'recipient_id': peerId,
        'sender_id': myId,
        'senderId': myId,
        'from': myId,
        'user_id': myId,
        'offer': {
          'type': offer.type,
          'sdp': offer.sdp,
        },
      });
      debugPrint('WebRTC: call_offer sent to mesh peer $peerId from $myId');
    } catch (e) {
      debugPrint('WebRTC: Error in createOfferForPeer: $e');
    }
  }

  Future<void> handlePeerOffer({
    required String peerId,
    required String conversationId,
    required Map<String, dynamic> offerMap,
    required ChatSocketRepository repository,
    bool isVideo = false,
  }) async {
    try {
      debugPrint('WebRTC: handlePeerOffer from peerId=$peerId (isVideo=$isVideo)');
      final myId = getIt<StorageService>().getUserId()?.toString() ?? '';
      _localStream ??= await _getUserMedia(isVideo: isVideo);

      if (_peerConnections.containsKey(peerId)) {
        try {
          await _peerConnections[peerId]?.close();
          await _peerConnections[peerId]?.dispose();
        } catch (_) {}
        _peerConnections.remove(peerId);
      }

      final pc = await createPeerConnection(_peerConfig, _offerConstraints);
      _peerConnections[peerId] = pc;

      _localStream?.getTracks().forEach((track) {
        pc.addTrack(track, _localStream!);
      });

      pc.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate.candidate != null) {
          repository.emit('message', {
            'type': 'ice_candidate',
            'conversation_id': conversationId,
            'target_user_id': peerId,
            'recipient_id': peerId,
            'sender_id': myId,
            'senderId': myId,
            'from': myId,
            'user_id': myId,
            'candidate': {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            },
          });
        }
      };

      pc.onIceConnectionState = (RTCIceConnectionState state) {
        debugPrint('WebRTC ICE State for peer $peerId: $state');
        if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
            state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
          try {
            pc.restartIce();
          } catch (e) {
            debugPrint('WebRTC: restartIce failed for peer $peerId: $e');
          }
        }
      };

      pc.onTrack = (RTCTrackEvent event) async {
        debugPrint('WebRTC: onTrack from mesh peer $peerId, streams: ${event.streams.length}, track kind: ${event.track.kind}');
        event.track.enabled = true;
        if (event.streams.isNotEmpty) {
          final stream = event.streams.first;
          _remoteStreams[peerId] = stream;
          for (var track in stream.getTracks()) {
            track.enabled = true;
          }
          final renderer = await getOrCreatePeerRenderer(peerId);
          renderer.srcObject = stream;
          _remoteStreamController.add(stream);
        }
        _callSignalController.add(CallSignalState.active);
      };

      final remoteOffer = RTCSessionDescription(offerMap['sdp'], offerMap['type'] ?? 'offer');
      await pc.setRemoteDescription(remoteOffer);

      // Process any queued candidates for this peer
      final queued = _peerCandidateQueues[peerId];
      if (queued != null && queued.isNotEmpty) {
        for (final c in queued) {
          try {
            await pc.addCandidate(c);
          } catch (e) {
            debugPrint('WebRTC: Error adding queued candidate to peer $peerId: $e');
          }
        }
        _peerCandidateQueues.remove(peerId);
      }

      final answer = await pc.createAnswer(_offerConstraints);
      await pc.setLocalDescription(answer);

      repository.emit('message', {
        'type': 'call_answer',
        'conversation_id': conversationId,
        'target_user_id': peerId,
        'recipient_id': peerId,
        'sender_id': myId,
        'senderId': myId,
        'from': myId,
        'user_id': myId,
        'answer': {
          'type': answer.type,
          'sdp': answer.sdp,
        },
      });
      debugPrint('WebRTC: call_answer sent to mesh peer $peerId from $myId');
    } catch (e) {
      debugPrint('WebRTC: Error in handlePeerOffer: $e');
    }
  }

  Future<void> handlePeerAnswer({
    required String peerId,
    required Map<String, dynamic> answerMap,
  }) async {
    try {
      debugPrint('WebRTC: handlePeerAnswer for peerId=$peerId');
      final pc = _peerConnections[peerId] ?? _peerConnection;
      if (pc == null) return;

      final remoteAnswer = RTCSessionDescription(answerMap['sdp'], answerMap['type'] ?? 'answer');
      await pc.setRemoteDescription(remoteAnswer);

      final queued = _peerCandidateQueues[peerId];
      if (queued != null && queued.isNotEmpty) {
        for (final c in queued) {
          try {
            await pc.addCandidate(c);
          } catch (e) {
            debugPrint('WebRTC: Error adding queued candidate to peer $peerId: $e');
          }
        }
        _peerCandidateQueues.remove(peerId);
      }
      _callSignalController.add(CallSignalState.active);
      debugPrint('WebRTC: Mesh connection with peer $peerId is ACTIVE');
    } catch (e) {
      debugPrint('WebRTC: Error in handlePeerAnswer: $e');
    }
  }

  Future<void> removePeer(String peerId) async {
    try {
      if (_peerConnections.containsKey(peerId)) {
        await _peerConnections[peerId]?.close();
        await _peerConnections[peerId]?.dispose();
        _peerConnections.remove(peerId);
      }
      if (_remoteStreams.containsKey(peerId)) {
        _remoteStreams[peerId]?.getTracks().forEach((t) {
          try {
            t.stop();
          } catch (_) {}
        });
        await _remoteStreams[peerId]?.dispose();
        _remoteStreams.remove(peerId);
      }
      if (_peerRenderers.containsKey(peerId)) {
        _peerRenderers[peerId]?.srcObject = null;
        await _peerRenderers[peerId]?.dispose();
        _peerRenderers.remove(peerId);
      }
      _peerCandidateQueues.remove(peerId);
      debugPrint('WebRTC: Successfully removed mesh peer $peerId');
    } catch (e) {
      debugPrint('WebRTC: Error removing peer $peerId: $e');
    }
  }

  // ─────────────────────────────────────────────
  // HANDLE REMOTE ICE CANDIDATE
  // ─────────────────────────────────────────────

  Future<void> handleRemoteIceCandidate(Map<String, dynamic> event) async {
    final candidateMap = event['candidate'] as Map<String, dynamic>?;
    if (candidateMap == null) return;
    final senderId = (event['sender_id'] ?? event['senderId'] ?? event['from'] ?? event['user_id'])?.toString() ?? '';

    final candidate = RTCIceCandidate(
      candidateMap['candidate'] as String,
      candidateMap['sdpMid'] as String?,
      candidateMap['sdpMLineIndex'] as int?,
    );

    final pc = senderId.isNotEmpty ? (_peerConnections[senderId] ?? _peerConnection) : _peerConnection;
    if (pc == null) {
      if (senderId.isNotEmpty) {
        _peerCandidateQueues.putIfAbsent(senderId, () => []).add(candidate);
      } else {
        _remoteCandidateQueue.add(candidate);
      }
      return;
    }

    try {
      await pc.addCandidate(candidate);
      debugPrint('WebRTC: Remote ICE candidate added for peer=$senderId');
    } catch (e) {
      debugPrint('WebRTC: Error adding remote ICE candidate for peer=$senderId: $e');
      if (senderId.isNotEmpty) {
        _peerCandidateQueues.putIfAbsent(senderId, () => []).add(candidate);
      } else {
        _remoteCandidateQueue.add(candidate);
      }
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
        _remoteCandidateQueue.add(candidate);
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
    final myId = getIt<StorageService>().getUserId()?.toString() ?? '';
    repository.emit('message', {
      'type': 'call_hangup',
      'conversation_id': conversationId,
      'message_id': messageId,
      'sender_id': myId,
      'senderId': myId,
      'user_id': myId,
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
    if (_isSwitchingCamera) {
      debugPrint('WebRTC: switchCamera skipped, already switching');
      return;
    }
    _isSwitchingCamera = true;
    try {
      final videoTrack = _localStream?.getVideoTracks().firstOrNull;
      if (videoTrack != null) {
        await Helper.switchCamera(videoTrack);
      }
    } catch (e) {
      debugPrint('WebRTC: switchCamera failed: $e');
    } finally {
      _isSwitchingCamera = false;
    }
  }

  // ─────────────────────────────────────────────
  // TOGGLE SPEAKER
  // ─────────────────────────────────────────────

  Future<void> toggleSpeaker(bool speakerOn) async {
    if (_isTogglingSpeaker) {
      debugPrint('WebRTC: toggleSpeaker skipped, already toggling');
      return;
    }
    _isTogglingSpeaker = true;
    try {
      await Helper.setSpeakerphoneOn(speakerOn);
      debugPrint('WebRTC: Speakerphone set to $speakerOn');
    } catch (e) {
      debugPrint('WebRTC: toggleSpeaker failed: $e');
    } finally {
      _isTogglingSpeaker = false;
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
    
    final isVideo = callType == 'video';
    try {
      if (isVideo) {
        if ((_localStream?.getVideoTracks() ?? []).isEmpty) {
          final videoStream = await navigator.mediaDevices.getUserMedia({
            'audio': false,
            'video': {
              'width': {'ideal': 640},
              'height': {'ideal': 480},
              'frameRate': {'ideal': 30},
              'facingMode': 'user',
            },
          });
          for (var track in videoStream.getVideoTracks()) {
            _localStream?.addTrack(track);
            await _peerConnection!.addTrack(track, _localStream!);
          }
        } else {
          for (var track in _localStream!.getVideoTracks()) {
            track.enabled = true;
          }
        }
      } else {
        for (var track in _localStream?.getVideoTracks() ?? []) {
          track.stop();
          _localStream?.removeTrack(track);
          final senders = await _peerConnection?.getSenders() ?? [];
          for (var sender in senders) {
            if (sender.track?.kind == 'video') {
              await _peerConnection?.removeTrack(sender);
            }
          }
        }
      }

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
    } catch (e) {
      debugPrint('WebRTC: Error in requestCallSwitch: $e');
    }
  }

  Future<void> acceptCallSwitch({
    required bool isVideo,
    required ChatSocketRepository repository,
    Map<String, dynamic>? remoteOfferEvent,
    String? messageId,
  }) async {
    if (_peerConnection == null || _activeConversationId == null) return;
    
    try {
      // Set remote description if offer is provided
      if (remoteOfferEvent != null && remoteOfferEvent['sdp'] != null) {
        final sdpData = remoteOfferEvent['sdp'];
        final remoteOffer = RTCSessionDescription(sdpData['sdp'], sdpData['type']);
        await _peerConnection!.setRemoteDescription(remoteOffer);
      }
      
      if (isVideo) {
        if ((_localStream?.getVideoTracks() ?? []).isEmpty) {
          final videoStream = await navigator.mediaDevices.getUserMedia({
            'audio': false,
            'video': {
              'width': {'ideal': 640},
              'height': {'ideal': 480},
              'frameRate': {'ideal': 30},
              'facingMode': 'user',
            },
          });
          for (var track in videoStream.getVideoTracks()) {
            _localStream?.addTrack(track);
            await _peerConnection!.addTrack(track, _localStream!);
          }
        } else {
          for (var track in _localStream!.getVideoTracks()) {
            track.enabled = true;
          }
        }
      } else {
        for (var track in _localStream?.getVideoTracks() ?? []) {
          track.stop();
          _localStream?.removeTrack(track);
          final senders = await _peerConnection?.getSenders() ?? [];
          for (var sender in senders) {
            if (sender.track?.kind == 'video') {
              await _peerConnection?.removeTrack(sender);
            }
          }
        }
      }

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
    } catch (e) {
      debugPrint('WebRTC: Error in acceptCallSwitch: $e');
    }
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
        debugPrint('WebRTC: Switch to $newType accepted (isVideo=$isVideo)');
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
    if (_isCleaningUp) {
      debugPrint('WebRTC: cleanup already in progress, skipping duplicate call');
      return;
    }
    _isCleaningUp = true;
    try {
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

      _localStream?.getTracks().forEach((track) {
        try {
          track.stop();
        } catch (_) {}
      });
      try {
        await _localStream?.dispose();
      } catch (_) {}
      _localStream = null;

      _remoteStream?.getTracks().forEach((track) {
        try {
          track.stop();
        } catch (_) {}
      });
      try {
        await _remoteStream?.dispose();
      } catch (_) {}
      _remoteStream = null;

      for (var stream in _remoteStreams.values) {
        stream.getTracks().forEach((track) {
          try {
            track.stop();
          } catch (_) {}
        });
        try {
          await stream.dispose();
        } catch (_) {}
      }
      _remoteStreams.clear();

      for (var renderer in _peerRenderers.values) {
        try {
          renderer.srcObject = null;
          await renderer.dispose();
        } catch (e) {
          debugPrint('WebRTC: Error disposing peer renderer: $e');
        }
      }
      _peerRenderers.clear();

      try {
        await _peerConnection?.close();
        await _peerConnection?.dispose();
      } catch (_) {}
      _peerConnection = null;

      for (var pc in _peerConnections.values) {
        try {
          await pc.close();
          await pc.dispose();
        } catch (_) {}
      }
      _peerConnections.clear();

      _activeConversationId = null;
      _remoteCandidateQueue.clear();
      _peerCandidateQueues.clear();

      _localStreamController.add(null);
      _remoteStreamController.add(null);

      debugPrint('WebRTC: Multi-peer cleanup complete');
    } finally {
      _isCleaningUp = false;
    }
  }

  // ─────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────

  Future<MediaStream> _getUserMedia({required bool isVideo}) async {
    final constraints = <String, dynamic>{
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
        'highpassFilter': true,
      },
      'video': isVideo
          ? {
              'mandatory': {
                'minWidth': '640',
                'minHeight': '480',
                'minFrameRate': '30',
              },
              'facingMode': 'user',
              'optional': [],
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
            'video': {
              'width': {'ideal': 640},
              'height': {'ideal': 480},
              'frameRate': {'ideal': 30},
              'facingMode': 'user',
            },
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
    final myId = getIt<StorageService>().getUserId()?.toString() ?? '';
    // Send ICE candidates to the other peer via signaling
    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        repository.emit('message', {
          'type': 'ice_candidate',
          'conversation_id': _activeConversationId,
          'sender_id': myId,
          'senderId': myId,
          'from': myId,
          'user_id': myId,
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
        try {
          _peerConnection?.restartIce();
        } catch (e) {
          debugPrint('WebRTC: restartIce failed: $e');
        }
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
