import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_event.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_bloc.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_bloc.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_event.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/injection.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/in_app_viewer.dart';
import 'package:schat/utils/download_helper/download_helper.dart';
import 'package:schat/utils/common_endpoints.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:schat/features/chat_screen/src/domain/models/message_model.dart' show CallMeta;
import 'dart:async' show StreamSubscription;
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_event.dart';
import 'package:schat/features/chat_screen/src/presentation/chat_page.dart';

class MessageBubble extends StatelessWidget {
  final String messageId;
  final String conversationId;
  final String message;
  final String time;
  final bool isMe;
  final bool isRead;
  final bool isDelivered;
  final bool isDeleted;
  final String type;
  final double? duration;
  final String? attachmentPath;
  final String? attachmentName;
  final Uint8List? attachmentBytes;
  final bool isReply;
  final String? replyMessageId;
  final String? replyMessageBody;
  final String? replyMessageSenderName;
  final bool isEdited;
  final bool isPinned;
  final bool isSelected;
  final bool isHighlighted;
  final bool isUploading;
  final bool isFailed;
  final VoidCallback? onResendPressed;
  final bool isGroup;
  final bool allowShare;
  final bool allowDownload;
  final bool allowView;
  final VoidCallback? onSharePressed;
  final int? fileSize;
  final CallMeta? callMeta;
  final bool isRecipientOnline;
  final VoidCallback? onReplyTap;

