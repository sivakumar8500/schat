import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/download_helper/download_helper.dart';
import 'package:schat/utils/platform_view_helper/platform_view_helper.dart';

import 'package:schat/core/security/secure_attachment_service.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/media_protection_bottom_sheet.dart';
import 'package:schat/injection.dart';

class InAppViewer extends StatefulWidget {
  final String url;
  final String fileName;
  final String type; // 'image', 'video', 'audio', 'file'
  final String? mediaId;
  final bool allowShare;
  final bool allowDownload;
  final VoidCallback? onSharePressed;
  final VoidCallback? onDownloadPressed;

  const InAppViewer({
    super.key,
    required this.url,
    required this.fileName,
    required this.type,
    this.mediaId,
    this.allowShare = true,
    this.allowDownload = true,
    this.onSharePressed,
    this.onDownloadPressed,
  });

  static void show(
    BuildContext context, {
    required String url,
    required String fileName,
    required String type,
    String? mediaId,
    bool allowShare = true,
    bool allowDownload = true,
    VoidCallback? onSharePressed,
    VoidCallback? onDownloadPressed,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InAppViewer(
          url: url,
          fileName: fileName,
          type: type,
          mediaId: mediaId,
          allowShare: allowShare,
          allowDownload: allowDownload,
          onSharePressed: onSharePressed,
          onDownloadPressed: onDownloadPressed,
        ),
      ),
    );
  }

  @override
  State<InAppViewer> createState() => _InAppViewerState();
}

class _InAppViewerState extends State<InAppViewer> with SingleTickerProviderStateMixin {
  File? _decryptedTempFile;
  bool _isLoading = true;
  String? _errorMessage;

  final TransformationController _transformationController = TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _zoomAnimation;
  double _currentScale = 1.0;
  Offset? _doubleTapPosition;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
        if (_zoomAnimation != null) {
          _transformationController.value = _zoomAnimation!.value;
        }
      });
    _transformationController.addListener(_onTransformationChanged);
    _prepareAttachment();
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.04) {
      if (mounted) {
        setState(() {
          _currentScale = scale;
        });
      }
    }
  }

  void _animateToMatrix(Matrix4 targetMatrix) {
    _zoomAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward(from: 0);
  }

  void _zoomIn() {
    final double targetScale = (_currentScale * 1.5).clamp(1.0, 8.0);
    _zoomToScale(targetScale);
  }

  void _zoomOut() {
    final double targetScale = (_currentScale / 1.5).clamp(1.0, 8.0);
    _zoomToScale(targetScale);
  }

  void _resetZoom() {
    _animateToMatrix(Matrix4.identity());
  }

  void _zoomToScale(double targetScale) {
    final Matrix4 target = Matrix4.diagonal3Values(targetScale, targetScale, 1.0);
    _animateToMatrix(target);
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapPosition = details.localPosition;
  }

  void _handleDoubleTap() {
    if (_currentScale > 1.25) {
      _resetZoom();
    } else {
      final position = _doubleTapPosition ?? Offset.zero;
      const targetScale = 2.5;
      final x = -position.dx * (targetScale - 1);
      final y = -position.dy * (targetScale - 1);
      final Matrix4 target = Matrix4.identity()
        ..setTranslationRaw(x, y, 0.0)
        ..scaleByDouble(targetScale, targetScale, 1.0, 1.0);
      _animateToMatrix(target);
    }
  }

  Future<void> _prepareAttachment() async {
    try {
      if (kIsWeb) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final secureService = getIt<SecureAttachmentService>();
      final tempFile = await secureService.getDecryptedTempFileForViewing(
        url: widget.url,
        fileName: widget.fileName,
      );

      if (mounted) {
        setState(() {
          _decryptedTempFile = tempFile;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('InAppViewer preparation error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to decrypt attachment securely.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    if (_decryptedTempFile != null) {
      getIt<SecureAttachmentService>().cleanupTempFile(_decryptedTempFile);
    }
    super.dispose();
  }

  Widget _buildZoomControls() {
    final percent = (_currentScale * 100).round();
    const accentGreen = Color(0xFF00D084);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom out button
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.white, size: 22),
            tooltip: 'Zoom Out',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            onPressed: _currentScale > 1.05 ? _zoomOut : null,
          ),
          const SizedBox(width: 8),
          // Scale percentage indicator & tap to reset
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: _resetZoom,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$percent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Zoom in button
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 22),
            tooltip: 'Zoom In',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            onPressed: _currentScale < 7.95 ? _zoomIn : null,
          ),
          if (_currentScale > 1.15) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              height: 16,
              width: 1,
              color: Colors.white24,
            ),
            IconButton(
              icon: const Icon(Icons.fit_screen_rounded, color: accentGreen, size: 20),
              tooltip: 'Fit to Screen',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              onPressed: _resetZoom,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget viewerWidget;

    if (_isLoading) {
      viewerWidget = const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            CommonSpaces.h16,
            Text('Securing & Decrypting...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    } else if (_errorMessage != null) {
      viewerWidget = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_clock_outlined, color: Colors.white54, size: 64),
            CommonSpaces.h16,
            Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      );
    } else {
      final activePath = _decryptedTempFile?.path ?? widget.url;

      if (widget.type == 'image') {
        final isLocal = !kIsWeb && File(activePath).existsSync();
        viewerWidget = GestureDetector(
          onDoubleTapDown: _handleDoubleTapDown,
          onDoubleTap: _handleDoubleTap,
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 8.0,
            clipBehavior: Clip.none,
            child: Center(
              child: isLocal
                  ? Image.file(
                      File(activePath),
                      fit: BoxFit.contain,
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
                    )
                  : Image.network(
                      activePath,
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
          ),
        );
      } else if (widget.type == 'video') {
        if (kIsWeb) {
          viewerWidget = Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: createWebVideoView(activePath),
            ),
          );
        } else {
          viewerWidget = _MobileVideoPlayer(url: activePath);
        }
      } else if (widget.type == 'audio') {
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
                    widget.fileName,
                    style: context.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  CommonSpaces.h24,
                  createWebAudioView(activePath),
                ],
              ),
            ),
          ),
        );
      } else {
        // Document / other files
        final isPdf = widget.fileName.toLowerCase().endsWith('.pdf') || activePath.toLowerCase().endsWith('.pdf');
        if (kIsWeb) {
          viewerWidget = Container(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: createWebDocView(activePath),
            ),
          );
        } else if (isPdf) {
          viewerWidget = _InAppPdfViewer(
            filePath: activePath,
            fileName: widget.fileName,
          );
        } else {
          viewerWidget = _MobileDocumentViewer(
            url: activePath,
            fileName: widget.fileName,
            allowDownload: widget.allowDownload,
            onDownloadPressed: widget.onDownloadPressed,
          );
        }
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
          widget.fileName,
          style: context.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: Colors.white),
            tooltip: 'Security & Protection',
            onPressed: () {
              final idToUse = (widget.mediaId != null && widget.mediaId!.isNotEmpty)
                  ? widget.mediaId!
                  : '3fa85f64-5717-4562-b3fc-2c963f66afa6';
              MediaProtectionBottomSheet.show(
                context,
                mediaId: idToUse,
                fileName: widget.fileName,
              );
            },
          ),
          if (widget.allowShare && widget.onSharePressed != null)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              tooltip: 'Share/Forward',
              onPressed: () {
                Navigator.pop(context);
                widget.onSharePressed!();
              },
            ),
          if (widget.allowDownload)
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              tooltip: 'Download',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final primaryColor = context.colors.primary;

                messenger.showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 2),
                    content: Text('Downloading ${widget.fileName}: 0%'),
                  ),
                );

                final file = await downloadFile(
                  widget.url,
                  widget.fileName,
                  onProgress: (received, total) {
                    if (total > 0 && mounted) {
                      final pct = ((received / total) * 100).toInt();
                      messenger.hideCurrentSnackBar();
                      messenger.showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 1),
                          content: Text('Downloading ${widget.fileName}: $pct%'),
                        ),
                      );
                    }
                  },
                );

                if (widget.onDownloadPressed != null) {
                  widget.onDownloadPressed!();
                }

                if (mounted) {
                  messenger.hideCurrentSnackBar();
                  final savePath = file?.path ?? 'Schat secure storage';
                  messenger.showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 5),
                      backgroundColor: primaryColor,
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '✅ ${widget.fileName} (100%) Encrypted & Downloaded',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Saved to: $savePath',
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          CommonSpaces.w8,
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: viewerWidget,
            ),
          ),
          if (widget.type == 'image' && !_isLoading && _errorMessage == null)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: _buildZoomControls(),
              ),
            ),
        ],
      ),
    );
  }
}

