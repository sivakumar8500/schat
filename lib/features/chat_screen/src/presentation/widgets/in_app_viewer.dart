import 'package:flutter/material.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/download_helper/download_helper.dart';
import 'package:schat/utils/platform_view_helper/platform_view_helper.dart';

class InAppViewer extends StatelessWidget {
  final String url;
  final String fileName;
  final String type; // 'image', 'video', 'audio', 'file'
  final bool allowShare;
  final bool allowDownload;
  final VoidCallback? onSharePressed;

  const InAppViewer({
    super.key,
    required this.url,
    required this.fileName,
    required this.type,
    this.allowShare = true,
    this.allowDownload = true,
    this.onSharePressed,
  });

  static void show(
    BuildContext context, {
    required String url,
    required String fileName,
    required String type,
    bool allowShare = true,
    bool allowDownload = true,
    VoidCallback? onSharePressed,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InAppViewer(
          url: url,
          fileName: fileName,
          type: type,
          allowShare: allowShare,
          allowDownload: allowDownload,
          onSharePressed: onSharePressed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget viewerWidget;

    if (type == 'image') {
      viewerWidget = InteractiveViewer(
        maxScale: 4.0,
        child: Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            },
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CommonIcons.brokenImage, color: Colors.white54, size: 64),
                  CommonSpaces.h16,
                  Text('Failed to load image', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (type == 'video') {
      viewerWidget = Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: createWebVideoView(url),
        ),
      );
    } else if (type == 'audio') {
      viewerWidget = Center(
        child: Card(
          color: Colors.grey.shade900,
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CommonIcons.audio, color: Colors.white70, size: 64),
                CommonSpaces.h16,
                Text(
                  fileName,
                  style: context.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                CommonSpaces.h24,
                createWebAudioView(url),
              ],
            ),
          ),
        ),
      );
    } else {
      // Document / other files
      viewerWidget = Container(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: createWebDocView(url),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CommonIcons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          fileName,
          style: context.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (allowShare && onSharePressed != null)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              tooltip: 'Share/Forward',
              onPressed: () {
                Navigator.pop(context);
                onSharePressed!();
              },
            ),
          if (allowDownload)
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              tooltip: 'Download',
              onPressed: () {
                downloadFile(url, fileName);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Downloading $fileName...')),
                );
              },
            ),
          CommonSpaces.w8,
        ],
      ),
      body: SafeArea(
        child: viewerWidget,
      ),
    );
  }
}
