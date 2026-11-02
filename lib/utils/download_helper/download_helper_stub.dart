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

    // 1. Download and securely encrypt the attachment with AES-256 following the .enc encryption flow
    final encryptedFile = await secureService.downloadAndEncryptAttachment(
      url: url,
      fileName: fileName,
      onProgress: onProgress,
    );

    if (!await encryptedFile.exists()) {
      throw Exception('Failed to download and encrypt attachment');
    }

    final encryptedBytes = await encryptedFile.readAsBytes();

    // 2. Determine target .enc filename
    var cleanName = fileName.trim();
    if (cleanName.contains('?')) {
      cleanName = cleanName.split('?').first.trim();
    }
    if (cleanName.contains('/')) {
      cleanName = cleanName.split('/').last.trim();
    }
    if (cleanName.isEmpty || cleanName == 'File' || cleanName == 'downloaded_file') {
      final urlName = url.split('?').first.split('/').last.trim();
      if (urlName.isNotEmpty && urlName.contains('.')) {
        cleanName = urlName;
      } else {
        cleanName = encryptedFile.path.split('/').last;
      }
    }
    if (!cleanName.toLowerCase().endsWith('.enc')) {
      cleanName = '$cleanName.enc';
    }

    File? savedPublicFile;

    // 3. Save encrypted .enc file to public /storage/emulated/0/Download/Schat on Android
    if (Platform.isAndroid) {
      try {
        final schatDir = Directory('/storage/emulated/0/Download/Schat');
        if (!await schatDir.exists()) {
          await schatDir.create(recursive: true);
        }
        final target = File('${schatDir.path}/$cleanName');
        await target.writeAsBytes(encryptedBytes, flush: true);
        savedPublicFile = target;
        debugPrint('downloadFile: Saved encrypted .enc file to public path -> ${target.path}');
      } catch (e) {
        debugPrint('downloadFile: Direct save error: $e');
      }

      // 4. Also invoke native MediaStore.Downloads via channel to guarantee visibility on Android 10+
      try {
        const channel = MethodChannel('com.sdpi.schat/screenshot_detector');
        final String? nativeSavedPath = await channel.invokeMethod<String>('saveFileToDownloads', {
          'bytes': encryptedBytes,
          'fileName': cleanName,
          'mimeType': 'application/octet-stream',
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

      // 5. Trigger MediaScanner
      if (savedPublicFile != null) {
        try {
          if (getIt.isRegistered<ScreenProtectionService>()) {
            await getIt<ScreenProtectionService>().scanFile(savedPublicFile.path);
          }
        } catch (_) {}
      }
    }

    final effectiveFile = savedPublicFile ?? encryptedFile;

    // 6. Cache the local mapping for url, fileName, and cleanName
    SecureAttachmentService.cacheMediaMapping(key: url, localPath: effectiveFile.path);
    SecureAttachmentService.cacheMediaMapping(key: fileName, localPath: effectiveFile.path);
    SecureAttachmentService.cacheMediaMapping(key: cleanName, localPath: effectiveFile.path);

    // 7. Keep cached in persistent storage
    try {
      await secureService.saveToPersistentStorage(
        originalPath: effectiveFile.path,
        fileName: cleanName,
        bytes: encryptedBytes,
      );
    } catch (_) {}

    return effectiveFile;
  } catch (e) {
    debugPrint('Error downloading secure attachment: $e');
    return null;
  }
}

