import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:screen_protector/screen_protector.dart';

@lazySingleton
class ScreenProtectionService {
  static const MethodChannel _androidScreenshotChannel =
      MethodChannel('com.sdpi.schat/screenshot_detector');

  final _screenshotController = StreamController<void>.broadcast();
  final _screenRecordController = StreamController<bool>.broadcast();

  Stream<void> get onScreenshot => _screenshotController.stream;
  Stream<bool> get onScreenRecord => _screenRecordController.stream;

  bool _isProtectionActive = true;
  bool get isProtectionActive => _isProtectionActive;

  Future<void> initialize() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    try {
      // By default, restrict screenshot and screen recording across the entire application
      await enableProtection();

      // iOS and general screen protector listeners
      ScreenProtector.addListener(
        () {
          _screenshotController.add(null);
        },
        (isCaptured) {
          _screenRecordController.add(isCaptured);
        },
      );

      // Android native screenshot detector listener
      if (Platform.isAndroid) {
        _androidScreenshotChannel.setMethodCallHandler((call) async {
          if (call.method == 'onScreenshot') {
            debugPrint('ScreenProtectionService: Android native screenshot detected');
            _screenshotController.add(null);
          }
        });
      }
    } catch (e) {
      debugPrint('ScreenProtection: Error initializing screen protection service: $e');
    }
  }

  Future<void> enableProtection() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    try {
      _isProtectionActive = true;
      await ScreenProtector.preventScreenshotOn();
      debugPrint('ScreenProtection: Screenshot & recording prevention enabled');
    } catch (e) {
      debugPrint('ScreenProtection: Error enabling screenshot prevention: $e');
    }
  }

  Future<void> disableProtection() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    try {
      _isProtectionActive = false;
      await ScreenProtector.preventScreenshotOff();
      debugPrint('ScreenProtection: Screenshot & recording prevention disabled');
    } catch (e) {
      debugPrint('ScreenProtection: Error disabling screenshot prevention: $e');
    }
  }

  /// Sets screen recording only mode on Android native layer so any screenshot
  /// attempted during recording time is immediately restricted and deleted.
  Future<void> setScreenRecordingMode(bool isRecording) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _androidScreenshotChannel.invokeMethod('setScreenRecordingMode', {
        'isRecording': isRecording,
      });
      debugPrint('ScreenProtection: setScreenRecordingMode($isRecording) applied');
    } catch (e) {
      debugPrint('ScreenProtection: Error setting screen recording mode: $e');
    }
  }

  /// Calls Android native layer to delete any screenshot file captured.
  Future<bool> deleteLastScreenshot() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final res = await _androidScreenshotChannel.invokeMethod<bool>('deleteLastScreenshot');
      debugPrint('ScreenProtection: deleteLastScreenshot() result=$res');
      return res ?? false;
    } catch (e) {
      debugPrint('ScreenProtection: Error deleting screenshot: $e');
      return false;
    }
  }

  void dispose() {
    ScreenProtector.removeListener();
    if (Platform.isAndroid) {
      _androidScreenshotChannel.setMethodCallHandler(null);
    }
    _screenshotController.close();
    _screenRecordController.close();
  }
}
