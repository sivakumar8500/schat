import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

    // 1. Download and obtain the raw/decrypted file
    final normalFile = await secureService.getDecryptedTempFileForViewing(
      url: url,
      fileName: fileName,
    );

    if (!await normalFile.exists()) {
      throw Exception('Failed to download or decrypt attachment');
    }

    final bytes = await normalFile.readAsBytes();

    var cleanName = fileName.trim();
    if (cleanName.contains('?')) {
      cleanName = cleanName.split('?').first.trim();
    }
    if (cleanName.contains('/')) {
      cleanName = cleanName.split('/').last.trim();
    }
    while (cleanName.toLowerCase().endsWith('.enc')) {
      cleanName = cleanName.substring(0, cleanName.length - 4);
    }
    if (cleanName.isEmpty) cleanName = 'downloaded_file';

    File? savedPublicFile;

    // 2. Save to public /storage/emulated/0/Download/Schat on Android
    if (Platform.isAndroid) {
      try {
        final schatDir = Directory('/storage/emulated/0/Download/Schat');
        if (!await schatDir.exists()) {
          await schatDir.create(recursive: true);
        }
        final target = File('${schatDir.path}/$cleanName');
        await target.writeAsBytes(bytes, flush: true);
        savedPublicFile = target;
        debugPrint('downloadFile: Saved directly to public path -> ${target.path}');
      } catch (e) {
        debugPrint('downloadFile: Direct save error: $e');
      }

      // 3. Also invoke native MediaStore.Downloads via channel to guarantee visibility on Android 10+
      try {
        const channel = MethodChannel('com.sdpi.schat/screenshot_detector');
        final ext = cleanName.contains('.') ? cleanName.split('.').last.toLowerCase() : '';
        final mimeType = SecureAttachmentService.getMimeTypeForExtension(ext);
        final String? nativeSavedPath = await channel.invokeMethod<String>('saveFileToDownloads', {
          'bytes': bytes,
          'fileName': cleanName,
          'mimeType': mimeType,
        });
        if (nativeSavedPath != null && nativeSavedPath.isNotEmpty) {
          final f = File(nativeSavedPath);
          if (await f.exists()) {
            savedPublicFile = f;
          }
        }
      } catch (e) {
        debugPrint('downloadFile: Native MediaStore channel error: $e');
      }

      // 4. Trigger MediaScanner
      if (savedPublicFile != null) {
        try {
          if (getIt.isRegistered<ScreenProtectionService>()) {
            await getIt<ScreenProtectionService>().scanFile(savedPublicFile.path);
          }
        } catch (_) {}
      }
    }

    // Keep cached in persistent storage
    try {
      await secureService.saveToPersistentStorage(
        originalPath: savedPublicFile?.path ?? normalFile.path,
        fileName: cleanName,
        bytes: bytes,
      );
    } catch (_) {}

    return savedPublicFile ?? normalFile;
  } catch (e) {
    debugPrint('Error downloading secure attachment: $e');
    return null;
  }
}

