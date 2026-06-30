import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  PermissionHelper._();

  static Future<bool> checkCallPermissions({required bool isVideo}) async {
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
}
