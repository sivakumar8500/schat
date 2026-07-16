import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:screen_protector/screen_protector.dart';

@lazySingleton
class ScreenProtectionService {
  final _screenshotController = StreamController<void>.broadcast();
  final _screenRecordController = StreamController<bool>.broadcast();

  Stream<void> get onScreenshot => _screenshotController.stream;
  Stream<bool> get onScreenRecord => _screenRecordController.stream;

  Future<void> initialize() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    
    try {
      ScreenProtector.addListener(
        () {
          debugPrint('ScreenProtection: Screenshot detected!');
          _screenshotController.add(null);
        },
        (isRecording) {
          debugPrint('ScreenProtection: Screen recording state: $isRecording');
          _screenRecordController.add(isRecording);
        },
      );
      
      final isRecording = await ScreenProtector.isRecording();
      if (isRecording) {
        _screenRecordController.add(true);
      }
    } catch (e) {
      debugPrint('ScreenProtection: Error initializing screen protector listeners: $e');
    }
  }

  Future<void> enableProtection() async {
    if (kIsWeb) return;
    try {
      await ScreenProtector.preventScreenshotOn();
      debugPrint('ScreenProtection: Screenshot prevention enabled');
    } catch (e) {
      debugPrint('ScreenProtection: Error enabling screenshot prevention: $e');
    }
  }

  Future<void> disableProtection() async {
    if (kIsWeb) return;
    try {
      await ScreenProtector.preventScreenshotOff();
      debugPrint('ScreenProtection: Screenshot prevention disabled');
    } catch (e) {
      debugPrint('ScreenProtection: Error disabling screenshot prevention: $e');
    }
  }

  void dispose() {
    _screenshotController.close();
    _screenRecordController.close();
    ScreenProtector.removeListener();
  }
}
