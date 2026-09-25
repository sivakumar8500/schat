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
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart' show CallMeta;
import 'package:schat/features/chat_screen/src/domain/models/media_access_tree_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/in_app_viewer.dart';
import 'package:schat/utils/download_helper/download_helper.dart';
import 'package:schat/utils/common_endpoints.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async' show StreamSubscription;
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_event.dart';
import 'package:schat/features/chat_screen/src/presentation/chat_page.dart';

class MessageBubble extends StatefulWidget {
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
  final bool isFileViewed;
  final bool isFileDownloaded;
  final bool isFileShared;
  final VoidCallback? onSharePressed;
  final int? fileSize;
  final CallMeta? callMeta;
  final bool isRecipientOnline;
  final VoidCallback? onReplyTap;
  final int? pinnedAt;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? locationTitle;
  final int? expiry;

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
    this.isFileViewed = false,
    this.isFileDownloaded = false,
    this.isFileShared = false,
    this.onSharePressed,
    this.fileSize,
    this.callMeta,
    this.isRecipientOnline = false,
    this.onReplyTap,
    this.duration,
    this.pinnedAt,
    this.latitude,
    this.longitude,
    this.address,
    this.locationTitle,
    this.expiry,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  String get messageId => widget.messageId;
  String get conversationId => widget.conversationId;
  String get message => widget.message;
  String get time => widget.time;
  bool get isMe => widget.isMe;
  bool get isRead => widget.isRead;
  bool get isDelivered => widget.isDelivered;
  bool get isDeleted => widget.isDeleted;
  String get type => widget.type;
  double? get duration => widget.duration;
  String? get attachmentPath => widget.attachmentPath;
  String? get attachmentName => widget.attachmentName;
  Uint8List? get attachmentBytes => widget.attachmentBytes;
  bool get isReply => widget.isReply;
  String? get replyMessageId => widget.replyMessageId;
  String? get replyMessageBody => widget.replyMessageBody;
  String? get replyMessageSenderName => widget.replyMessageSenderName;
  bool get isEdited => widget.isEdited;
  bool get isPinned => widget.isPinned;
  bool get isSelected => widget.isSelected;
  bool get isHighlighted => widget.isHighlighted;
  bool get isUploading => widget.isUploading;
  bool get isFailed => widget.isFailed;
  VoidCallback? get onResendPressed => widget.onResendPressed;
  bool get isGroup => widget.isGroup;
  bool get allowShare => widget.allowShare;
  bool get allowDownload => widget.allowDownload;
  bool get allowView => widget.allowView;
  bool get isFileViewed => widget.isFileViewed;
  bool get isFileDownloaded => widget.isFileDownloaded;
  bool get isFileShared => widget.isFileShared;
  VoidCallback? get onSharePressed => widget.onSharePressed;
  int? get fileSize => widget.fileSize;
  CallMeta? get callMeta => widget.callMeta;
  bool get isRecipientOnline => widget.isRecipientOnline;
  VoidCallback? get onReplyTap => widget.onReplyTap;
  int? get pinnedAt => widget.pinnedAt;
  double? get latitude => widget.latitude;
  double? get longitude => widget.longitude;
  String? get address => widget.address;
  String? get locationTitle => widget.locationTitle;
  int? get expiry => widget.expiry;

  bool get _isMediaMessage {
    if (type == 'image' || type == 'video' || type == 'file') return true;
    if ((attachmentPath != null || attachmentBytes != null) &&
        type != 'call' &&
        type != 'location' &&
        type != 'contact' &&
        type != 'text') {
      return true;
    }
    return false;
  }

