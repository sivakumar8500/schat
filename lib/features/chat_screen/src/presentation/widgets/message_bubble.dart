import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:schat/utils/common_endpoints.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_notifications.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isMe;
  final bool isRead;
  final String type;
  final String? attachmentPath;
  final String? attachmentName;
  final Uint8List? attachmentBytes;
  final bool isReply;
  final String? replyMessageBody;
  final String? replyMessageSenderName;
  final bool isEdited;
  final bool isSelected;
  final bool isUploading;

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
    this.isReply = false,
    this.replyMessageBody,
    this.replyMessageSenderName,
    this.isEdited = false,
    this.isSelected = false,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isSelected
          ? context.colors.primary.withValues(alpha: 0.15)
          : context.colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 12,
                backgroundColor: context.colors.textHint,
                child: Icon(
                  CommonIcons.person,
                  size: 16,
                  color: context.colors.textLight,
                ),
              ),
              CommonSpaces.w8,
            ],
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isMe
                        ? context.colors.primary
                        : context.colors.lightBackground,
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
                      if (isReply && replyMessageBody != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isMe
                                ? context.colors.pureWhite.withValues(alpha: 0.15)
                                : context.colors.lightBackground.withValues(alpha: 0.8),
                            border: Border(
                              left: BorderSide(
                                color: isMe
                                    ? context.colors.pureWhite.withValues(alpha: 0.8)
                                    : context.colors.primary,
                                width: 4,
                              ),
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                replyMessageSenderName ?? (isMe ? 'You' : 'Recipient'),
                                style: context.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isMe
                                      ? context.colors.textLight
                                      : context.colors.primary,
                                ),
                              ),
                              CommonSpaces.h4,
                              Text(
                                replyMessageBody!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.bodySmall.copyWith(
                                  fontSize: 12,
                                  color: isMe
                                      ? context.colors.textLight.withValues(alpha: 0.8)
                                      : context.colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      _buildAttachment(context),
                      if (message.isNotEmpty)
                        Text(
                          message,
                          style: context.bodyLarge.copyWith(
                            fontSize: 16,
                            color: isMe ? context.colors.textLight : context.colors.textPrimary,
                          ),
                        ),
                      if (message.isNotEmpty && type != 'text') CommonSpaces.h6,
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isEdited) ...[
                            Text(
                              '(edited) ',
                              style: context.bodySmall.copyWith(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color: isMe
                                    ? context.colors.textLight.withValues(alpha: 0.7)
                                    : context.colors.textSecondary,
                              ),
                            ),
                          ],
                          Text(
                            time,
                            style: context.bodySmall.copyWith(
                              fontSize: 11,
                              color: isMe
                                  ? context.colors.textLight.withValues(alpha: 0.7)
                                  : context.colors.textSecondary,
                            ),
                          ),
                          if (isMe) ...[
                            CommonSpaces.w4,
                            Icon(
                              isRead ? CommonIcons.doneAll : CommonIcons.done,
                              size: 14,
                              color: isRead
                                  ? context.colors.blueAccent
                                  : context.colors.textLight.withValues(alpha: 0.7),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachment(BuildContext context) {
    if (attachmentPath == null && attachmentBytes == null) {
      return const SizedBox.shrink();
    }

    if (type == 'image') {
      Widget imageWidget;
      if (attachmentBytes != null) {
        imageWidget = Image.memory(
          attachmentBytes!,
          height: 200,
          width: 220,
          fit: BoxFit.cover,
        );
      } else if (attachmentPath != null) {
        String displayUrl = attachmentPath!;
        if (displayUrl.contains('minio')) {
          try {
            final serverUri = Uri.parse(CommonEndpoints.baseUrl);
            final host = serverUri.host;
            if (host.isNotEmpty) {
              displayUrl = displayUrl.replaceAll('minio', host);
            }
          } catch (_) {}
        }

        final isLocalFile = !kIsWeb && File(displayUrl).existsSync();
        if (displayUrl.startsWith('http') ||
            displayUrl.startsWith('https')) {
          imageWidget = Image.network(
            displayUrl,
            height: 200,
            width: 220,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                _fileChip(context, CommonIcons.brokenImage, 'Image error'),
          );
        } else if (isLocalFile) {
          imageWidget = Image.file(
            File(displayUrl),
            height: 200,
            width: 220,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fileChip(
              context,
              CommonIcons.imageNotSupported,
              'Image error',
            ),
          );
        } else {
          String s3BaseUrl;
          try {
            final serverUri = Uri.parse(CommonEndpoints.baseUrl);
            final host = serverUri.host;
            if (host == '13.201.205.176' || host == 'localhost' || host == '127.0.0.1') {
              s3BaseUrl = 'http://$host:9000/qlyncs-docs/';
            } else {
              s3BaseUrl = 'https://qlyncs-docs.s3.ap-south-1.amazonaws.com/';
            }
          } catch (_) {
            s3BaseUrl = 'https://qlyncs-docs.s3.ap-south-1.amazonaws.com/';
          }
          final s3Url = '$s3BaseUrl$displayUrl';
          imageWidget = Image.network(
            s3Url,
            height: 200,
            width: 220,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                _fileChip(context, CommonIcons.brokenImage, 'Image error'),
          );
        }
      } else {
        return const SizedBox.shrink();
      }

      Widget imageContent = imageWidget;
      if (isUploading) {
        imageContent = Stack(
          alignment: Alignment.center,
          children: [
            imageWidget,
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ],
        );
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageContent,
        ),
      );
    } else if (type == 'audio') {
      return _fileChip(context, CommonIcons.audio, attachmentName ?? 'Audio');
    } else if (type == 'video') {
      return _fileChip(
        context,
        CommonIcons.playCircle,
        attachmentName ?? 'Video',
      );
    } else if (type == 'file') {
      return _fileChip(context, CommonIcons.document, attachmentName ?? 'File');
    } else if (type == 'location') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 120,
            width: 200,
            color: isMe
                ? context.colors.pureWhite.withValues(alpha: 0.15)
                : context.colors.lightBackground,
            child: Stack(
              alignment: Alignment.center,
              children: [
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                  ),
                  itemCount: 25,
                  itemBuilder: (_, _) => Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.colors.textHint.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CommonIcons.location,
                      color: context.colors.error,
                      size: 36,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? context.colors.pureWhite.withValues(alpha: 0.8)
                            : context.colors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'My Location',
                        style: context.bodySmall.copyWith(
                          fontSize: 11,
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
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
          color: isMe
              ? context.colors.pureWhite.withValues(alpha: 0.15)
              : context.colors.lightBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe
                ? context.colors.pureWhite.withValues(alpha: 0.3)
                : context.colors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isMe
                  ? context.colors.pureWhite.withValues(alpha: 0.3)
                  : context.colors.primary.withValues(alpha: 0.15),
              child: Icon(
                CommonIcons.person,
                color: isMe ? context.colors.pureWhite : context.colors.primary,
                size: 20,
              ),
            ),
            CommonSpaces.w8,
            Flexible(
              child: Text(
                attachmentName ?? 'Contact',
                style: context.bodyMedium.copyWith(
                  color: isMe
                      ? context.colors.pureWhite
                      : context.colors.textPrimary,
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
    return InkWell(
      onTap: () async {
        if (isUploading) return;
        if (attachmentPath != null && attachmentPath!.isNotEmpty) {
          String url = attachmentPath!;
          if (url.contains('minio')) {
            try {
              final serverUri = Uri.parse(CommonEndpoints.baseUrl);
              final host = serverUri.host;
              if (host.isNotEmpty) {
                url = url.replaceAll('minio', host);
              }
            } catch (_) {}
          }
          final isLocal = !kIsWeb && File(url).existsSync();
          if (isLocal) {
            context.showInfoNotification('Local file: $label');
            return;
          }

          if (!url.startsWith('http') && !url.startsWith('https')) {
            String s3BaseUrl;
            try {
              final serverUri = Uri.parse(CommonEndpoints.baseUrl);
              final host = serverUri.host;
              if (host == '13.201.205.176' || host == 'localhost' || host == '127.0.0.1') {
                s3BaseUrl = 'http://$host:9000/qlyncs-docs/';
              } else {
                s3BaseUrl = 'https://qlyncs-docs.s3.ap-south-1.amazonaws.com/';
              }
            } catch (_) {
              s3BaseUrl = 'https://qlyncs-docs.s3.ap-south-1.amazonaws.com/';
            }
            url = '$s3BaseUrl$url';
          }
          final uri = Uri.parse(url);
          try {
            final canLaunch = await canLaunchUrl(uri);
            if (!context.mounted) return;
            if (canLaunch) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              context.showErrorNotification('Could not open file URL');
            }
          } catch (e) {
            if (!context.mounted) return;
            context.showErrorNotification('Error opening file: $e');
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe
              ? context.colors.pureWhite.withValues(alpha: 0.2)
              : context.colors.scaffoldBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe
                ? context.colors.pureWhite.withValues(alpha: 0.3)
                : context.colors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isUploading) ...[
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isMe ? context.colors.pureWhite : context.colors.primary,
                  ),
                ),
              ),
            ] else ...[
              Icon(
                icon,
                color: isMe ? context.colors.pureWhite : context.colors.primary,
              ),
            ],
            CommonSpaces.w8,
            Flexible(
              child: Text(
                label,
                style: context.bodyMedium.copyWith(
                  color: isMe
                      ? context.colors.pureWhite
                      : context.colors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
