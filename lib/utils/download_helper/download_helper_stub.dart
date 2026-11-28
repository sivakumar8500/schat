import 'dart:io';
import 'package:schat/core/services/background_download_service.dart';

Future<File?> downloadFile(
  String url,
  String fileName, {
  void Function(int count, int total)? onProgress,
}) async {
  return await BackgroundDownloadService.instance.download(
    url: url,
    fileName: fileName,
    onProgress: onProgress,
  );
}
