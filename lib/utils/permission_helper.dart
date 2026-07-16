import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/injection.dart';

class PermissionHelper {
  PermissionHelper._();

  static Future<bool> checkCallPermissions({required bool isVideo}) async {
    if (kIsWeb) return true;
    final microphoneStatus = await Permission.microphone.request();
    
    if (microphoneStatus.isDenied || microphoneStatus.isPermanentlyDenied) {
      return false;
    }

    if (isVideo) {
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus.isDenied || cameraStatus.isPermanentlyDenied) {
        return false;
      }
    }

    return true;
  }

  /// Checks if all core onboarding permissions are granted
  static Future<bool> hasAllRequiredPermissions() async {
    if (kIsWeb) return true;
    final notification = await Permission.notification.isGranted;
    final contacts = await Permission.contacts.isGranted;
    final camera = await Permission.camera.isGranted;
    final microphone = await Permission.microphone.isGranted;
    return notification && contacts && camera && microphone;
  }

  /// Determines whether the permission screen should be shown
  static Future<bool> shouldShowPermissionsScreen() async {
    if (kIsWeb) return false;
    final storage = getIt<StorageService>();
    if (storage.hasSeenPermissions()) {
      return false;
    }
    final hasAll = await hasAllRequiredPermissions();
    return !hasAll;
  }
}