  const MessageBubble({
    super.key,
    this.messageId = '',
    this.conversationId = '',
    required this.message,
    required this.time,
    required this.isMe,
    this.isRead = false,
    this.isDelivered = false,
    this.isDeleted = false,
    this.type = 'text',
    this.attachmentPath,
    this.attachmentName,
    this.attachmentBytes,
    this.isReply = false,
    this.replyMessageId,
    this.replyMessageBody,
    this.replyMessageSenderName,
    this.isEdited = false,
    this.isPinned = false,
    this.isSelected = false,
    this.isHighlighted = false,
    this.isUploading = false,
    this.isFailed = false,
    this.onResendPressed,
    this.isGroup = false,
    this.allowShare = true,
    this.allowDownload = true,
    this.allowView = true,
    this.onSharePressed,
    this.fileSize,
    this.callMeta,
    this.isRecipientOnline = false,
    this.onReplyTap,
    this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSystemMessage = type == 'system' ||
        type == 'group_event' ||
        type == 'notification' ||
        _isGroupEvent(message);

    if (isSystemMessage) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 24.0),
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
          decoration: BoxDecoration(
            color: context.colors.isDark
                ? const Color(0xFF263238) // Dark bluish gray (BlueGrey 900)
                : const Color(0xFFECEFF1), // Light bluish gray (BlueGrey 50)
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: context.bodyMedium.copyWith(
              color: context.colors.isDark
                  ? const Color(0xFFB0BEC5) // Light bluish gray text for dark mode
                  : const Color(0xFF546E7A), // Dark bluish gray text for light mode
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: isSelected
          ? context.colors.primary.withValues(alpha: 0.15)
          : (isHighlighted ? context.colors.primary.withValues(alpha: 0.25) : context.colors.transparent),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isFailed && isMe) ...[
              GestureDetector(
                onTap: onResendPressed,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CommonIcons.errorOutline, color: context.colors.error, size: 16),
                    CommonSpaces.w4,
                    Text(
                      'Resend',
                      style: context.bodySmall.copyWith(
                        color: context.colors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              CommonSpaces.w8,
            ],
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
                        ? context.colors.sentBubble
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
                      if (isReply && replyMessageBody != null && !isDeleted)
                        GestureDetector(
                          onTap: onReplyTap,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? context.colors.sentBubble.withValues(alpha: 0.5)
                                  : context.colors.lightBackground.withValues(alpha: 0.8),
                              border: Border(
                                left: BorderSide(
                                  color: isMe
                                      ? context.colors.primary
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
                                        ? context.colors.textPrimary
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
                                        ? context.colors.textSecondary
                                        : context.colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (!isDeleted) _buildAttachment(context),
                      if (!isDeleted) _buildPermissionControls(context),
                      _buildMessageText(
                        context,
                        context.bodyLarge.copyWith(
                          fontSize: 16,
                          color: isMe ? context.colors.textPrimary : context.colors.textPrimary,
                        ),
                      ),
                      if (message.isNotEmpty && (type == 'text' || message != attachmentName) && type != 'text' && !isDeleted) CommonSpaces.h6,
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
                                    ? context.colors.textSecondary
                                    : context.colors.textSecondary,
                              ),
                            ),
                          ],
                          if (isPinned) ...[
                            Icon(
                              CommonIcons.pin,
                              size: 10,
                              color: isMe
                                  ? context.colors.textSecondary
                                  : context.colors.textSecondary,
                            ),
                            CommonSpaces.w4,
                          ],
                          Text(
                            time,
                            style: context.bodySmall.copyWith(
                              fontSize: 11,
                              color: isMe
                                  ? context.colors.textSecondary
                                  : context.colors.textSecondary,
                            ),
                          ),
                          if (isMe) ...[
                            CommonSpaces.w4,
                            Builder(
                              builder: (context) {
                                // Pending = temp ID, uploading, OR not yet server-confirmed (covers network-drop case)
                                final isPending = messageId.startsWith('temp_') ||
                                    isUploading ||
                                    (!isDelivered && !isRead && !isFailed);
                                // ✓ single grey tick — sending / not yet server-confirmed
                                if (isPending && !isFailed) {
                                  return Icon(
                                    CommonIcons.done,
                                    size: 14,
                                    color: context.colors.textSecondary,
                                  );
                                }

                                // ✓✓ blue — read
                                if (isRead) {
                                  return Icon(
                                    CommonIcons.doneAll,
                                    size: 14,
                                    color: const Color(0xFF2196F3), // blue
                                  );
                                }

                                // ✓✓ grey — delivered
                                if (isDelivered) {
                                  return Icon(
                                    CommonIcons.doneAll,
                                    size: 14,
                                    color: context.colors.textSecondary,
                                  );
                                }

                                // ✓ grey — sent (reached server, not yet delivered)
                                return Icon(
                                  CommonIcons.done,
                                  size: 14,
                                  color: context.colors.textSecondary,
                                );
                              },
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
    if (attachmentPath == null && attachmentBytes == null && type != 'call') {
      return const SizedBox.shrink();
    }

    final viewLocked = !allowView && !isMe;

    Widget result;
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

      Widget imageContent = GestureDetector(
        onTap: viewLocked ? null : () => _openInAppViewer(context),
        child: imageWidget,
      );

      if (isUploading) {
        imageContent = Stack(
          alignment: Alignment.center,
          children: [
            imageContent,
            Positioned.fill(
              child: Container(
                color: context.colors.pureBlack.withValues(alpha: 0.4),
              ),
            ),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(context.colors.pureWhite),
                strokeWidth: 3,
              ),
            ),
          ],
        );
      }

      if (viewLocked) {
        imageContent = Stack(
          alignment: Alignment.center,
          children: [
            imageContent,
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: context.colors.pureBlack.withValues(alpha: 0.35),
                    alignment: Alignment.center,
                    child: Icon(
                      CommonIcons.lockOutline,
                      color: context.colors.pureWhite,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }

      result = Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageContent,
        ),
      );
    } else if (type == 'audio' || type == 'voice_note') {
       result = _AudioWaveformPlayer(
         audioUrl: attachmentPath,
         isMe: isMe,
         payloadDuration: duration,
       );
    } else if (type == 'video') {
      if (viewLocked) {
        result = _buildLockedPreview(context);
      } else {
        result = Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _VideoMessagePreview(
            url: attachmentPath,
            messageId: messageId,
            isMe: isMe,
            onTap: () => _openInAppViewer(context),
            isUploading: isUploading,
          ),
        );
      }
    } else if (type == 'file') {
      if (viewLocked) {
        result = _buildLockedPreview(context);
      } else {
        result = _buildFileBubbleCard(context);
      }
    } else if (type == 'location') {
      result = Padding(
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
                            : context.colors.lightBackground,
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
      final path = attachmentPath ?? '';
      String phone = '';
      String? contactUserId;
      bool isSchatUser = false;

      if (path.contains('contact:')) {
        final contactPart = path.split('contact:').last;
        final contactParts = contactPart.split(':');
        if (contactParts.isNotEmpty) {
          phone = contactParts[0];
        }
        if (contactParts.length > 1 && contactParts[1].isNotEmpty) {
          contactUserId = contactParts[1];
          isSchatUser = true;
        }
      }

      final String nameText = attachmentName ?? 'Contact';
      String displayName = nameText;
      String displayPhone = phone;

      if (nameText.contains(' · ')) {
        final nameParts = nameText.split(' · ');
        displayName = nameParts[0].trim();
        if (displayPhone.isEmpty && nameParts.length > 1) {
          displayPhone = nameParts[1].trim();
        }
      }

      // Sanitize phone for dialer: take only first number (if comma/semicolon separated),
      // strip all formatting but keep leading '+' and digits (preserves country codes).
      String _sanitizePhone(String raw) {
        final first = raw.split(RegExp(r'[,;]')).first.trim();
        return first.replaceAll(RegExp(r'[^\d+]'), '');
      }

      final cleanedPhone = _sanitizePhone(phone.isNotEmpty ? phone : displayPhone);

      result = GestureDetector(
        onTap: () {
          if (isSchatUser && contactUserId != null) {
            final chatsBloc = getIt<ChatsBloc>();
            chatsBloc.add(CreateChat(
              participantId: contactUserId,
              contactName: displayName,
            ));
            StreamSubscription? sub;
            sub = chatsBloc.stream.listen((state) {
              state.maybeWhen(
                chatCreated: (chat, contactName, profilePictureUrl) {
                  sub?.cancel();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        conversationId: chat.id,
                        contactName: contactName,
                        contactColor: context.colors.primary,
                        isOnline: false,
                        recipientId: chat.recipient.id,
                        profilePictureUrl: profilePictureUrl,
                      ),
                    ),
                  );
                },
                orElse: () {},
              );
            });
          } else {
            if (cleanedPhone.isNotEmpty) {
              final Uri telUri = Uri(scheme: 'tel', path: cleanedPhone);
              canLaunchUrl(telUri).then((can) {
                if (can) launchUrl(telUri);
              });
            }
          }
        },
        child: Container(
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
                  isSchatUser ? Icons.chat_rounded : CommonIcons.person,
                  color: isMe ? context.colors.pureWhite : context.colors.primary,
                  size: 20,
                ),
              ),
              CommonSpaces.w8,
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: context.bodyMedium.copyWith(
                        color: isMe ? context.colors.pureWhite : context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (displayPhone.isNotEmpty) ...[
                      CommonSpaces.h2,
                      Text(
                        displayPhone,
                        style: context.bodySmall.copyWith(
                          color: isSchatUser 
                              ? (isMe ? context.colors.pureWhite.withOpacity(0.7) : context.colors.textSecondary)
                              : (isMe ? context.colors.pureWhite.withOpacity(0.4) : context.colors.textHint), // blur/muted color!
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (!isSchatUser) ...[
                CommonSpaces.w12,
                IconButton(
                  icon: Icon(
                    CommonIcons.phone,
                    color: isMe ? context.colors.pureWhite : context.colors.primary,
                    size: 20,
                  ),
                  onPressed: () {
                    if (cleanedPhone.isNotEmpty) {
                      final Uri telUri = Uri(scheme: 'tel', path: cleanedPhone);
                      canLaunchUrl(telUri).then((can) {
                        if (can) launchUrl(telUri);
                      });
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ),
      );
    } else if (type == 'call') {
      final statusLower = callMeta?.status.toLowerCase() ?? '';
      final isMissed = statusLower == 'missed';
      final isDeclined = statusLower == 'rejected' || statusLower == 'reject' || statusLower == 'busy' || statusLower == 'decline' || statusLower == 'declined';
      final isErrorState = isMissed || isDeclined;
      final isVideo = callMeta?.callType.toLowerCase() == 'video';
      final duration = callMeta?.duration ?? 0;
      
      result = Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe
              ? context.colors.pureWhite.withValues(alpha: 0.15)
              : context.colors.lightBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isErrorState 
                    ? context.colors.error.withValues(alpha: 0.1) 
                    : (isMe ? context.colors.pureWhite.withValues(alpha: 0.2) : context.colors.primary.withValues(alpha: 0.1)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVideo 
                    ? (isErrorState ? CommonIcons.missedVideoCall : CommonIcons.videocam) 
                    : (isErrorState ? CommonIcons.phoneMissed : CommonIcons.phone),
                color: isErrorState 
                    ? context.colors.error 
                    : (isMe ? context.colors.pureWhite : context.colors.primary),
                size: 20,
              ),
            ),
            CommonSpaces.w12,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isVideo ? 'Video Call' : 'Voice Call',
                  style: context.bodyMedium.copyWith(
                    color: isMe ? context.colors.pureWhite : context.colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isMissed 
                      ? 'Missed' 
                      : (isDeclined ? 'Declined' : (duration > 0 ? _formatCallDuration(duration) : 'Completed')),
                  style: context.bodySmall.copyWith(
                    color: isErrorState 
                        ? context.colors.error 
                        : (isMe ? context.colors.pureWhite.withValues(alpha: 0.7) : context.colors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }

    return result;
  }

  Widget _buildPermissionControls(BuildContext context) {
    if (attachmentPath == null && attachmentBytes == null) {
      return const SizedBox.shrink();
    }

    if (isGroup) {
      return const SizedBox.shrink();
    }

    if (isMe) {
      final activeBg = context.colors.pureWhite.withValues(alpha: 0.2);
      final activeIcon = context.colors.pureWhite;
      final activeBorder = context.colors.pureWhite.withValues(alpha: 0.4);

      final inactiveBg = context.colors.pureWhite.withValues(alpha: 0.05);
      final inactiveIcon = context.colors.pureWhite.withValues(alpha: 0.4);
      final inactiveBorder = context.colors.pureWhite.withValues(alpha: 0.15);

      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCapsuleChip(
                context: context,
                icon: allowView ? CommonIcons.visibility : CommonIcons.visibilityOff,
                label: allowView ? 'View Allowed' : 'View Locked',
                backgroundColor: allowView ? activeBg : inactiveBg,
                textColor: allowView ? activeIcon : inactiveIcon,
                borderColor: allowView ? activeBorder : inactiveBorder,
                onTap: () => _updatePermissions(context, view: !allowView),
              ),
              _buildCapsuleChip(
                context: context,
                icon: allowDownload ? CommonIcons.download : CommonIcons.downloadOff,
                label: allowDownload ? 'Download Allowed' : 'Download Locked',
                backgroundColor: allowDownload ? activeBg : inactiveBg,
                textColor: allowDownload ? activeIcon : inactiveIcon,
                borderColor: allowDownload ? activeBorder : inactiveBorder,
                onTap: () => _updatePermissions(context, download: !allowDownload),
              ),
              _buildCapsuleChip(
                context: context,
                icon: allowShare ? CommonIcons.share : CommonIcons.shareOff,
                label: allowShare ? 'Share Allowed' : 'Share Locked',
                backgroundColor: allowShare ? activeBg : inactiveBg,
                textColor: allowShare ? activeIcon : inactiveIcon,
                borderColor: allowShare ? activeBorder : inactiveBorder,
                onTap: () => _updatePermissions(context, share: !allowShare),
              ),
            ],
          ),
        ),
      );
    } else {
      final activeBg = context.colors.primary.withValues(alpha: 0.1);
      final activeIcon = context.colors.primary;
      final activeBorder = context.colors.primary.withValues(alpha: 0.3);

      final inactiveBg = context.colors.textHint.withValues(alpha: 0.05);
      final inactiveIcon = context.colors.textHint.withValues(alpha: 0.4);
      final inactiveBorder = context.colors.textHint.withValues(alpha: 0.1);

      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCapsuleChip(
                context: context,
                icon: allowView ? CommonIcons.visibility : CommonIcons.visibilityOff,
                label: 'View',
                backgroundColor: allowView ? activeBg : inactiveBg,
                textColor: allowView ? activeIcon : inactiveIcon,
                borderColor: allowView ? activeBorder : inactiveBorder,
                onTap: allowView ? () => _openInAppViewer(context) : null,
              ),
              _buildCapsuleChip(
                context: context,
                icon: allowDownload ? CommonIcons.download : CommonIcons.downloadOff,
                label: 'Download',
                backgroundColor: allowDownload ? activeBg : inactiveBg,
                textColor: allowDownload ? activeIcon : inactiveIcon,
                borderColor: allowDownload ? activeBorder : inactiveBorder,
                onTap: allowDownload ? () => _triggerDownload(context) : null,
              ),
              _buildCapsuleChip(
                context: context,
                icon: allowShare ? CommonIcons.share : CommonIcons.shareOff,
                label: 'Share',
                backgroundColor: allowShare ? activeBg : inactiveBg,
                textColor: allowShare ? activeIcon : inactiveIcon,
                borderColor: allowShare ? activeBorder : inactiveBorder,
                onTap: allowShare ? () => _triggerShare(context) : null,
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildCapsuleChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback? onTap,
    Color? borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8.0, top: 4.0, bottom: 4.0),
      child: Material(
        color: context.colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor ?? context.colors.transparent,
                width: 1,
              ),
            ),
            child: Icon(icon, size: 16, color: textColor),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedPreview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 64,
          width: 220,
          color: context.colors.textPrimary.withValues(alpha: 0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CommonIcons.lockOutline, color: context.colors.textSecondary, size: 20),
              CommonSpaces.w8,
              Flexible(
                child: Text(
                  'View Locked',
                  style: context.bodyMedium.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updatePermissions(BuildContext context, {bool? share, bool? download, bool? view}) {
    final newShare = share ?? allowShare;
    final newDownload = download ?? allowDownload;
    final newView = view ?? allowView;
    
    context.read<ChatBloc>().add(UpdateAttachmentPermissionsEvent(
      messageId: messageId,
      conversationId: conversationId,
      allowShare: newShare,
      allowDownload: newDownload,
      allowView: newView,
    ));
    
    context.read<ChatSocketBloc>().add(SendMessage(
      conversationId: conversationId,
      type: 'update_attachment_permissions',
      text: messageId,
      security: {
        'messageId': messageId,
        'allowShare': newShare,
        'allowDownload': newDownload,
        'allowView': newView,
      },
      viewControl: {
        'messageId': messageId,
        'allowShare': newShare,
        'allowDownload': newDownload,
        'allowView': newView,
      },
    ));
  }

  void _openInAppViewer(BuildContext context) {
    final String? path = attachmentPath;
    if (path == null || path.isEmpty) return;
    String url = path;

    if (url.contains('minio')) {
      try {
        final serverUri = Uri.parse(CommonEndpoints.baseUrl);
        final host = serverUri.host;
        if (host.isNotEmpty) {
          url = url.replaceAll('minio', host);
        }
      } catch (_) {}
    }

    final bool isLocalFile = !kIsWeb && File(url).existsSync();

    if (!url.startsWith('http') && !url.startsWith('https') && !isLocalFile) {
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

    InAppViewer.show(
      context,
      url: url,
      fileName: attachmentName ?? 'File',
      type: type,
      allowShare: allowShare,
      allowDownload: allowDownload,
      onSharePressed: onSharePressed,
    );

    // Notify backend about file view
    if (!isLocalFile) {
      getIt<ChatSocketRepository>().sendFileAction(
        type: 'view_file',
        conversationId: conversationId,
        messageId: messageId,
        fileKey: path,
      );
    }
  }

  void _triggerDownload(BuildContext context) {
    final String? path = attachmentPath;
    if (path == null || path.isEmpty) return;
    String url = path;

    final bool isLocalFile = !kIsWeb && File(url).existsSync();

    if (!url.startsWith('http') && !url.startsWith('https') && !isLocalFile) {
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

    if (isLocalFile) {
      // If it's already local, we just try to open it
      downloadFile(url, attachmentName ?? 'File');
    } else {
      downloadFile(url, attachmentName ?? 'File');
      context.showSuccessNotification('Downloading ${attachmentName ?? "File"}...');
    }

    // Notify backend about file download
    if (!isLocalFile) {
      getIt<ChatSocketRepository>().sendFileAction(
        type: 'download_file',
        conversationId: conversationId,
        messageId: messageId,
        fileKey: path,
      );
    }
  }

  void _triggerShare(BuildContext context) {
    if (onSharePressed != null) {
      onSharePressed!();
      
      // Notify backend about file share
      if (attachmentPath != null) {
        getIt<ChatSocketRepository>().sendFileAction(
          type: 'share_file',
          conversationId: conversationId,
          messageId: messageId,
          fileKey: attachmentPath!,
        );
      }
    }
  }

  Widget _buildFileBubbleCard(BuildContext context) {
    final String fileName = attachmentName ?? (type == 'video' ? 'Video' : 'File');
    final String extension = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    
    Color typeColor;
    String badgeText;
    IconData fileIcon;

    if (type == 'video') {
      typeColor = const Color(0xFF1565C0); // Blue for video
      badgeText = extension.isNotEmpty ? extension.toUpperCase() : 'VIDEO';
      fileIcon = CommonIcons.playCircle;
    } else {
      switch (extension) {
        case 'pdf':
          typeColor = const Color(0xFFE53935); // Red for PDF
          badgeText = 'PDF';
          fileIcon = CommonIcons.pictureAsPdf;
          break;
        case 'doc':
        case 'docx':
          typeColor = const Color(0xFF1E88E5); // Blue for Word
          badgeText = 'DOC';
          fileIcon = CommonIcons.description;
          break;
        case 'xls':
        case 'xlsx':
          typeColor = const Color(0xFF43A047); // Green for Excel
          badgeText = 'XLS';
          fileIcon = CommonIcons.tableChart;
          break;
        case 'csv':
          typeColor = const Color(0xFF00897B); // Teal for CSV
          badgeText = 'CSV';
          fileIcon = CommonIcons.gridOn;
          break;
        case 'json':
          typeColor = const Color(0xFF8E24AA); // Purple for JSON
          badgeText = 'JSON';
          fileIcon = CommonIcons.codeIcon;
          break;
        default:
          typeColor = const Color(0xFF757575); // Grey for other files
          badgeText = extension.isNotEmpty ? extension.toUpperCase() : 'FILE';
          fileIcon = CommonIcons.document;
          break;
      }
    }

    String sizeLabel = '1.2 MB'; // Fallback
    if (fileSize != null && fileSize! > 0) {
      sizeLabel = _formatBytes(fileSize!);
    } else {
      // Create a deterministic simulated size based on name hash for UI completeness
      final int nameHash = fileName.hashCode.abs();
      final double mockSizeMb = 0.5 + (nameHash % 95) / 10.0;
      if (mockSizeMb < 1.0) {
        sizeLabel = '${(mockSizeMb * 1024).toStringAsFixed(0)} KB';
      } else {
        sizeLabel = '${mockSizeMb.toStringAsFixed(1)} MB';
      }
    }

    return InkWell(
      onTap: () async {
        if (isUploading) return;
        if (!allowView) {
          context.showInfoNotification('View permission is locked by sender');
          return;
        }
        _openInAppViewer(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: isMe
              ? context.colors.pureWhite.withValues(alpha: 0.12)
              : context.colors.lightBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe
                ? context.colors.pureWhite.withValues(alpha: 0.25)
                : context.colors.border,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            // Left-hand colored document format box
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: isUploading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(context.colors.pureWhite),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          fileIcon,
                          color: context.colors.pureWhite,
                          size: 20,
                        ),
                        CommonSpaces.h2,
                        Text(
                          badgeText,
                          style: context.bodySmall.copyWith(
                            color: context.colors.pureWhite,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
            ),
            CommonSpaces.w12,
            // Text displaying name and size details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isMe ? context.colors.pureWhite : context.colors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  CommonSpaces.h4,
                  Text(
                    sizeLabel,
                    style: context.bodySmall.copyWith(
                      color: isMe 
                          ? context.colors.pureWhite.withValues(alpha: 0.7)
                          : context.colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = 0;
    double w = bytes.toDouble();
    while (w >= 1024 && i < suffixes.length - 1) {
      w /= 1024;
      i++;
    }
    return "${w.toStringAsFixed(1)} ${suffixes[i]}";
  }

  String _formatCallDuration(int seconds) {
    if (seconds < 60) return '$seconds sec';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) return '$minutes min';
    return '$minutes min $remainingSeconds sec';
  }

  Widget _fileChip(BuildContext context, IconData icon, String label) {
    return InkWell(
      onTap: () async {
        if (isUploading) return;
        if (!allowView) {
          context.showInfoNotification('View permission is locked by sender');
          return;
        }
        _openInAppViewer(context);
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

  Widget _buildMessageText(BuildContext context, TextStyle baseStyle) {
    if (isDeleted) {
      final deletedStyle = baseStyle.copyWith(
        fontStyle: FontStyle.italic,
        color: isMe
            ? context.colors.textLight.withValues(alpha: 0.7)
            : context.colors.textSecondary,
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CommonIcons.block,
              size: 16,
              color: deletedStyle.color,
            ),
            CommonSpaces.w6,
            Text(
              isMe ? 'You deleted this message' : 'This message was deleted',
              style: deletedStyle,
            ),
          ],
        ),
      );
    }

    if (message.isEmpty || (type != 'text' && message == attachmentName)) {
      return const SizedBox.shrink();
    }

    final RegExp urlRegex = RegExp(
      r'(https?://\S+|www\.\S+)',
      caseSensitive: false,
    );

    final matches = urlRegex.allMatches(message);
    if (matches.isEmpty) {
      return Text(
        message,
        style: baseStyle,
      );
    }

    final List<InlineSpan> spans = [];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: message.substring(lastEnd, match.start),
        ));
      }

      final url = message.substring(match.start, match.end);
      final linkColor = isMe ? context.colors.blueAccent : context.colors.primary;

      spans.add(TextSpan(
        text: url,
        style: context.bodyMedium.copyWith(
          color: linkColor,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            var openUrl = url;
            if (openUrl.toLowerCase().startsWith('www.')) {
              openUrl = 'https://$openUrl';
            }
            final uri = Uri.tryParse(openUrl);
            if (uri != null) {
              try {
                final can = await canLaunchUrl(uri);
                if (can) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    context.showErrorNotification('Could not open link');
                  }
                }
              } catch (e) {
                debugPrint('Error launching url: $e');
                if (context.mounted) {
                  context.showErrorNotification('Error opening link');
                }
              }
            }
          },
      ));

      lastEnd = match.end;
    }

    if (lastEnd < message.length) {
      spans.add(TextSpan(
        text: message.substring(lastEnd),
      ));
    }

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: spans,
      ),
    );
  }

  bool _isGroupEvent(String msg) {
    final lowerMsg = msg.toLowerCase().trim();
    if (lowerMsg.isEmpty) return false;

    final patterns = [
      'added',
      'removed',
      'left the group',
      'left group',
      'joined the group',
      'joined group',
      'joined using',
      'created the group',
      'created this group',
      'group created',
      'changed the group name',
      'changed group name',
      'group name changed',
      'changed the group icon',
      'changed group icon',
      'group icon changed',
      'group icon was updated',
      'promoted to admin',
      'demoted from admin',
      'changed group description',
      'group description updated',
      'changed the theme',
      'changed chat theme',
    ];

    return patterns.any((pattern) => lowerMsg.contains(pattern));
  }
}

class _VideoMessagePreview extends StatefulWidget {
  final String? url;
  final String messageId;
  final bool isMe;
  final VoidCallback onTap;
  final bool isUploading;

  const _VideoMessagePreview({
    required this.url,
    required this.messageId,
    required this.isMe,
    required this.onTap,
    this.isUploading = false,
  });

  @override
  State<_VideoMessagePreview> createState() => _VideoMessagePreviewState();
}

class _VideoMessagePreviewState extends State<_VideoMessagePreview> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.url != null && !widget.isUploading) {
      _initializePlayer();
    }
  }

  @override
  void didUpdateWidget(_VideoMessagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url || (oldWidget.isUploading && !widget.isUploading)) {
      if (widget.url != null && !widget.isUploading) {
        _initializePlayer();
      }
    }
  }

  String _resolveUrl(String path) {
    String url = path;
    if (url.contains('minio')) {
      try {
        final serverUri = Uri.parse(CommonEndpoints.baseUrl);
        final host = serverUri.host;
        if (host.isNotEmpty) {
          url = url.replaceAll('minio', host);
        }
      } catch (_) {}
    }

    final bool isLocalFile = !kIsWeb && File(url).existsSync();

    if (!url.startsWith('http') && !url.startsWith('https') && !isLocalFile) {
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
    return url;
  }

  Future<void> _initializePlayer() async {
    if (_controller != null) await _controller!.dispose();

    try {
      final url = _resolveUrl(widget.url!);
      final bool isLocal = !kIsWeb && File(url).existsSync();

      _controller = isLocal
          ? VideoPlayerController.file(File(url))
          : VideoPlayerController.networkUrl(Uri.parse(url));

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video preview: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 180,
          width: 220,
          color: context.colors.pureBlack.withValues(alpha: 0.12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isInitialized && _controller != null)
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                ),
              if (!_isInitialized)
                Icon(CommonIcons.playCircleOutline, color: context.colors.pureWhite.withValues(alpha: 0.54), size: 50),
              if (widget.isUploading)
                Container(
                  color: context.colors.pureBlack.withValues(alpha: 0.3),
                  child: Center(
                    child: CircularProgressIndicator(color: context.colors.pureWhite),
                  ),
                ),
              if (_isInitialized && !widget.isUploading)
                Icon(CommonIcons.playArrowRounded, color: context.colors.pureWhite, size: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioWaveformPlayer extends StatefulWidget {
  final String? audioUrl;
  final bool isMe;
  final double? payloadDuration;
  const _AudioWaveformPlayer({required this.audioUrl, required this.isMe, this.payloadDuration});

  @override
  State<_AudioWaveformPlayer> createState() => _AudioWaveformPlayerState();
}

class _AudioWaveformPlayerState extends State<_AudioWaveformPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isSourceInitialized = false;

  final List<double> _barHeights = [
    10, 16, 12, 22, 26, 14, 20, 12, 16, 10, 24, 28, 20, 14, 18,
    12, 20, 24, 10, 14, 18, 22, 16, 12, 20, 14, 10, 16, 12, 20
  ];

  @override
  void initState() {
    super.initState();
    if (widget.payloadDuration != null) {
      _duration = Duration(milliseconds: (widget.payloadDuration! * 1000).round());
    }
    _setupAudioPlayer();
    _initAudioSource();
  }

  Future<void> _initAudioSource() async {
    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      try {
        final url = _resolveUrl(widget.audioUrl!);
        final bool isLocal = !kIsWeb && File(url).existsSync();
        await _audioPlayer.setSource(
          isLocal ? DeviceFileSource(url) : UrlSource(url),
        );
        _isSourceInitialized = true;
      } catch (e) {
        debugPrint('Error setting initial audio source: $e');
      }
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((d) {
      if (widget.payloadDuration == null && mounted) {
        setState(() => _duration = d);
      }
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) {
        // If we have a payload duration, clamp position to not exceed duration
        final currentPosition = widget.payloadDuration != null && p > _duration ? _duration : p;
        setState(() => _position = currentPosition);
      }
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      _audioPlayer.seek(Duration.zero);
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _resolveUrl(String path) {
    String url = path;
    if (url.contains('minio')) {
      try {
        final serverUri = Uri.parse(CommonEndpoints.baseUrl);
        final host = serverUri.host;
        if (host.isNotEmpty) {
          url = url.replaceAll('minio', host);
        }
      } catch (_) {}
    }

    final bool isLocalFile = !kIsWeb && File(url).existsSync();

    if (!url.startsWith('http') && !url.startsWith('https') && !isLocalFile) {
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
    return url;
  }

  Future<void> _togglePlay() async {
    if (widget.audioUrl == null || widget.audioUrl!.isEmpty) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      try {
        if (!_isSourceInitialized) {
          final url = _resolveUrl(widget.audioUrl!);
          final bool isLocal = !kIsWeb && File(url).existsSync();
          await _audioPlayer.play(
            isLocal ? DeviceFileSource(url) : UrlSource(url),
          );
          _isSourceInitialized = true;
        } else {
          await _audioPlayer.resume();
        }
        if (mounted) setState(() => _isPlaying = true);
      } catch (e) {
        debugPrint('Error playing audio: $e');
      }
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isMe ? context.colors.pureWhite : context.colors.primary;
    final inactiveColor = widget.isMe ? context.colors.pureWhite.withValues(alpha: 0.4) : context.colors.textHint;
    final buttonBg = widget.isMe ? context.colors.pureWhite : context.colors.primary;
    final buttonIconColor = widget.isMe ? context.colors.primary : context.colors.pureWhite;

    final double progress = _duration.inMilliseconds > 0 
        ? _position.inMilliseconds / _duration.inMilliseconds 
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 150),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play button
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: buttonBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? CommonIcons.pause : CommonIcons.playArrow,
                color: buttonIconColor,
                size: 20,
              ),
            ),
          ),
          CommonSpaces.w8,
          // Waveform
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                const barWidth = 2.0;
                const spacing = 2.0;
                final int barsCount = (availableWidth / (barWidth + spacing)).floor().clamp(5, 30);
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(barsCount, (index) {
                    final barProgress = index / barsCount;
                    final isPlayed = progress >= barProgress;
                    return Container(
                      width: barWidth,
                      height: _barHeights[index % _barHeights.length],
                      decoration: BoxDecoration(
                        color: isPlayed ? activeColor : inactiveColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          CommonSpaces.w8,
          // Duration
          Text(
            "${_formatDuration(_position)} / ${_formatDuration(_duration)}",
            style: context.bodySmall.copyWith(
              color: activeColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
