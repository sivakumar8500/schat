import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

class PhoneCallStateService {
  static const MethodChannel _channel =
      MethodChannel('com.sdpi.schat/phone_call_state');

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
