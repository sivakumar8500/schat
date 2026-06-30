import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:schat/utils/common_colors.dart';
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
      if (kIsWeb) {
        viewerWidget = Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: createWebVideoView(url),
          ),
        );
      } else {
        viewerWidget = _MobileVideoPlayer(url: url);
      }
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
      if (kIsWeb) {
        viewerWidget = Container(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: createWebDocView(url),
          ),
        );
      } else {
        viewerWidget = _MobileDocumentViewer(url: url, fileName: fileName);
      }
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

class _MobileDocumentViewer extends StatefulWidget {
  final String url;
  final String fileName;
  const _MobileDocumentViewer({required this.url, required this.fileName});

  @override
  State<_MobileDocumentViewer> createState() => _MobileDocumentViewerState();
}

class _MobileDocumentViewerState extends State<_MobileDocumentViewer> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    String finalUrl = widget.url;
    
    // For mobile, most documents (PDF, DOCX) are best viewed via Google Docs Viewer
    // especially since Android WebView doesn't support PDF viewing natively.
    if (!widget.url.startsWith('file://')) {
      finalUrl = 'https://docs.google.com/viewer?url=${Uri.encodeComponent(widget.url)}&embedded=true';
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Error: ${error.description}');
            if (mounted) setState(() => _hasError = true);
          },
        ),
      )
      ..loadRequest(Uri.parse(finalUrl));
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Failed to load document in viewer.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => downloadFile(widget.url, widget.fileName),
              child: const Text('Download & Open Externally'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
      ],
    );
  }
}

class _MobileVideoPlayer extends StatefulWidget {
  final String url;
  const _MobileVideoPlayer({required this.url});

  @override
  State<_MobileVideoPlayer> createState() => _MobileVideoPlayerState();
}

class _MobileVideoPlayerState extends State<_MobileVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final isLocal = !kIsWeb && File(widget.url).existsSync();
      if (isLocal) {
        _controller = VideoPlayerController.file(File(widget.url));
      } else {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      }

      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
        _controller.setLooping(true);
      }
    } catch (e) {
      debugPrint('Video player initialization error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.white54, size: 64),
            SizedBox(height: 16),
            Text('Failed to play video', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        });
      },
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
            if (!_controller.value.isPlaying)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: Theme.of(context).primaryColor,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
