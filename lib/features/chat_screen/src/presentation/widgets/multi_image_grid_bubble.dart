import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:schat/core/security/secure_attachment_service.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/multi_image_gallery_page.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_endpoints.dart';
import 'package:schat/utils/common_icons.dart';

class MultiImageGridBubble extends StatelessWidget {
  final List<MessageModel> images;
  final bool isMe;
  final String contactName;
  final Function(MessageModel msg)? onSharePressed;

  const MultiImageGridBubble({
    super.key,
    required this.images,
    required this.isMe,
    required this.contactName,
    this.onSharePressed,
  });

  void _openGallery(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiImageGalleryPage(
          images: images,
          initialIndex: initialIndex,
          contactName: contactName,
          isMe: isMe,
          onSharePressed: onSharePressed,
        ),
      ),
    );
  }

  String _resolveImageUrl(MessageModel msg) {
    final displayUrl = msg.mediaUrl ?? '';
    return SecureAttachmentService.resolveFullUrl(displayUrl);
  }

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    final count = images.length;
    const double gridSize = 250.0;
    const double spacing = 3.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: gridSize,
        height: gridSize,
        child: _buildGridLayout(context, count, spacing),
      ),
    );
  }

  Widget _buildGridLayout(BuildContext context, int count, double spacing) {
    if (count == 2) {
      return Row(
        children: [
          Expanded(child: _buildTile(context, 0)),
          SizedBox(width: spacing),
          Expanded(child: _buildTile(context, 1)),
        ],
      );
    } else if (count == 3) {
      return Row(
        children: [
          Expanded(flex: 1, child: _buildTile(context, 0)),
          SizedBox(width: spacing),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(child: _buildTile(context, 1)),
                SizedBox(height: spacing),
                Expanded(child: _buildTile(context, 2)),
              ],
            ),
          ),
        ],
      );
    } else if (count == 4) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildTile(context, 0)),
                SizedBox(width: spacing),
                Expanded(child: _buildTile(context, 1)),
              ],
            ),
          ),
          SizedBox(height: spacing),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildTile(context, 2)),
                SizedBox(width: spacing),
                Expanded(child: _buildTile(context, 3)),
              ],
            ),
          ),
        ],
      );
    } else {
      // 5 or more images: 2x2 grid with +N on 4th item
      final remaining = count - 3;
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildTile(context, 0)),
                SizedBox(width: spacing),
                Expanded(child: _buildTile(context, 1)),
              ],
            ),
          ),
          SizedBox(height: spacing),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildTile(context, 2)),
                SizedBox(width: spacing),
                Expanded(child: _buildTile(context, 3, remainingCount: remaining)),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildTile(BuildContext context, int index, {int? remainingCount}) {
    final msg = images[index];
    final displayUrl = _resolveImageUrl(msg);
    final isLocal = !kIsWeb && File(displayUrl).existsSync();

    Widget imageWidget;
    if (msg.attachmentBytes != null) {
      imageWidget = Image.memory(
        msg.attachmentBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (isLocal) {
      imageWidget = Image.file(
        File(displayUrl),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _errorPlaceholder(context),
      );
    } else if (displayUrl.startsWith('http') || displayUrl.startsWith('https')) {
      imageWidget = Image.network(
        displayUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _errorPlaceholder(context),
      );
    } else {
      imageWidget = _errorPlaceholder(context);
    }

    return GestureDetector(
      onTap: () => _openGallery(context, index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,

          // Uploading spinner
          if (msg.isUploading)
            Container(
              color: Colors.black.withValues(alpha: 0.45),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
                  ),
                ),
              ),
            ),

          // Remaining count overlay (+N)
          if (remainingCount != null && remainingCount > 0)
            Container(
              color: Colors.black.withValues(alpha: 0.55),
              child: Center(
                child: Text(
                  '+$remainingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _errorPlaceholder(BuildContext context) {
    return Container(
      color: Colors.grey.withValues(alpha: 0.2),
      child: const Center(
        child: Icon(CommonIcons.brokenImage, color: Colors.grey, size: 28),
      ),
    );
  }
}
