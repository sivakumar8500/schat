import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:schat/main.dart'; // For navigatorKey
import 'package:schat/injection.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/chat_screen/src/presentation/share_forward_target_page.dart';

class ShareReceiverService {
  static final ShareReceiverService _instance = ShareReceiverService._internal();
  factory ShareReceiverService() => _instance;
  ShareReceiverService._internal();

  StreamSubscription? _intentSub;
  bool _isHandling = false;
  bool _isShareScreenOpen = false;
  List<SharedMediaItem>? _pendingMediaItems;
  String? _pendingSharedText;

  bool get hasPendingShare =>
      (_pendingMediaItems != null && _pendingMediaItems!.isNotEmpty) ||
      (_pendingSharedText != null && _pendingSharedText!.isNotEmpty);

  bool get isShareScreenOpen => _isShareScreenOpen;

  void init() {
    // 1. Listen to media sharing when app is running (foreground/background)
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedMedia(value);
      }
    }, onError: (err) {
      debugPrint("ReceiveSharingIntent getMediaStream error: $err");
    });

    // 2. Handle sharing when app is opened from a closed state (cold start)
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedMedia(value);
      }
      ReceiveSharingIntent.instance.reset();
    }).catchError((err) {
      debugPrint("ReceiveSharingIntent getInitialMedia error: $err");
    });
  }

  void dispose() {
    _intentSub?.cancel();
  }

  void onShareScreenClosed() {
    _isShareScreenOpen = false;
    _pendingMediaItems = null;
    _pendingSharedText = null;
  }

  Future<void> _handleSharedMedia(List<SharedMediaFile> media) async {
    if (_isHandling) return;
    _isHandling = true;

    // Reset lock after a short delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      _isHandling = false;
    });

    final List<SharedMediaItem> mediaItems = [];
    String? sharedText;

    for (final item in media) {
      final String path = item.path;
      final typeStr = item.type.toString().toLowerCase();

      if (typeStr.contains('text') || typeStr.contains('url')) {
        sharedText = path;
      } else {
        String type = 'file';
        if (typeStr.contains('image')) {
          type = 'image';
        } else if (typeStr.contains('video')) {
          type = 'video';
        } else if (typeStr.contains('audio')) {
          type = 'audio';
        }

        String name = 'Shared File';
        try {
          name = Uri.parse(path).pathSegments.last;
        } catch (_) {
          name = path.split('/').last;
        }

        int size = 0;
        try {
          final f = File(path);
          if (f.existsSync()) {
            size = f.lengthSync();
          }
        } catch (_) {}

        mediaItems.add(SharedMediaItem(
          path: path,
          name: name,
          type: type,
          size: size,
        ));
      }
    }

    _pendingMediaItems = mediaItems;
    _pendingSharedText = sharedText;

    await checkAndPresentPendingShare();
  }

  Future<void> checkAndPresentPendingShare() async {
    if (!hasPendingShare) return;
    if (_isShareScreenOpen) return;

    // Ensure the user is logged in before allowing sharing
    final storage = getIt<StorageService>();
    if (!storage.hasToken()) {
      debugPrint("ShareReceiverService: User is not authenticated. Share ignored.");
      return;
    }

    // Wait for navigator to be mounted
    int retryCount = 0;
    while (navigatorKey.currentState == null && retryCount < 15) {
      await Future.delayed(const Duration(milliseconds: 200));
      retryCount++;
    }

    final navState = navigatorKey.currentState;
    if (navState == null) {
      debugPrint("ShareReceiverService: No navigator state available");
      return;
    }

    final mediaItems = List<SharedMediaItem>.from(_pendingMediaItems ?? []);
    final sharedText = _pendingSharedText;

    if (mediaItems.isEmpty && (sharedText == null || sharedText.isEmpty)) {
      return;
    }

    _isShareScreenOpen = true;

    // Push the ShareForwardTargetPage on top of whatever screen is currently active
    navState.push(
      MaterialPageRoute(
        builder: (context) => ShareForwardTargetPage(
          mediaItems: mediaItems,
          sharedText: sharedText,
        ),
      ),
    ).then((_) {
      _isShareScreenOpen = false;
      _pendingMediaItems = null;
      _pendingSharedText = null;
    });
  }
}
