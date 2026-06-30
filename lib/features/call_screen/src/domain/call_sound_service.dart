import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class CallSoundService {
  final AudioPlayer _ringtonePlayer = AudioPlayer();
  final AudioPlayer _backRingPlayer = AudioPlayer();

  CallSoundService() {
    _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
    _backRingPlayer.setReleaseMode(ReleaseMode.loop);
  }

  /// Play ringtone (for callee/receiver)
  Future<void> playRingtone() async {
    try {
      await _ringtonePlayer.stop();
      await _ringtonePlayer.setVolume(1.0);
      final source = AssetSource('audio/ringing.mp3');
      await _ringtonePlayer.play(source);
      debugPrint('CallSoundService: Playing ringing.mp3');
    } catch (e) {
      debugPrint('CallSoundService: Error playing ringing.mp3: $e');
    }
  }

  /// Play back ring (for caller/sender)
  Future<void> playBackRing() async {
    try {
      await _backRingPlayer.stop();
      await _backRingPlayer.setVolume(1.0);
      final source = AssetSource('audio/calling.mp3');
      await _backRingPlayer.play(source);
      debugPrint('CallSoundService: Playing calling.mp3');
    } catch (e) {
      debugPrint('CallSoundService: Error playing calling.mp3: $e');
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
      debugPrint('CallSoundService: Stopped all sounds');
    } catch (e) {
      debugPrint('CallSoundService: Error stopping sounds: $e');
    }
  }

  void dispose() {
    _ringtonePlayer.dispose();
    _backRingPlayer.dispose();
  }
}
