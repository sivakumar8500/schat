import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
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

  /// Copies the latest screen recording video to Download/Schat folder
  Future<String?> saveLatestScreenRecordingToSchat({int? recordedSinceTimestamp}) async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final res = await _androidScreenshotChannel.invokeMethod<String>(
        'saveLatestScreenRecordingToSchat',
        {
          'recordedSinceTimestamp': recordedSinceTimestamp ??
              (DateTime.now().millisecondsSinceEpoch - 10 * 60 * 1000),
        },
      );
      debugPrint('ScreenProtection: saveLatestScreenRecordingToSchat() result=$res');
      return res;
    } catch (e) {
      debugPrint('ScreenProtection: Error saving screen recording to Schat: $e');
      return null;
    }
  }

  /// Triggers Android MediaScanner so newly copied/saved files appear immediately in Downloads and File Manager
  Future<bool> scanFile(String path, {String? mimeType}) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final res = await _androidScreenshotChannel.invokeMethod<bool>('scanFile', {
        'path': path,
        if (mimeType != null) 'mimeType': mimeType,
      });
      return res ?? false;
    } catch (e) {
      debugPrint('ScreenProtection: Error scanning file $path: $e');
      return false;
    }
  }

  /// Saves screenshot PNG bytes to local device storage (Pictures/Schat) and gallery
  Future<String?> saveScreenshot({
    required Uint8List bytes,
    String? fileName,
  }) async {
    if (kIsWeb) return null;
    try {
      if (Platform.isAndroid) {
        final res = await _androidScreenshotChannel.invokeMethod<String>(
          'saveScreenshot',
          {
            'bytes': bytes,
            'fileName': fileName,
          },
        );
        if (res != null && res.isNotEmpty) {
          debugPrint('ScreenProtection: Screenshot saved natively at $res');
          return res;
        }
      }

      // Fallback via path_provider or direct file
      Directory? targetDir;
      if (Platform.isAndroid) {
        final schatDir = Directory('/storage/emulated/0/Pictures/Schat');
        if (!await schatDir.exists()) {
          try {
            await schatDir.create(recursive: true);
          } catch (_) {}
        }
        if (await schatDir.exists()) {
          targetDir = schatDir;
        }
      }
      targetDir ??= await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();

      final actualFileName = fileName ??
          'Screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${targetDir.path}/$actualFileName');
      await file.writeAsBytes(bytes, flush: true);
      debugPrint('ScreenProtection: Screenshot saved via fallback at ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('ScreenProtection: Error saving screenshot: $e');
      return null;
    }
  }

  ScreenRecordingSession? _activeRecordingSession;
  ScreenRecordingSession? get activeRecordingSession => _activeRecordingSession;

  void setActiveRecordingSession(ScreenRecordingSession? session) {
    _activeRecordingSession = session;
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

class ScreenRecordingSession {
  final String permissionId;
  final String conversationId;
  final int totalDurationSeconds;
  int remainingSeconds;
  bool isPaused;
  bool isSystemRecordingStarted;
  final DateTime startedAt;
  final DateTime? expiresAt;

  ScreenRecordingSession({
    required this.permissionId,
    required this.conversationId,
    required this.totalDurationSeconds,
    required this.remainingSeconds,
    this.isPaused = false,
    this.isSystemRecordingStarted = false,
    required this.startedAt,
    this.expiresAt,
  });

  int get computedRemainingSeconds {
    return remainingSeconds > 0 ? remainingSeconds : 0;
  }
}
