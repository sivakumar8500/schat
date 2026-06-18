import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_colors.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isMe;
  final bool isRead;
  final String type;
  final String? attachmentPath;
  final String? attachmentName;
  final Uint8List? attachmentBytes;

  const MessageBubble({
    super.key,
    required this.message,
    required this.time,
    required this.isMe,
    this.isRead = false,
    this.type = 'text',
    this.attachmentPath,
    this.attachmentName,
    this.attachmentBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: context.colors.textHint,
              child: Icon(Icons.person, size: 16, color: context.colors.textLight),
            ),
            CommonSpaces.w8,
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isMe ? context.colors.primary : context.colors.lightBackground,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
                  bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.colors.textPrimary.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  _buildAttachment(context),
                  if (message.isNotEmpty)
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 16,
                        color: isMe ? context.colors.textLight : context.colors.textPrimary,
                      ),
                    ),
                  if (message.isNotEmpty && type != 'text') CommonSpaces.h6,
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe ? context.colors.textLight.withValues(alpha: 0.7) : context.colors.textSecondary,
                        ),
                      ),
                      if (isMe) ...[
                        CommonSpaces.w4,
                        Icon(
                          isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: isRead ? Colors.lightBlueAccent.shade100 : context.colors.textLight.withValues(alpha: 0.7),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachment(BuildContext context) {
    if (attachmentPath == null && attachmentBytes == null) {
      return const SizedBox.shrink();
    }

    if (type == 'image') {
      Widget imageWidget;
      if (kIsWeb && attachmentBytes != null) {
        imageWidget = Image.memory(
          attachmentBytes!,
          height: 200,
          width: 220,
          fit: BoxFit.cover,
        );
      } else if (!kIsWeb && attachmentPath != null) {
        if (attachmentPath!.startsWith('http') || attachmentPath!.startsWith('https')) {
          imageWidget = Image.network(
            attachmentPath!,
            height: 200,
            width: 220,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fileChip(context, Icons.broken_image, 'Image error'),
          );
        } else {
          imageWidget = Image.file(
            File(attachmentPath!),
            height: 200,
            width: 220,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fileChip(context, Icons.image_not_supported, 'Image error'),
          );
        }
      } else {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageWidget,
        ),
      );
    } else if (type == 'audio') {
      return _fileChip(context, Icons.headset, attachmentName ?? 'Audio');
    } else if (type == 'video') {
      return _fileChip(context, Icons.play_circle_fill, attachmentName ?? 'Video');
    } else if (type == 'file') {
      return _fileChip(context, Icons.insert_drive_file, attachmentName ?? 'File');
    } else if (type == 'location') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 120,
            width: 200,
            color: isMe ? Colors.white.withValues(alpha: 0.15) : context.colors.lightBackground,
            child: Stack(
              alignment: Alignment.center,
              children: [
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
                  itemCount: 25,
                  itemBuilder: (_, _) => Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: context.colors.textHint.withValues(alpha: 0.2)),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_pin, color: context.colors.error, size: 36),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.white.withValues(alpha: 0.8) : context.colors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'My Location',
                        style: TextStyle(fontSize: 11, color: context.colors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else if (type == 'contact') {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withValues(alpha: 0.15) : context.colors.lightBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe ? Colors.white.withValues(alpha: 0.3) : context.colors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isMe ? Colors.white.withValues(alpha: 0.3) : context.colors.primary.withValues(alpha: 0.15),
              child: Icon(Icons.person, color: isMe ? Colors.white : context.colors.primary, size: 20),
            ),
            CommonSpaces.w8,
            Flexible(
              child: Text(
                attachmentName ?? 'Contact',
                style: TextStyle(
                  color: isMe ? Colors.white : context.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _fileChip(BuildContext context, IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withValues(alpha: 0.2) : context.colors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe ? Colors.white.withValues(alpha: 0.3) : context.colors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isMe ? Colors.white : context.colors.primary),
          CommonSpaces.w8,
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: isMe ? Colors.white : context.colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
