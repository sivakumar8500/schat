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
  MediaStream? get currentLocalStream => _localStream;
  MediaStream? get currentRemoteStream => _remoteStream;

  RTCPeerConnection? get peerConnection => _peerConnection;
  Map<String, RTCPeerConnection> get peerConnections => _peerConnections;

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

  static Map<String, dynamic> _getOfferConstraints({bool isVideo = false}) => {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': isVideo,
    },
    'optional': [],
  };

  // ─────────────────────────────────────────────
  // RENDERERS
  // ─────────────────────────────────────────────

  final Map<String, Future<RTCVideoRenderer>> _initializingPeerRenderers = {};

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
    if (_initializingPeerRenderers.containsKey(peerId)) {
      return await _initializingPeerRenderers[peerId]!;
    }
    final completer = Completer<RTCVideoRenderer>();
    _initializingPeerRenderers[peerId] = completer.future;
    try {
      final renderer = RTCVideoRenderer();
      await renderer.initialize();
      final stream = _remoteStreams[peerId];
      if (stream != null) {
        renderer.srcObject = stream;
      }
      _peerRenderers[peerId] = renderer;
      completer.complete(renderer);
      return renderer;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _initializingPeerRenderers.remove(peerId);
    }
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
    final offerConstraints = _getOfferConstraints(isVideo: isVideo);
    _peerConnection = await createPeerConnection(_peerConfig, offerConstraints);
    _attachLocalTracks();
    _setupConnectionCallbacks(repository);

    // 3. Create and set local SDP offer
    final offer = await _peerConnection!.createOffer(offerConstraints);
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
        final offerConstraints = _getOfferConstraints(isVideo: isVideo ?? false);
        _peerConnection = await createPeerConnection(_peerConfig, offerConstraints);
        _attachLocalTracks();
        if (getIt.isRegistered<ChatSocketRepository>()) {
          _setupConnectionCallbacks(getIt<ChatSocketRepository>());
        }
        final offer = await _peerConnection!.createOffer(offerConstraints);
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
    
    dynamic rawOffer = incomingEvent['offer'] ?? incomingEvent['sdp'] ?? incomingEvent['offer_sdp'] ?? incomingEvent['offerSdp'];
    if (rawOffer == null && incomingEvent['data'] is Map) {
      rawOffer = incomingEvent['data']['offer'] ?? incomingEvent['data']['sdp'] ?? incomingEvent['data']['offer_sdp'];
    }
    
    Map<String, dynamic>? offerMap;
    String? offerSdp;
    if (rawOffer is Map) {
      offerMap = Map<String, dynamic>.from(rawOffer);
      if (offerMap['offer'] is Map) {
        offerSdp = (offerMap['offer']['sdp'] ?? offerMap['offer']['description'])?.toString();
      } else if (offerMap['offer'] is String) {
        offerSdp = offerMap['offer'].toString();
      }
      offerSdp ??= (offerMap['sdp'] ?? offerMap['description'] ?? offerMap['offer_sdp'])?.toString();
    } else if (rawOffer is String && rawOffer.trim().isNotEmpty) {
      final trimmed = rawOffer.trim();
      if (trimmed.startsWith('{')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map) {
            offerMap = Map<String, dynamic>.from(decoded);
            if (offerMap['offer'] is Map) {
              offerSdp = (offerMap['offer']['sdp'] ?? offerMap['offer']['description'])?.toString();
            }
            offerSdp ??= (offerMap['sdp'] ?? offerMap['description'])?.toString();
          }
        } catch (e) {
          debugPrint('WebRTC: Error decoding offer string: $e');
        }
      }
      if (offerSdp == null && (trimmed.startsWith('v=') || trimmed.contains('v=0') || trimmed.contains('m=audio') || trimmed.contains('m=video'))) {
        offerSdp = trimmed;
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
    final isVideo = callType == 'video';
    final offerConstraints = _getOfferConstraints(isVideo: isVideo);
    _localStream = await _getUserMedia(isVideo: isVideo);
    localRenderer.srcObject = _localStream;
    _localStreamController.add(_localStream);

    // 2. Create peer connection
    _peerConnection = await createPeerConnection(_peerConfig, offerConstraints);
    _attachLocalTracks();
    _setupConnectionCallbacks(repository);

    Map<String, dynamic>? answerData;
    if (offerSdp != null && offerSdp.isNotEmpty) {
      // 3. Set remote description (the caller's SDP offer)
      final remoteOffer = RTCSessionDescription(offerSdp, 'offer');
      await _peerConnection!.setRemoteDescription(remoteOffer);
      await _processRemoteCandidateQueue();

      // 4. Create and set local SDP answer
      final answer = await _peerConnection!.createAnswer(offerConstraints);
      await _peerConnection!.setLocalDescription(answer);
      answerData = {
        'type': 'answer',
        'sdp': answer.sdp,
      };
    } else {
      debugPrint('WebRTC: Answering call without initial offer SDP. Leaving peerConnection in stable state to receive call_offer.');
      answerData = null;
    }

    final myId = getIt<StorageService>().getUserId()?.toString() ?? '';
    final targetId = (incomingEvent['sender_id'] ??
            incomingEvent['senderId'] ??
            incomingEvent['caller_id'] ??
            incomingEvent['callerId'] ??
            incomingEvent['user_id'] ??
            incomingEvent['userId'])
        ?.toString();

    final responsePayload = {
      'type': 'call_response',
      'conversation_id': conversationId,
      'message_id': messageId,
      'sender_id': myId,
      'senderId': myId,
      'recipient_id': targetId,
      'recipientId': targetId,
      'target_user_id': targetId,
      'receiver_id': targetId,
      'response': 'accept',
      'answer': answerData,
    };

    // 5. Send call_response and call_answered with accept over WebSocket
    repository.emit('message', responsePayload);
    repository.emit('message', {
      ...responsePayload,
      'type': 'call_answered',
    });

    debugPrint('WebRTC: call_response & call_answered (accept) sent for conv=$conversationId from $myId to $targetId');
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

  Future<void> handleCallAnswered(Map<String, dynamic> event, {ChatSocketRepository? repository}) async {
    final response = (event['response'] ?? event['action'] ?? '').toString().toLowerCase();
    if (response == 'reject' || response == 'rejected' || response == 'busy') {
      _callSignalController.add(
        response == 'busy' ? CallSignalState.busy : CallSignalState.rejected,
      );
      await cleanup();
      return;
    }

    dynamic answerRaw = event['answer'] ?? event['sdp'] ?? event['answer_sdp'] ?? event['answerSdp'];
    if (answerRaw == null && event['data'] is Map) {
      answerRaw = event['data']['answer'] ?? event['data']['sdp'] ?? event['data']['answer_sdp'];
    }

    Map<String, dynamic>? answerMap;
    String? sdp;
    if (answerRaw is Map) {
      answerMap = Map<String, dynamic>.from(answerRaw);
      if (answerMap['answer'] is Map) {
        sdp = (answerMap['answer']['sdp'] ?? answerMap['answer']['description'])?.toString();
      } else if (answerMap['answer'] is String) {
        sdp = answerMap['answer'].toString();
      }
      sdp ??= (answerMap['sdp'] ?? answerMap['description'] ?? answerMap['answer_sdp'])?.toString();
    } else if (answerRaw is String && answerRaw.trim().isNotEmpty) {
      final trimmed = answerRaw.trim();
      if (trimmed.startsWith('{')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map) {
            if (decoded['answer'] is Map) {
              sdp = (decoded['answer']['sdp'] ?? decoded['answer']['description'])?.toString();
            }
            sdp ??= (decoded['sdp'] ?? decoded['description'] ?? decoded['answer_sdp'])?.toString();
          }
        } catch (_) {}
      }
      if (sdp == null && (trimmed.startsWith('v=') || trimmed.contains('v=0') || trimmed.contains('m=audio') || trimmed.contains('m=video'))) {
        sdp = trimmed;
      }
    }

    if (sdp == null || sdp.isEmpty || _peerConnection == null) {
      debugPrint('WebRTC: handleCallAnswered: callee accepted without SDP answer. Sending call_offer to callee.');
      final currentOffer = await _peerConnection?.getLocalDescription();
      final targetId = (event['sender_id'] ?? event['senderId'] ?? event['from'] ?? event['user_id'])?.toString() ?? '';
      final myId = getIt<StorageService>().getUserId()?.toString() ?? '';
      final conversationId = (event['conversation_id'] ?? event['conversationId'] ?? _activeConversationId)?.toString() ?? '';
      if (currentOffer != null && currentOffer.sdp != null && targetId.isNotEmpty) {
        final repo = repository ?? getIt<ChatSocketRepository>();
        repo.emit('message', {
          'type': 'call_offer',
          'conversation_id': conversationId,
          'target_user_id': targetId,
          'recipient_id': targetId,
          'sender_id': myId,
          'senderId': myId,
          'from': myId,
          'offer': {
            'type': 'offer',
            'sdp': currentOffer.sdp,
          },
        });
        debugPrint('WebRTC: Re-sent call_offer to callee $targetId for conv=$conversationId');
      }
      return;
    }

    try {
      // Caller is receiving the answer from callee; remote description MUST always be set as 'answer'
      final remoteAnswer = RTCSessionDescription(sdp, 'answer');
      await _peerConnection!.setRemoteDescription(remoteAnswer);
      await _processRemoteCandidateQueue();
      _callSignalController.add(CallSignalState.active);
      debugPrint('WebRTC: Remote answer set successfully — call is ACTIVE');
    } catch (e, st) {
      debugPrint('WebRTC: Error setting remote description in handleCallAnswered: $e\n$st');
    }
  }

  // ─────────────────────────────────────────────
  // HANDLE OFFER FOR ACTIVE 1-TO-1 CALL
  // ─────────────────────────────────────────────

  Future<void> handleOfferForActiveCall({
    required Map<String, dynamic> offerMap,
    required String targetUserId,
    required String conversationId,
    required ChatSocketRepository repository,
    bool isVideo = false,
  }) async {
    try {
      dynamic rawOffer = offerMap['offer'] ?? offerMap['sdp'] ?? offerMap['description'] ?? offerMap;
      String? offerSdp;
      if (rawOffer is Map) {
        offerSdp = (rawOffer['sdp'] ?? rawOffer['description'])?.toString();
      } else if (rawOffer is String) {
        offerSdp = rawOffer;
      }

      if (offerSdp == null || offerSdp.isEmpty || _peerConnection == null) {
        debugPrint('WebRTC: handleOfferForActiveCall aborted: offerSdp=$offerSdp, pc=$_peerConnection');
        return;
      }

      debugPrint('WebRTC: handleOfferForActiveCall: Setting remote offer description from $targetUserId');
      final offerConstraints = _getOfferConstraints(isVideo: isVideo);
      final remoteOffer = RTCSessionDescription(offerSdp, 'offer');
      await _peerConnection!.setRemoteDescription(remoteOffer);
      await _processRemoteCandidateQueue();

      final answer = await _peerConnection!.createAnswer(offerConstraints);
      await _peerConnection!.setLocalDescription(answer);

      final myId = getIt<StorageService>().getUserId()?.toString() ?? '';
      repository.emit('message', {
        'type': 'call_answer',
        'conversation_id': conversationId,
        'sender_id': myId,
        'senderId': myId,
        'from': myId,
        'recipient_id': targetUserId,
        'target_user_id': targetUserId,
        'answer': {
          'type': 'answer',
          'sdp': answer.sdp,
        },
      });
      _callSignalController.add(CallSignalState.active);
      debugPrint('WebRTC: Answered active 1-to-1 call with call_answer to $targetUserId');
    } catch (e, st) {
      debugPrint('WebRTC: Error in handleOfferForActiveCall: $e\n$st');
    }
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

      final offerConstraints = _getOfferConstraints(isVideo: isVideo);
      final pc = await createPeerConnection(_peerConfig, offerConstraints);
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
        MediaStream? stream;
        if (event.streams.isNotEmpty) {
          stream = event.streams.first;
        } else {
          stream = _remoteStreams[peerId];
          if (stream == null) {
            try {
              stream = await createLocalMediaStream('remote_mesh_${peerId}_${DateTime.now().millisecondsSinceEpoch}');
            } catch (e) {
              debugPrint('WebRTC: Error creating local stream for peer $peerId: $e');
            }
          }
          if (stream != null) {
            try {
              stream.addTrack(event.track);
            } catch (_) {}
          }
        }
        if (stream != null) {
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

      pc.onAddStream = (MediaStream stream) async {
        debugPrint('WebRTC: onAddStream from mesh peer $peerId, stream id: ${stream.id}');
        _remoteStreams[peerId] = stream;
        for (var track in stream.getTracks()) {
          track.enabled = true;
        }
        final renderer = await getOrCreatePeerRenderer(peerId);
        renderer.srcObject = stream;
        _remoteStreamController.add(stream);
        _callSignalController.add(CallSignalState.active);
      };

      final offer = await pc.createOffer(offerConstraints);
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
          'type': 'offer',
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

      final offerConstraints = _getOfferConstraints(isVideo: isVideo);
      final pc = await createPeerConnection(_peerConfig, offerConstraints);
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
        MediaStream? stream;
        if (event.streams.isNotEmpty) {
          stream = event.streams.first;
        } else {
          stream = _remoteStreams[peerId];
          if (stream == null) {
            try {
              stream = await createLocalMediaStream('remote_mesh_${peerId}_${DateTime.now().millisecondsSinceEpoch}');
            } catch (e) {
              debugPrint('WebRTC: Error creating local stream for peer $peerId: $e');
            }
          }
          if (stream != null) {
            try {
              stream.addTrack(event.track);
            } catch (_) {}
          }
        }
        if (stream != null) {
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

      pc.onAddStream = (MediaStream stream) async {
        debugPrint('WebRTC: onAddStream from mesh peer $peerId, stream id: ${stream.id}');
        _remoteStreams[peerId] = stream;
        for (var track in stream.getTracks()) {
          track.enabled = true;
        }
        final renderer = await getOrCreatePeerRenderer(peerId);
        renderer.srcObject = stream;
        _remoteStreamController.add(stream);
        _callSignalController.add(CallSignalState.active);
      };

      final offerSdp = (offerMap['sdp'] ?? offerMap['description'])?.toString() ?? '';
      if (offerSdp.isNotEmpty) {
        final remoteOffer = RTCSessionDescription(offerSdp, 'offer');
        await pc.setRemoteDescription(remoteOffer);
      }

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

      final answer = await pc.createAnswer(offerConstraints);
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
          'type': 'answer',
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

      final answerSdp = (answerMap['sdp'] ?? answerMap['description'])?.toString() ?? '';
      if (answerSdp.isNotEmpty) {
        final remoteAnswer = RTCSessionDescription(answerSdp, 'answer');
        await pc.setRemoteDescription(remoteAnswer);
      }

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

    RTCPeerConnection? pc;
    if (senderId.isNotEmpty && _peerConnections.containsKey(senderId)) {
      pc = _peerConnections[senderId];
    } else if (senderId.isEmpty || _peerConnections.isEmpty) {
      pc = _peerConnection;
    }

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

  Future<void> _processRemoteCandidateQueue([String? peerId]) async {
    if (_peerConnection == null) return;

    if (_remoteCandidateQueue.isNotEmpty) {
      debugPrint('WebRTC: Processing ${_remoteCandidateQueue.length} queued ICE candidates on _peerConnection');
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

    if (peerId != null && peerId.isNotEmpty && _peerCandidateQueues.containsKey(peerId)) {
      final queued = _peerCandidateQueues.remove(peerId);
      if (queued != null && queued.isNotEmpty) {
        debugPrint('WebRTC: Processing ${queued.length} queued peer ICE candidates for $peerId on _peerConnection');
        for (final candidate in queued) {
          try {
            await _peerConnection!.addCandidate(candidate);
          } catch (e) {
            debugPrint('WebRTC: Error adding queued peer ICE candidate: $e');
            _peerCandidateQueues.putIfAbsent(peerId, () => []).add(candidate);
          }
        }
      }
    } else if (_peerCandidateQueues.isNotEmpty && _peerConnections.isEmpty) {
      final keys = List<String>.from(_peerCandidateQueues.keys);
      for (final key in keys) {
        final queued = _peerCandidateQueues.remove(key);
        if (queued != null && queued.isNotEmpty) {
          debugPrint('WebRTC: Processing ${queued.length} queued ICE candidates from peer queue $key on _peerConnection');
          for (final candidate in queued) {
            try {
              await _peerConnection!.addCandidate(candidate);
            } catch (e) {
              debugPrint('WebRTC: Error adding queued candidate: $e');
              _peerCandidateQueues.putIfAbsent(key, () => []).add(candidate);
            }
          }
        }
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
      _localStream?.getAudioTracks().forEach((track) {
        try {
          track.enableSpeakerphone(speakerOn);
        } catch (_) {}
      });
      _remoteStream?.getAudioTracks().forEach((track) {
        try {
          track.enableSpeakerphone(speakerOn);
        } catch (_) {}
      });
      for (final stream in _remoteStreams.values) {
        stream.getAudioTracks().forEach((track) {
          try {
            track.enableSpeakerphone(speakerOn);
          } catch (_) {}
        });
      }
      debugPrint('WebRTC: Speakerphone set to $speakerOn (updated ${_remoteStreams.length} mesh peers)');
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
            track.enabled = true;
            _localStream?.addTrack(track);
            if (_peerConnection != null) {
              await _peerConnection!.addTrack(track, _localStream!);
            }
            for (var pc in _peerConnections.values) {
              try {
                await pc.addTrack(track, _localStream!);
              } catch (_) {}
            }
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
          if (_peerConnection != null) {
            final senders = await _peerConnection!.getSenders();
            for (var sender in senders) {
              if (sender.track?.kind == 'video') {
                await _peerConnection!.removeTrack(sender);
              }
            }
          }
        }
      }

      localRenderer.srcObject = null;
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
      debugPrint('WebRTC: Sent call_switch_request with renegotiated video offer');
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
            track.enabled = true;
            _localStream?.addTrack(track);
            if (_peerConnection != null) {
              await _peerConnection!.addTrack(track, _localStream!);
            }
            for (var pc in _peerConnections.values) {
              try {
                await pc.addTrack(track, _localStream!);
              } catch (_) {}
            }
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
          if (_peerConnection != null) {
            final senders = await _peerConnection!.getSenders();
            for (var sender in senders) {
              if (sender.track?.kind == 'video') {
                await _peerConnection!.removeTrack(sender);
              }
            }
          }
        }
      }

      localRenderer.srcObject = null;
      localRenderer.srcObject = _localStream;
      _localStreamController.add(_localStream);

      // Set remote description if offer is provided
      if (remoteOfferEvent != null && remoteOfferEvent['sdp'] != null) {
        final sdpData = remoteOfferEvent['sdp'];
        final remoteOffer = RTCSessionDescription(sdpData['sdp'], sdpData['type']);
        await _peerConnection!.setRemoteDescription(remoteOffer);
        await _processRemoteCandidateQueue();
      }
      
      // Create new answer
      final answer = await _peerConnection!.createAnswer(_offerConstraints);
      await _peerConnection!.setLocalDescription(answer);

      final myId = getIt<StorageService>().getUserId()?.toString() ?? '';
      final payload = <String, dynamic>{
        'type': 'call_switch_response',
        'conversation_id': _activeConversationId,
        'sender_id': myId,
        'senderId': myId,
        'accepted': true,
        'call_type': isVideo ? 'video' : 'audio',
        'sdp': {
          'type': answer.type,
          'sdp': answer.sdp,
        },
      };
      if (messageId != null) payload['message_id'] = messageId;
      
      repository.emit('message', payload);
      debugPrint('WebRTC: acceptCallSwitch complete, sent call_switch_response');
    } catch (e) {
      debugPrint('WebRTC: Error in acceptCallSwitch: $e');
    }
  }

  void rejectCallSwitch({
    required ChatSocketRepository repository,
    String? messageId,
  }) {
    if (_activeConversationId == null) return;
    
    final myId = getIt<StorageService>().getUserId()?.toString() ?? '';
    final payload = <String, dynamic>{
      'type': 'call_switch_response',
      'conversation_id': _activeConversationId,
      'sender_id': myId,
      'senderId': myId,
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
        try {
          final state = await _peerConnection!.getSignalingState();
          if (state == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
            final answer = RTCSessionDescription(sdpData['sdp'], sdpData['type']);
            await _peerConnection!.setRemoteDescription(answer);
            await _processRemoteCandidateQueue();
          } else {
            debugPrint('WebRTC: Skipping setRemoteDescription in handleCallSwitchResponded (signalingState=$state)');
          }
        } catch (e) {
          debugPrint('WebRTC: Error setting remote answer in handleCallSwitchResponded: $e');
        }
      }
      
      // Ensure renderers refresh video texture
      if (_localStream != null) {
        localRenderer.srcObject = null;
        localRenderer.srcObject = _localStream;
        _localStreamController.add(_localStream);
      }
      if (_remoteStream != null) {
        remoteRenderer.srcObject = null;
        remoteRenderer.srcObject = _remoteStream;
        _remoteStreamController.add(_remoteStream);
      }
      _callSignalController.add(CallSignalState.active);
      debugPrint('WebRTC: Switch to video accepted and renderers refreshed');
    } else {
      debugPrint('WebRTC: Remote party rejected the switch');
    }
  }

  /// Restores audio and video tracks and sender pipeline after a cellular phone call or OS interruption
  Future<void> reacquireMediaAfterInterruption({
    required bool isVideo,
    required ChatSocketRepository repository,
    bool? isSpeakerOn,
  }) async {
    debugPrint('WebRTC: reacquireMediaAfterInterruption started (isVideo=$isVideo, isSpeakerOn=$isSpeakerOn)');
    if (_peerConnection == null) {
      debugPrint('WebRTC: Cannot reacquire media - peerConnection is null');
      return;
    }

    try {
      // 1. Cleanly stop old local stream and tracks
      if (_localStream != null) {
        for (var track in _localStream!.getTracks()) {
          try {
            track.stop();
          } catch (_) {}
        }
        try {
          await _localStream?.dispose();
        } catch (_) {}
        _localStream = null;
      }

      // 2. Re-acquire fresh getUserMedia
      _localStream = await _getUserMedia(isVideo: isVideo);
      localRenderer.srcObject = _localStream;
      _localStreamController.add(_localStream);

      // 3. Replace tracks on existing senders or re-add
      final senders = await _peerConnection!.getSenders();
      final audioTracks = _localStream!.getAudioTracks();
      final videoTracks = _localStream!.getVideoTracks();

      RTCRtpSender? audioSender;
      RTCRtpSender? videoSender;

      for (var sender in senders) {
        if (sender.track?.kind == 'audio') {
          audioSender = sender;
        } else if (sender.track?.kind == 'video') {
          videoSender = sender;
        }
      }

      if (audioTracks.isNotEmpty) {
        if (audioSender != null) {
          debugPrint('WebRTC: Replacing audio track on existing sender');
          await audioSender.replaceTrack(audioTracks.first);
        } else {
          debugPrint('WebRTC: Adding new audio track to peer connection');
          await _peerConnection!.addTrack(audioTracks.first, _localStream!);
        }
      }

      if (isVideo && videoTracks.isNotEmpty) {
        if (videoSender != null) {
          debugPrint('WebRTC: Replacing video track on existing sender');
          await videoSender.replaceTrack(videoTracks.first);
        } else {
          debugPrint('WebRTC: Adding new video track to peer connection');
          await _peerConnection!.addTrack(videoTracks.first, _localStream!);
        }
      }

      // 4. Restore audio mode and speakerphone
      final speaker = isSpeakerOn ?? isVideo;
      await toggleSpeaker(speaker);

      // 5. Trigger ICE restart to re-establish broken media transport
      try {
        await _peerConnection?.restartIce();
      } catch (e) {
        debugPrint('WebRTC: restartIce failed during reacquire: $e');
      }

      // 6. Broadcast socket event to other peer
      if (_activeConversationId != null) {
        repository.emit('message', {
          'type': 'call_media_restored',
          'conversation_id': _activeConversationId,
        });
      }

      debugPrint('WebRTC: reacquireMediaAfterInterruption completed successfully');
    } catch (e, st) {
      debugPrint('WebRTC: Error in reacquireMediaAfterInterruption: $e\n$st');
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
              'facingMode': 'user',
              'width': {'ideal': 640},
              'height': {'ideal': 480},
              'frameRate': {'ideal': 30},
            }
          : false,
    };
    try {
      final stream = await navigator.mediaDevices.getUserMedia(constraints);
      for (var track in stream.getAudioTracks()) {
        track.enabled = true;
      }
      return stream;
    } catch (e) {
      debugPrint('WebRTC: getUserMedia failed with constraints $constraints: $e');
      if (isVideo) {
        debugPrint('WebRTC: Retrying getUserMedia with standard video constraints...');
        try {
          final stream = await navigator.mediaDevices.getUserMedia({
            'audio': {
              'echoCancellation': true,
              'noiseSuppression': true,
              'autoGainControl': true,
            },
            'video': {
              'width': {'ideal': 640},
              'height': {'ideal': 480},
              'frameRate': {'ideal': 30},
              'facingMode': 'user',
            },
          });
          for (var track in stream.getAudioTracks()) {
            track.enabled = true;
          }
          return stream;
        } catch (e2) {
          debugPrint('WebRTC: Retrying getUserMedia with audio-only fallback...');
          final stream = await navigator.mediaDevices.getUserMedia({
            'audio': true,
            'video': false,
          });
          for (var track in stream.getAudioTracks()) {
            track.enabled = true;
          }
          return stream;
        }
      } else {
        debugPrint('WebRTC: Retrying pure audio getUserMedia...');
        final stream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': false,
        });
        for (var track in stream.getAudioTracks()) {
          track.enabled = true;
        }
        return stream;
      }
    }
  }

  void _attachLocalTracks() {
    _localStream?.getTracks().forEach((track) {
      track.enabled = true;
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
    _peerConnection?.onTrack = (RTCTrackEvent event) async {
      debugPrint('WebRTC: onTrack event - kind: ${event.track.kind}, id: ${event.track.id}, streams: ${event.streams.length}');
      event.track.enabled = true;
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
      } else {
        if (_remoteStream == null) {
          _remoteStream = await createLocalMediaStream('remote_stream_${DateTime.now().millisecondsSinceEpoch}');
        }
        _remoteStream?.addTrack(event.track);
      }
      if (_remoteStream != null) {
        for (var track in _remoteStream!.getTracks()) {
          track.enabled = true;
        }
        remoteRenderer.srcObject = null;
        remoteRenderer.srcObject = _remoteStream;
        _remoteStreamController.add(_remoteStream);
      }

      _callSignalController.add(CallSignalState.active);
      debugPrint('WebRTC: Remote track received (${event.track.kind}) — rendering remote stream');
    };

    _peerConnection?.onAddStream = (MediaStream stream) {
      debugPrint('WebRTC: onAddStream event - id: ${stream.id}, tracks: ${stream.getTracks().length}');
      _remoteStream = stream;
      for (var track in _remoteStream!.getTracks()) {
        track.enabled = true;
      }
      remoteRenderer.srcObject = null;
      remoteRenderer.srcObject = _remoteStream;
      _remoteStreamController.add(_remoteStream);
      _callSignalController.add(CallSignalState.active);
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
