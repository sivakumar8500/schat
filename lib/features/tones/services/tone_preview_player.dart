import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class TonePreviewPlayer {
  static final TonePreviewPlayer _instance = TonePreviewPlayer._internal();
  factory TonePreviewPlayer() => _instance;
  TonePreviewPlayer._internal() {
    _player.onPlayerComplete.listen((_) {
      _currentlyPlayingId = null;
      _onStateChangeCallback?.call(false);
    });
  }

  final AudioPlayer _player = AudioPlayer();
  String? _currentlyPlayingId;
  Function(bool isPlaying)? _onStateChangeCallback;

  String? get currentlyPlayingId => _currentlyPlayingId;

  /// Plays or stops a preview tone
  Future<void> playPreview({
    required String toneId,
    required String fileUrl,
    required Function(bool isPlaying) onStateChange,
  }) async {
    // If the same tone is already playing, toggle stop
    if (_currentlyPlayingId == toneId) {
      await stop();
      onStateChange(false);
      return;
    }

    try {
      await _player.stop();
      _onStateChangeCallback?.call(false);

      _currentlyPlayingId = toneId;
      _onStateChangeCallback = onStateChange;
      onStateChange(true);

      await _player.setVolume(1.0);
      await _player.setReleaseMode(ReleaseMode.stop);

      Source source;
      if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
        source = UrlSource(fileUrl);
      } else if (fileUrl.startsWith('assets/')) {
        source = AssetSource(fileUrl.replaceFirst('assets/', ''));
      } else {
        source = DeviceFileSource(fileUrl);
      }

      await _player.play(source);
    } catch (e) {
      debugPrint('TonePreviewPlayer: Error playing tone: $e');
      _currentlyPlayingId = null;
      onStateChange(false);
    }
  }

  Future<void> stop() async {
    _currentlyPlayingId = null;
    _onStateChangeCallback?.call(false);
    _onStateChangeCallback = null;
    try {
      await _player.stop();
    } catch (_) {}
  }

  void dispose() {
    _player.dispose();
  }
}