  String _formatSystemMessage(String msg) {
    final RegExp regex = RegExp(r'(\d+)\s*seconds?');
    return msg.replaceAllMapped(regex, (match) {
      final secondsStr = match.group(1);
      if (secondsStr != null) {
        final int seconds = int.tryParse(secondsStr) ?? 0;
        if (seconds == 0) return 'Off';
        if (seconds < 60) return '$seconds seconds';
        if (seconds < 3600) {
          final mins = seconds ~/ 60;
          return '$mins min';
        }
        if (seconds < 86400) {
          final hours = seconds ~/ 3600;
          return '$hours hr';
        }
        final days = seconds ~/ 86400;
        return '$days day${days > 1 ? 's' : ''}';
      }
      return match.group(0)!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isSystemMessage = type == 'system' ||
        type == 'group_event' ||
        type == 'notification' ||
        _isGroupEvent(message);

    if (isSystemMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const Expanded(child: Divider(indent: 16, endIndent: 8)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: context.colors.lightBackground,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: context.colors.border,
                  width: 0.5,
                ),
              ),
              child: Text(
                _formatSystemMessage(message),
                textAlign: TextAlign.center,
                style: context.bodySmall.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            const Expanded(child: Divider(indent: 8, endIndent: 16)),
          ],
        ),
      );
    }

