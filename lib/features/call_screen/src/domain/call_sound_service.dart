import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/storage/storage_service.dart';

@lazySingleton
class CallSoundService {
  final StorageService _storageService;
  final AudioPlayer _ringtonePlayer = AudioPlayer();
  final AudioPlayer _backRingPlayer = AudioPlayer();
  final AudioPlayer _messageTonePlayer = AudioPlayer();

  CallSoundService(this._storageService) {
    _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
    _backRingPlayer.setReleaseMode(ReleaseMode.loop);
    _messageTonePlayer.setReleaseMode(ReleaseMode.stop);
  }

  /// Play ringtone (for callee/receiver)
  Future<void> playRingtone({String? customRingtoneUrl}) async {
    try {
      await _ringtonePlayer.stop();
      await _ringtonePlayer.setVolume(1.0);

      final ringtoneUrl = customRingtoneUrl ?? _storageService.getCallRingtoneUrl();
      Source source;

      if (ringtoneUrl != null && ringtoneUrl.isNotEmpty) {
        if (ringtoneUrl.startsWith('http://') || ringtoneUrl.startsWith('https://')) {
          source = UrlSource(ringtoneUrl);
        } else if (ringtoneUrl.startsWith('assets/')) {
          source = AssetSource(ringtoneUrl.replaceFirst('assets/', ''));
        } else {
          source = DeviceFileSource(ringtoneUrl);
        }
        debugPrint('CallSoundService: Playing custom ringtone from $ringtoneUrl');
      } else {
        source = AssetSource('audio/ringing.mp3');
        debugPrint('CallSoundService: Playing default ringing.mp3');
      }

      await _ringtonePlayer.play(source);
    } catch (e) {
      debugPrint('CallSoundService: Error playing ringtone: $e. Falling back to asset ringing.mp3');
      try {
        await _ringtonePlayer.play(AssetSource('audio/ringing.mp3'));
      } catch (_) {}
    }
  }

  /// Play message notification sound
  Future<void> playMessageTone({String? customMessageToneUrl}) async {
    try {
      await _messageTonePlayer.stop();
      await _messageTonePlayer.setVolume(1.0);

      final toneUrl = customMessageToneUrl ?? _storageService.getMessageToneUrl();
      Source source;

      if (toneUrl != null && toneUrl.isNotEmpty) {
        if (toneUrl.startsWith('http://') || toneUrl.startsWith('https://')) {
          source = UrlSource(toneUrl);
        } else if (toneUrl.startsWith('assets/')) {
          source = AssetSource(toneUrl.replaceFirst('assets/', ''));
        } else {
          source = DeviceFileSource(toneUrl);
        }
        debugPrint('CallSoundService: Playing custom message tone from $toneUrl');
      } else {
        source = AssetSource('audio/message.mpeg');
        debugPrint('CallSoundService: Playing default message.mpeg');
      }

      await _messageTonePlayer.play(source);
    } catch (e) {
      debugPrint('CallSoundService: Error playing message tone: $e');
      try {
        await _messageTonePlayer.play(AssetSource('audio/message.mpeg'));
      } catch (_) {}
    }
  }

  /// Play back ring (for caller/sender)
  Future<void> playBackRing() async {
    try {
      await _backRingPlayer.stop();
      await _backRingPlayer.setVolume(1.0);
      final source = AssetSource('audio/calling.mpeg');
      await _backRingPlayer.play(source);
      debugPrint('CallSoundService: Playing calling.mpeg');
    } catch (e) {
      debugPrint('CallSoundService: Error playing calling.mpeg: $e');
    }
  }

  /// Stop all call sounds
  Future<void> stopAll() async {
    try {
      if (_ringtonePlayer.state != PlayerState.stopped) {
        await _ringtonePlayer.stop();
      }
      if (_backRingPlayer.state != PlayerState.stopped) {
        await _backRingPlayer.stop();
      }
      if (_messageTonePlayer.state != PlayerState.stopped) {
        await _messageTonePlayer.stop();
      }
      debugPrint('CallSoundService: Stopped all sounds');
    } catch (e) {
      debugPrint('CallSoundService: Error stopping sounds: $e');
    }
  }

  void dispose() {
    _ringtonePlayer.dispose();
    _backRingPlayer.dispose();
    _messageTonePlayer.dispose();
  }
}
