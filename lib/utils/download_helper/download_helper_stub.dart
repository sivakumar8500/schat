import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:schat/core/security/secure_attachment_service.dart';
import 'package:schat/injection.dart';

Future<File> saveFileToPublicDownloads(File sourceFile, String fileName) async {
  var cleanName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
  while (cleanName.endsWith('.enc')) {
    cleanName = cleanName.substring(0, cleanName.length - 4);
  }
  if (cleanName.isEmpty) cleanName = 'download_${DateTime.now().millisecondsSinceEpoch}';

  Directory? targetDir;
  if (!kIsWeb && Platform.isAndroid) {
    try {
      final publicDownload = Directory('/storage/emulated/0/Download');
      if (await publicDownload.exists()) {
        final schatFolder = Directory('/storage/emulated/0/Download/Schat');
        if (!await schatFolder.exists()) {
          await schatFolder.create(recursive: true);
        }
        targetDir = schatFolder;
      }
    } catch (_) {}
  }

  if (targetDir == null) {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final schatFolder = Directory('${appDir.path}/Schat');
      if (!await schatFolder.exists()) {
        await schatFolder.create(recursive: true);
      }
      targetDir = schatFolder;
    } catch (_) {
      targetDir = await getTemporaryDirectory();
    }
  }

  final destinationFile = File('${targetDir.path}/$cleanName');
  if (destinationFile.path != sourceFile.path) {
    await sourceFile.copy(destinationFile.path);
  }
  debugPrint('Saved clean file to: ${destinationFile.path}');
  return destinationFile;
}

Future<File?> downloadFile(
  String url,
  String fileName, {
  void Function(int count, int total)? onProgress,
}) async {
  try {
    final secureService = getIt<SecureAttachmentService>();

    final tempDecrypted = await secureService.getDecryptedTempFileForViewing(
      url: url,
      fileName: fileName,
    );

    if (onProgress != null) {
      onProgress(100, 100);
    }

    final publicFile = await saveFileToPublicDownloads(tempDecrypted, fileName);
    debugPrint('Attachment downloaded and saved to: ${publicFile.path}');
    return publicFile;
  } catch (e) {
    debugPrint('Error downloading secure attachment: $e');
    return null;
  }
}
