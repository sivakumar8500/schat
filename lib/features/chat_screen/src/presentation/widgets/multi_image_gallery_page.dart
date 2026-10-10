import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:schat/core/security/secure_attachment_service.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_endpoints.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/download_helper/download_helper.dart';

class MultiImageGalleryPage extends StatefulWidget {
  final List<MessageModel> images;
  final int initialIndex;
  final String contactName;
  final bool isMe;
  final Function(MessageModel msg)? onSharePressed;

  const MultiImageGalleryPage({
    super.key,
    required this.images,
    this.initialIndex = 0,
    required this.contactName,
    this.isMe = false,
    this.onSharePressed,
  });

  @override
  State<MultiImageGalleryPage> createState() => _MultiImageGalleryPageState();
}

class _MultiImageGalleryPageState extends State<MultiImageGalleryPage> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _resolveImageUrl(MessageModel msg) {
    final displayUrl = msg.mediaUrl ?? '';
    return SecureAttachmentService.resolveFullUrl(displayUrl);
  }

  Future<void> _downloadCurrentImage() async {
    if (_isDownloading) return;
    final currentMsg = widget.images[_currentIndex];
    final url = _resolveImageUrl(currentMsg);
    final fileName = currentMsg.attachmentName ?? 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';

    setState(() {
      _isDownloading = true;
    });

    try {
      await downloadFile(
        url,
        fileName,
      );
    } catch (e) {
      debugPrint('Error downloading gallery image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMsg = widget.images[_currentIndex];
    final totalCount = widget.images.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_currentIndex + 1} of $totalCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.contactName,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          if (currentMsg.allowDownload || widget.isMe)
            IconButton(
              icon: _isDownloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download_rounded, color: Colors.white),
              onPressed: _downloadCurrentImage,
              tooltip: 'Download',
            ),
          if (currentMsg.allowShare || widget.isMe)
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              onPressed: () {
                if (widget.onSharePressed != null) {
                  widget.onSharePressed!(currentMsg);
                }
              },
              tooltip: 'Share',
            ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: totalCount,
            onPageChanged: (idx) {
              setState(() {
                _currentIndex = idx;
              });
            },
            itemBuilder: (context, index) {
              final msg = widget.images[index];
              return _buildImageView(msg);
            },
          ),

          // Bottom thumbnail preview bar (if multiple images)
          if (totalCount > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(totalCount, (index) {
                      final isSelected = index == _currentIndex;
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isSelected ? 24 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isSelected ? context.colors.primary : Colors.white38,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageView(MessageModel msg) {
    if (msg.attachmentBytes != null) {
      return Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.memory(
            msg.attachmentBytes!,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      );
    }

    final displayUrl = _resolveImageUrl(msg);
    final isLocal = !kIsWeb && File(displayUrl).existsSync();

    Widget imageWidget;
    if (isLocal) {
      imageWidget = Image.file(
        File(displayUrl),
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(CommonIcons.brokenImage, color: Colors.white54, size: 48),
        ),
      );
    } else {
      imageWidget = Image.network(
        displayUrl,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              color: context.colors.primary,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(CommonIcons.brokenImage, color: Colors.white54, size: 48),
        ),
      );
    }

    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: imageWidget,
      ),
    );
  }
}
