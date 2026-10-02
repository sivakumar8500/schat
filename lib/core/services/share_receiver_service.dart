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

  Future<void> _handleSharedMedia(List<SharedMediaFile> media) async {
    if (_isHandling) return;
    _isHandling = true;

    // Reset lock after a small delay to allow future shares
    Future.delayed(const Duration(seconds: 1), () {
      _isHandling = false;
    });

    // Wait for navigator to be mounted if app is just launching
    int retryCount = 0;
    while (navigatorKey.currentState == null && retryCount < 10) {
      await Future.delayed(const Duration(milliseconds: 300));
      retryCount++;
    }

    final navState = navigatorKey.currentState;
    if (navState == null) {
      debugPrint("ShareReceiverService: No navigator state available");
      return;
    }

    // Ensure the user is logged in before allowing sharing
    final storage = getIt<StorageService>();
    if (!storage.hasToken()) {
      debugPrint("ShareReceiverService: User is not authenticated. Share ignored.");
      return;
    }

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

    // Navigate to dedicated multi-select ShareForwardTargetPage
    navState.push(
      MaterialPageRoute(
        builder: (context) => ShareForwardTargetPage(
          mediaItems: mediaItems,
          sharedText: sharedText,
        ),
      ),
    );
  }
}