    final isMedia = _isMediaMessage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: isSelected
          ? context.colors.primary.withValues(alpha: 0.15)
          : (isHighlighted ? context.colors.primary.withValues(alpha: 0.25) : context.colors.transparent),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
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
                  maxWidth: isMedia ? 244 : MediaQuery.of(context).size.width * 0.72,
                ),
                child: Container(
                  width: isMedia ? 244 : null,
                  padding: isMedia
                      ? const EdgeInsets.all(8)
                      : const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isMe
                        ? (isMedia
                            ? (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF132B25)
                                : context.colors.sentBubble)
                            : context.colors.sentBubble)
                        : (isMedia
                            ? (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1E2B33)
                                : context.colors.lightBackground)
                            : context.colors.lightBackground),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                    ),
                    border: isMedia
                        ? Border.all(
                            color: const Color(0xFF00D084).withValues(alpha: 0.15),
                            width: 0.8,
                          )
                        : null,
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
                      if (isMedia) ...[
                        if (!isDeleted) _buildAttachment(context),
                        if (message.isNotEmpty && (type == 'text' || message != attachmentName) && type != 'text' && !isDeleted)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                            child: _buildMessageText(
                              context,
                              context.bodyLarge.copyWith(
                                fontSize: 14,
                                color: isMe ? context.colors.textPrimary : context.colors.textPrimary,
                              ),
                              message,
                            ),
                          ),
                        if (!isDeleted) _buildMediaActionBar(context),
                        if (!isDeleted) _buildMediaFooter(context),
                      ] else ...[
                        if (!isDeleted) _buildAttachment(context),
                        if (!isDeleted) _buildPermissionControls(context),
                        _buildMessageText(
                          context,
                          context.bodyLarge.copyWith(
                            fontSize: 16,
                            color: isMe ? context.colors.textPrimary : context.colors.textPrimary,
                          ),
                          type == 'location' ? '' : message,
                        ),
                        if (message.isNotEmpty && (type == 'text' || message != attachmentName) && type != 'text' && !isDeleted) CommonSpaces.h6,
                        _buildDefaultTimestampRow(context),
                      ],
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

  Widget _buildMediaActionBar(BuildContext context) {
    const accentGreen = Color(0xFF00D084);
    final textColor = isMe ? context.colors.pureWhite : context.colors.textPrimary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> actionButtons = [];

    // 1. View Action (Show if isMe or allowView is granted)
    if (isMe || allowView) {
      actionButtons.add(
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (!allowView && !isMe) {
              context.showInfoNotification('View permission is restricted by sender');
              return;
            }
            _openInAppViewer(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  allowView || isMe ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 16,
                  color: allowView || isMe ? accentGreen : context.colors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'View',
                  style: context.bodySmall.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. Download Action (Show if isMe or allowDownload is granted)
    if (isMe || allowDownload) {
      actionButtons.add(
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (!allowDownload && !isMe) {
              context.showInfoNotification('Download permission is locked by sender');
              return;
            }
            _triggerDownload(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  allowDownload || isMe ? Icons.file_download_outlined : Icons.file_download_off_outlined,
                  size: 16,
                  color: allowDownload || isMe ? accentGreen : context.colors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Download',
                  style: context.bodySmall.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Share Action (Show if isMe or allowShare is granted)
    if (isMe || allowShare) {
      actionButtons.add(
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (!allowShare && !isMe) {
              context.showInfoNotification('Share permission is locked by sender');
              return;
            }
            _triggerShare(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  allowShare || isMe ? Icons.share_outlined : Icons.block_outlined,
                  size: 15,
                  color: allowShare || isMe ? accentGreen : context.colors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Share',
                  style: context.bodySmall.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (actionButtons.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 13, color: isDark ? Colors.white60 : Colors.black54),
            const SizedBox(width: 5),
            Text(
              'Access restricted by sender',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
      child: Row(
        mainAxisAlignment: actionButtons.length == 3 ? MainAxisAlignment.spaceBetween : MainAxisAlignment.spaceEvenly,
        children: actionButtons,
      ),
    );
  }

  Widget _buildMediaFooter(BuildContext context) {
    const accentGreen = Color(0xFF00D084);

    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 2.0, left: 4.0, right: 4.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
        children: [
          // Left: Show share details > (ONLY FOR SENDER)
          if (isMe)
            Flexible(
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _openShareDetailsBottomSheet(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.assignment_outlined,
                        size: 14,
                        color: accentGreen,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Show share details',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.bodySmall.copyWith(
                            color: accentGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 1),
                      const Icon(
                        Icons.chevron_right,
                        size: 15,
                        color: accentGreen,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (isMe) const SizedBox(width: 6),

          // Right: Timestamp and checkmark status
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 12,
                color: context.colors.textSecondary,
              ),
              const SizedBox(width: 3),
              Text(
                time,
                style: context.bodySmall.copyWith(
                  fontSize: 11,
                  color: context.colors.textSecondary,
                ),
              ),
              if (isMe) ...[
                CommonSpaces.w4,
                _buildDeliveryStatus(context),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String? _getMediaId() {
    final uuidRegex = RegExp(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}');
    if (widget.attachmentPath != null) {
      final matches = uuidRegex.allMatches(widget.attachmentPath!);
      if (matches.isNotEmpty) {
        return matches.last.group(0);
      }
    }
    if (uuidRegex.hasMatch(widget.messageId)) {
      return widget.messageId;
    }
    return null;
  }

  void _openShareDetailsBottomSheet(BuildContext context) {
    final mediaId = _getMediaId();
    final Future<MediaAccessTreeModel?> accessTreeFuture = (mediaId != null && mediaId.isNotEmpty)
        ? getIt<ChatRepository>().getMediaAccessTree(mediaId).then<MediaAccessTreeModel?>((v) => v).catchError((_) => null)
        : Future<MediaAccessTreeModel?>.value(null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            const accentGreen = Color(0xFF00D084);
            final sheetBg = isDark ? const Color(0xFF1B232A) : context.colors.pureWhite;
            final cardBg = isDark ? const Color(0xFF131A20) : context.colors.lightBackground;
            final textColor = isDark ? Colors.white : context.colors.textPrimary;
            final subTextColor = isDark ? Colors.white70 : context.colors.textSecondary;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.security,
                              color: accentGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isMe ? 'Share & Protection Details' : 'Security & Protection',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  attachmentName ?? (type == 'image' ? 'Image File' : (type == 'video' ? 'Video File' : 'Media Attachment')),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: subTextColor, size: 20),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section 1: Compact Access Permissions Card (Icons Only)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: accentGreen.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: accentGreen.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.lock_outline, size: 16, color: accentGreen),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isMe ? 'Access Permissions' : 'File Protection',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: textColor,
                                          ),
                                        ),
                                        Text(
                                          isMe ? 'Tap icon to toggle' : 'Policies by sender',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: subTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Compact Square Icons (View, Download, Share)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildCompactPermissionIcon(
                                        context: context,
                                        icon: allowView ? CommonIcons.visibility : CommonIcons.visibilityOff,
                                        tooltip: allowView ? 'View: Allowed' : 'View: Locked',
                                        allowed: allowView,
                                        isInteractive: isMe,
                                        onTap: isMe
                                            ? () {
                                                _updatePermissions(context, view: !allowView);
                                                setModalState(() {});
                                              }
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildCompactPermissionIcon(
                                        context: context,
                                        icon: allowDownload ? CommonIcons.download : CommonIcons.downloadOff,
                                        tooltip: allowDownload ? 'Download: Allowed' : 'Download: Locked',
                                        allowed: allowDownload,
                                        isInteractive: isMe,
                                        onTap: isMe
                                            ? () {
                                                _updatePermissions(context, download: !allowDownload);
                                                setModalState(() {});
                                              }
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildCompactPermissionIcon(
                                        context: context,
                                        icon: allowShare ? CommonIcons.share : CommonIcons.shareOff,
                                        tooltip: allowShare ? 'Share: Allowed' : 'Share: Locked',
                                        allowed: allowShare,
                                        isInteractive: isMe,
                                        onTap: isMe
                                            ? () {
                                                _updatePermissions(context, share: !allowShare);
                                                setModalState(() {});
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Section 2: Share & Access Lineage (Access Tree API)
                            FutureBuilder<MediaAccessTreeModel?>(
                              future: accessTreeFuture,
                              builder: (context, snapshot) {
                                final isWaiting = snapshot.connectionState == ConnectionState.waiting;
                                final accessTreeModel = snapshot.data;
                                final grants = accessTreeModel?.accessTree ?? [];
                                final totalGrants = accessTreeModel?.totalGrants ?? grants.length;

                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF2A3630) : const Color(0xFFE5E9E7),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'SHARE & ACCESS LINEAGE',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.1,
                                              color: subTextColor,
                                            ),
                                          ),
                                          if (!isWaiting)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: accentGreen.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '$totalGrants ${totalGrants == 1 ? 'Share' : 'Shares'}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: accentGreen,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      if (isWaiting)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 16),
                                          child: Center(
                                            child: SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: accentGreen,
                                              ),
                                            ),
                                          ),
                                        )
                                      else if (grants.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          child: Row(
                                            children: [
                                              Icon(Icons.share_outlined, size: 16, color: subTextColor),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'No one has forwarded or reshared this file yet.',
                                                  style: TextStyle(fontSize: 12, color: subTextColor),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        Column(
                                          children: grants
                                              .map((node) => _buildAccessTreeNodeItem(
                                                    node: node,
                                                    isDark: isDark,
                                                    textColor: textColor,
                                                    subTextColor: subTextColor,
                                                    accentGreen: accentGreen,
                                                    level: 0,
                                                  ))
                                              .toList(),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 14),

                            // Section 3: Active Protection Policies
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF2A3630) : const Color(0xFFE5E9E7),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ACTIVE PROTECTION POLICIES',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                      color: subTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.lock_outline_rounded, size: 18, color: subTextColor),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'End-to-End Encryption',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: textColor,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              'AES-256-GCM encrypted in-transit & at-rest',
                                              style: TextStyle(fontSize: 11, color: subTextColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: accentGreen.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: accentGreen.withValues(alpha: 0.4), width: 0.8),
                                        ),
                                        child: const Text(
                                          'Enforced',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: accentGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16, thickness: 0.6),
                                  Row(
                                    children: [
                                      Icon(Icons.screenshot_monitor_rounded, size: 18, color: subTextColor),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Anti-Screenshot & DRM',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: textColor,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              'Protected against unauthorized capture',
                                              style: TextStyle(fontSize: 11, color: subTextColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: (allowDownload ? Colors.orangeAccent : accentGreen).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: (allowDownload ? Colors.orangeAccent : accentGreen).withValues(alpha: 0.4),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          allowDownload ? 'Allowed' : 'Secured',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: allowDownload ? Colors.orangeAccent : accentGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Done Button
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentGreen,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(sheetContext),
                                child: const Text(
                                  'Done',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAccessTreeNodeItem({
    required AccessTreeNode node,
    required bool isDark,
    required Color textColor,
    required Color subTextColor,
    required Color accentGreen,
    required int level,
  }) {
    final isActive = node.status.toLowerCase() == 'active';
    final perms = node.effectivePermissions;

    return Padding(
      padding: EdgeInsets.only(left: level * 16.0, bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2830) : const Color(0xFFF4F6F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (level > 0)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Text('↳', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  ),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: accentGreen.withValues(alpha: 0.2),
                  child: Text(
                    node.grantee.initials,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.grantee.displayName,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (node.granter.displayName.isNotEmpty)
                        Text(
                          'Shared by ${node.granter.displayName}',
                          style: TextStyle(fontSize: 10, color: subTextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isActive ? accentGreen : Colors.redAccent).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    node.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isActive ? accentGreen : Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Permission Badges
            Row(
              children: [
                _buildPermissionChip('View', perms.canView, isDark),
                const SizedBox(width: 4),
                _buildPermissionChip('Download', perms.canDownload, isDark),
                const SizedBox(width: 4),
                _buildPermissionChip('Share', perms.canShare, isDark),
              ],
            ),
            if (node.downstreamShares.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...node.downstreamShares.map(
                (child) => _buildAccessTreeNodeItem(
                  node: child,
                  isDark: isDark,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  accentGreen: accentGreen,
                  level: level + 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionChip(String label, bool allowed, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: allowed
            ? (const Color(0xFF00D084)).withValues(alpha: 0.12)
            : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            allowed ? Icons.check : Icons.close,
            size: 10,
            color: allowed ? const Color(0xFF00D084) : Colors.grey,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: allowed ? const Color(0xFF00D084) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPermissionIcon({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required bool allowed,
    required bool isInteractive,
    VoidCallback? onTap,
  }) {
    const accentGreen = Color(0xFF00D084);
    final color = allowed ? accentGreen : context.colors.error;
    final bg = color.withValues(alpha: allowed ? 0.15 : 0.1);
    final border = color.withValues(alpha: 0.4);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border, width: 1),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryStatus(BuildContext context) {
    final isPending = messageId.startsWith('temp_') ||
        isUploading ||
        (!isDelivered && !isRead && !isFailed);
    if (isPending && !isFailed) {
      return Icon(
        CommonIcons.done,
        size: 14,
        color: context.colors.textSecondary,
      );
    }
    if (isRead) {
      return const Icon(
        CommonIcons.doneAll,
        size: 14,
        color: Color(0xFF2196F3),
      );
    }
    if (isDelivered) {
      return Icon(
        CommonIcons.doneAll,
        size: 14,
        color: context.colors.textSecondary,
      );
    }
    return Icon(
      CommonIcons.done,
      size: 14,
      color: context.colors.textSecondary,
    );
  }

  Widget _buildDefaultTimestampRow(BuildContext context) {
    return Row(
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
        if (expiry != null && expiry! > 0) ...[
          Icon(
            Icons.timer_outlined,
            size: 11,
            color: context.colors.textSecondary,
          ),
          CommonSpaces.w2,
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
          _buildDeliveryStatus(context),
        ],
      ],
    );
  }

  Widget _buildAttachment(BuildContext context) {
    if (attachmentPath == null && attachmentBytes == null && type != 'call' && type != 'location') {
      return const SizedBox.shrink();
    }

    final viewLocked = !allowView && !isMe;

    Widget result;
    if (type == 'image') {
      Widget imageWidget;
      if (attachmentBytes != null) {
        imageWidget = Image.memory(
          attachmentBytes!,
          height: 220,
          width: double.infinity,
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
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                _fileChip(context, CommonIcons.brokenImage, 'Image error'),
          );
        } else if (isLocalFile) {
          imageWidget = Image.file(
            File(displayUrl),
            height: 220,
            width: double.infinity,
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
              s3BaseUrl = 'https://qlyncs-docs.s3.amazonaws.com/';
            }
          } catch (_) {
            s3BaseUrl = 'https://qlyncs-docs.s3.amazonaws.com/';
          }
          final s3Url = '$s3BaseUrl$displayUrl';
          imageWidget = Image.network(
            s3Url,
            height: 220,
            width: double.infinity,
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
      if (viewLocked) {
        result = _buildLockedAttachmentCard(context, type: type, label: 'Audio Restricted');
      } else {
        result = _AudioWaveformPlayer(
          audioUrl: attachmentPath,
          isMe: isMe,
          payloadDuration: duration,
        );
      }
    } else if (type == 'video') {
      if (viewLocked) {
        result = _buildLockedAttachmentCard(context, type: type, label: 'Video Restricted');
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
        result = _buildLockedAttachmentCard(context, type: type, label: 'File Restricted');
      } else {
        result = _buildFileBubbleCard(context);
      }
    } else if (type == 'location') {
      double lat = latitude ?? 0.0;
      double lng = longitude ?? 0.0;
      
      // Fallback for old messages that might still use attachmentPath
      if (lat == 0.0 && lng == 0.0 && attachmentPath != null && attachmentPath!.contains(',')) {
        final parts = attachmentPath!.split(',');
        if (parts.length == 2) {
          lat = double.tryParse(parts[0]) ?? 0.0;
          lng = double.tryParse(parts[1]) ?? 0.0;
        }
      }

      result = Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () async {
            if (lat != 0.0 && lng != 0.0) {
              final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                if (context.mounted) {
                  context.showErrorNotification('Could not open Maps');
                }
              }
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 180,
              width: 260,
              color: isMe
                  ? context.colors.pureWhite.withValues(alpha: 0.15)
                  : context.colors.lightBackground,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (lat != 0.0 && lng != 0.0)
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(lat, lng),
                        zoom: 15,
                      ),
                      liteModeEnabled: true,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      mapToolbarEnabled: false,
                      markers: {
                        Marker(
                          markerId: const MarkerId('loc'),
                          position: LatLng(lat, lng),
                        ),
                      },
                    )
                  else
                    Container(
                      color: context.colors.lightBackground,
                    ),
                  if (lat == 0.0 && lng == 0.0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.colors.scaffoldBackground.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CommonIcons.location,
                            color: context.colors.error,
                            size: 36,
                          ),
                          CommonSpaces.h8,
                          Text(
                            'Location',
                            style: context.bodySmall.copyWith(
                              fontSize: 11,
                              color: context.colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Coordinate overlay
                  if (lat != 0.0 && lng != 0.0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        color: Colors.black.withValues(alpha: 0.6),
                        child: Text(
                          'Lat: $lat, Lng: $lng',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
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
      String sanitizePhone(String raw) {
        final first = raw.split(RegExp(r'[,;]')).first.trim();
        return first.replaceAll(RegExp(r'[^\d+]'), '');
      }

      final cleanedPhone = sanitizePhone(phone.isNotEmpty ? phone : displayPhone);

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
                              ? (isMe ? context.colors.pureWhite.withValues(alpha: 0.7) : context.colors.textSecondary)
                              : (isMe ? context.colors.pureWhite.withValues(alpha: 0.4) : context.colors.textHint), // blur/muted color!
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

  Widget _buildLockedAttachmentCard(BuildContext context, {required String type, required String label}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? context.colors.pureWhite.withValues(alpha: 0.1)
            : context.colors.textHint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colors.textHint.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colors.textHint.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CommonIcons.lockOutline,
              color: isMe ? context.colors.pureWhite : context.colors.textSecondary,
              size: 20,
            ),
          ),
          CommonSpaces.w12,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: context.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isMe ? context.colors.pureWhite : context.colors.textPrimary,
                ),
              ),
              CommonSpaces.h2,
              Text(
                'Playback & viewing locked by sender',
                style: context.bodySmall.copyWith(
                  fontSize: 11,
                  color: isMe ? context.colors.pureWhite.withValues(alpha: 0.7) : context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionControls(BuildContext context) {
    if (attachmentPath == null && attachmentBytes == null) {
      return const SizedBox.shrink();
    }

    if (isGroup) {
      return const SizedBox.shrink();
    }

    if (isMe) {
      final activeBg = context.colors.primary.withValues(alpha: 0.12);
      final activeIcon = context.colors.primary;
      final activeBorder = context.colors.primary.withValues(alpha: 0.35);

      final viewedBg = context.colors.primary;
      final viewedIcon = context.colors.pureWhite;
      final viewedBorder = context.colors.primary;

      final inactiveBg = context.colors.error.withValues(alpha: 0.12);
      final inactiveIcon = context.colors.error;
      final inactiveBorder = context.colors.error.withValues(alpha: 0.35);

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
                label: allowView ? (isFileViewed ? 'Viewed' : 'View Allowed') : 'View Locked',
                backgroundColor: allowView ? (isFileViewed ? viewedBg : activeBg) : inactiveBg,
                textColor: allowView ? (isFileViewed ? viewedIcon : activeIcon) : inactiveIcon,
                borderColor: allowView ? (isFileViewed ? viewedBorder : activeBorder) : inactiveBorder,
                onTap: () => _updatePermissions(context, view: !allowView),
              ),
              _buildCapsuleChip(
                context: context,
                icon: allowDownload ? CommonIcons.download : CommonIcons.downloadOff,
                label: allowDownload ? (isFileDownloaded ? 'Downloaded' : 'Download Allowed') : 'Download Locked',
                backgroundColor: allowDownload ? (isFileDownloaded ? viewedBg : activeBg) : inactiveBg,
                textColor: allowDownload ? (isFileDownloaded ? viewedIcon : activeIcon) : inactiveIcon,
                borderColor: allowDownload ? (isFileDownloaded ? viewedBorder : activeBorder) : inactiveBorder,
                onTap: () => _updatePermissions(context, download: !allowDownload),
              ),
              _buildCapsuleChip(
                context: context,
                icon: allowShare ? CommonIcons.share : CommonIcons.shareOff,
                label: allowShare ? (isFileShared ? 'Shared' : 'Share Allowed') : 'Share Locked',
                backgroundColor: allowShare ? (isFileShared ? viewedBg : activeBg) : inactiveBg,
                textColor: allowShare ? (isFileShared ? viewedIcon : activeIcon) : inactiveIcon,
                borderColor: allowShare ? (isFileShared ? viewedBorder : activeBorder) : inactiveBorder,
                onTap: () => _updatePermissions(context, share: !allowShare),
              ),
            ],
          ),
        ),
      );
    } else {
      final activeBg = context.colors.primary.withValues(alpha: 0.12);
      final activeIcon = context.colors.primary;
      final activeBorder = context.colors.primary.withValues(alpha: 0.35);

      final inactiveBg = context.colors.error.withValues(alpha: 0.12);
      final inactiveIcon = context.colors.error;
      final inactiveBorder = context.colors.error.withValues(alpha: 0.35);

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
                label: allowView ? 'View' : 'View Locked',
                backgroundColor: allowView ? activeBg : inactiveBg,
                textColor: allowView ? activeIcon : inactiveIcon,
                borderColor: allowView ? activeBorder : inactiveBorder,
                onTap: allowView ? () => _openInAppViewer(context) : null,
              ),
              _buildCapsuleChip(
                context: context,
                icon: allowDownload ? CommonIcons.download : CommonIcons.downloadOff,
                label: allowDownload ? 'Download' : 'Download Locked',
                backgroundColor: allowDownload ? activeBg : inactiveBg,
                textColor: allowDownload ? activeIcon : inactiveIcon,
                borderColor: allowDownload ? activeBorder : inactiveBorder,
                onTap: allowDownload ? () => _triggerDownload(context) : null,
              ),
              _buildCapsuleChip(
                context: context,
                icon: allowShare ? CommonIcons.share : CommonIcons.shareOff,
                label: allowShare ? 'Share' : 'Share Locked',
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
      margin: const EdgeInsets.only(right: 6.0, top: 4.0, bottom: 4.0),
      child: Material(
        color: context.colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor ?? context.colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: textColor),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: context.bodySmall.copyWith(
                      color: textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
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
    
    context.read<ChatSocketBloc>().add(SendEditMessage(
      messageId: messageId,
      security: {
        'isLocked': false,
        'allowShare': newShare,
        'allowDownload': newDownload,
        'allowView': newView,
      },
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

    if (messageId.isNotEmpty) {
      getIt<ChatRepository>().updateMessageSecurity(
        messageId,
        allowShare: newShare,
        allowDownload: newDownload,
        allowView: newView,
      ).catchError((e) {
        debugPrint('Failed to persist security permissions: $e');
      });
    }
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
          s3BaseUrl = 'https://qlyncs-docs.s3.amazonaws.com/';
        }
      } catch (_) {
        s3BaseUrl = 'https://qlyncs-docs.s3.amazonaws.com/';
      }
      url = '$s3BaseUrl$url';
    }

    InAppViewer.show(
      context,
      url: url,
      fileName: attachmentName ?? 'File',
      type: type,
      mediaId: messageId,
      allowShare: allowShare,
      allowDownload: allowDownload,
      onSharePressed: () {
        if (onSharePressed != null) {
          onSharePressed!();
        }
        getIt<ChatSocketRepository>().sendFileAction(
          type: 'share_file',
          conversationId: conversationId,
          messageId: messageId,
          fileKey: path,
        );
      },
      onDownloadPressed: () {
        if (!isLocalFile) {
          getIt<ChatSocketRepository>().sendFileAction(
            type: 'download_file',
            conversationId: conversationId,
            messageId: messageId,
            fileKey: path,
          );
        }
      },
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

  void _triggerDownload(BuildContext context) async {
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
          s3BaseUrl = 'https://qlyncs-docs.s3.amazonaws.com/';
        }
      } catch (_) {
        s3BaseUrl = 'https://qlyncs-docs.s3.amazonaws.com/';
      }
      url = '$s3BaseUrl$url';
    }

    final messenger = ScaffoldMessenger.of(context);
    final fileName = attachmentName ?? 'File';

    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Downloading $fileName: 0%'),
      ),
    );

    final downloadedFile = await downloadFile(
      url,
      fileName,
      onProgress: (received, total) {
        if (total > 0) {
          final pct = ((received / total) * 100).toInt();
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 1),
              content: Text('Downloading $fileName: $pct%'),
            ),
          );
        }
      },
    );

    if (!context.mounted) return;

    messenger.hideCurrentSnackBar();
    final savePath = downloadedFile?.path ?? 'Schat secure storage';
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: context.colors.primary,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ $fileName (100%) Encrypted & Downloaded',
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

  Widget _buildMessageText(BuildContext context, TextStyle baseStyle, String text) {
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

    if (text.isEmpty || (type != 'text' && text == attachmentName)) {
      return const SizedBox.shrink();
    }

    final RegExp urlRegex = RegExp(
      r'(https?://\S+|www\.\S+)',
      caseSensitive: false,
    );

    final matches = urlRegex.allMatches(text);
    if (matches.isEmpty) {
      return Text(
        text,
        style: baseStyle,
      );
    }

    final List<InlineSpan> spans = [];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
        ));
      }

      final url = text.substring(match.start, match.end);
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

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
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
      'disappearing',
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
          s3BaseUrl = 'https://qlyncs-docs.s3.amazonaws.com/';
        }
      } catch (_) {
        s3BaseUrl = 'https://qlyncs-docs.s3.amazonaws.com/';
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
          s3BaseUrl = 'https://qlyncs-docs.s3.amazonaws.com/';
        }
      } catch (_) {
        s3BaseUrl = 'https://qlyncs-docs.s3.amazonaws.com/';
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
