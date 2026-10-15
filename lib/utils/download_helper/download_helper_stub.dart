import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:schat/core/security/secure_attachment_service.dart';
import 'package:schat/core/security/screen_protection_service.dart';
import 'package:schat/injection.dart';

Future<File?> downloadFile(
  String url,
  String fileName, {
  void Function(int count, int total)? onProgress,
}) async {
  try {
    final secureService = getIt<SecureAttachmentService>();

    final encryptedFile = await secureService.downloadAndEncryptAttachment(
      url: url,
      fileName: fileName,
      onProgress: onProgress,
    );
    debugPrint('Attachment downloaded and securely encrypted at: ${encryptedFile.path}');
    try {
      if (getIt.isRegistered<ScreenProtectionService>()) {
        await getIt<ScreenProtectionService>().scanFile(encryptedFile.path);
      }
    } catch (_) {}
    return encryptedFile;
  } catch (e) {
    debugPrint('Error downloading secure attachment: $e');
    return null;
  }
}

