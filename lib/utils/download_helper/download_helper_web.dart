import 'dart:html' as html;
import 'package:flutter/foundation.dart';

Future<dynamic> downloadFile(
  String url,
  String fileName, {
  void Function(int count, int total)? onProgress,
}) async {
  try {
    debugPrint('download_helper_web: Downloading $fileName from $url');
    if (onProgress != null) onProgress(50, 100);

    if (url.startsWith('blob:') || url.startsWith('data:')) {
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..target = '_blank';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      if (onProgress != null) onProgress(100, 100);
      return null;
    }

    final request = await html.HttpRequest.request(
      url,
      responseType: 'blob',
    );

    final blob = request.response as html.Blob;
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: blobUrl)
      ..setAttribute("download", fileName)
      ..target = '_blank';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();

    if (onProgress != null) onProgress(100, 100);

    Future.delayed(const Duration(seconds: 10), () {
      html.Url.revokeObjectUrl(blobUrl);
    });
  } catch (e) {
    debugPrint('download_helper_web error: $e');
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..target = '_blank';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
  }
  return null;
}