class _MobileDocumentViewer extends StatefulWidget {
  final String url;
  final String fileName;
  final bool allowDownload;
  final VoidCallback? onDownloadPressed;

  const _MobileDocumentViewer({
    required this.url,
    required this.fileName,
    this.allowDownload = true,
    this.onDownloadPressed,
  });

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
    final String path = widget.url;
    final bool isLocal = !path.startsWith('http://') && !path.startsWith('https://');

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
      );

    if (isLocal) {
      final cleanPath = path.replaceAll('file://', '');
      final file = File(cleanPath);
      if (file.existsSync()) {
        debugPrint('MobileDocumentViewer: Loading local file -> $cleanPath');
        _controller.loadFile(cleanPath);
      } else {
        if (mounted) setState(() => _hasError = true);
      }
    } else {
      final googleDocsUrl =
          'https://docs.google.com/viewer?url=${Uri.encodeComponent(path)}&embedded=true';
      debugPrint('MobileDocumentViewer: Loading remote doc -> $googleDocsUrl');
      _controller.loadRequest(Uri.parse(googleDocsUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            Text(
              'Document: ${widget.fileName}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap below to open or save the PDF file',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open with External PDF Reader'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                downloadFile(widget.url, widget.fileName);
              },
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

class _InAppPdfViewer extends StatefulWidget {
  final String filePath;
  final String fileName;

  const _InAppPdfViewer({
    required this.filePath,
    required this.fileName,
  });

  @override
  State<_InAppPdfViewer> createState() => _InAppPdfViewerState();
}

class _InAppPdfViewerState extends State<_InAppPdfViewer> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              Text(
                'Error rendering PDF: $_errorMessage',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        PDFView(
          filePath: widget.filePath.replaceAll('file://', ''),
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          pageSnap: true,
          defaultPage: _currentPage,
          fitPolicy: FitPolicy.BOTH,
          preventLinkNavigation: false,
          onRender: (pages) {
            if (mounted) {
              setState(() {
                _totalPages = pages ?? 0;
                _isReady = true;
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _errorMessage = error.toString();
              });
            }
          },
          onPageError: (page, error) {
            if (mounted) {
              setState(() {
                _errorMessage = 'Page $page error: $error';
              });
            }
          },
          onPageChanged: (int? page, int? total) {
            if (mounted) {
              setState(() {
                _currentPage = page ?? 0;
              });
            }
          },
        ),
        if (!_isReady)
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        if (_isReady && _totalPages > 0)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

