import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PhoneCallStateService {
  static const MethodChannel _channel =
      MethodChannel('com.sdpi.schat/phone_call_state');

  static final StreamController<void> _phoneCallStartedController =
      StreamController<void>.broadcast();
  static final StreamController<void> _phoneCallEndedController =
      StreamController<void>.broadcast();

  static Stream<void> get onPhoneCallStarted => _phoneCallStartedController.stream;
  static Stream<void> get onPhoneCallEnded => _phoneCallEndedController.stream;

  static bool _isInitialized = false;

  static void initialize() {
    if (_isInitialized || kIsWeb) return;
    _isInitialized = true;

    _channel.setMethodCallHandler((call) async {
      debugPrint('PhoneCallStateService: Native method received: ${call.method}');
      switch (call.method) {
        case 'onPhoneCallStarted':
          _phoneCallStartedController.add(null);
          break;
        case 'onPhoneCallEnded':
          _phoneCallEndedController.add(null);
          break;
      }
    });
  }

  /// Returns true if the device is currently in an active cellular phone call,
  /// another VoIP call, or system call ring.
  static Future<bool> isPhoneCallActive() async {
    if (kIsWeb) return false;

    try {
      // Check native system cellular/GSM call state
      final bool? isNativeActive =
          await _channel.invokeMethod<bool>('isPhoneCallActive');
      if (isNativeActive == true) {
        debugPrint('PhoneCallStateService: Native cellular/phone call detected active');
        return true;
      }
    } catch (e) {
      debugPrint('PhoneCallStateService: Error checking phone call state: $e');
    }

    return false;
  }
}
