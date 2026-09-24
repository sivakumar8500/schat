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
      // Ensure screenshot and screen recording restrictions are off across the entire app
      await disableProtection();
    } catch (e) {
      debugPrint('ScreenProtection: Error initializing screen protection service: $e');
    }
  }

  Future<void> enableProtection() async {
    // Disabled across all screens as requested
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
  }
}

