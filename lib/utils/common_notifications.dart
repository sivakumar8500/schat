import 'dart:async';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:schat/main.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';

extension NotificationExt on BuildContext {
  void showErrorNotification(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(this);
    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(CommonIcons.errorOutline, color: colors.pureWhite, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: bodyMedium.copyWith(color: colors.pureWhite),
                ),
              ),
            ],
          ),
          backgroundColor: colors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    Flushbar(
      message: message,
      messageText: Text(
        message,
        style: bodyMedium.copyWith(color: colors.pureWhite),
      ),
      backgroundColor: colors.error,
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(12),
      icon: Icon(CommonIcons.errorOutline, color: colors.pureWhite),
      shouldIconPulse: false,
    ).show(this);
  }

  void showSuccessNotification(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(this);
    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(CommonIcons.checkCircleOutline, color: colors.pureWhite, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: bodyMedium.copyWith(color: colors.pureWhite),
                ),
              ),
            ],
          ),
          backgroundColor: colors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    Flushbar(
      message: message,
      messageText: Text(
        message,
        style: bodyMedium.copyWith(color: colors.pureWhite),
      ),
      backgroundColor: colors.success,
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(12),
      icon: Icon(CommonIcons.checkCircleOutline, color: colors.pureWhite),
      shouldIconPulse: false,
    ).show(this);
  }

  void showInfoNotification(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(this);
    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(CommonIcons.infoOutline, color: colors.pureWhite, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: bodyMedium.copyWith(color: colors.pureWhite),
                ),
              ),
            ],
          ),
          backgroundColor: colors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    Flushbar(
      message: message,
      messageText: Text(
        message,
        style: bodyMedium.copyWith(color: colors.pureWhite),
      ),
      backgroundColor: colors.primary,
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(12),
      icon: Icon(CommonIcons.infoOutline, color: colors.pureWhite),
      shouldIconPulse: false,
    ).show(this);
  }

  void showDownloadNotification(String message, {double? progress}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(this);
    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CommonIcons.downloading, color: colors.pureWhite, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: bodyMedium.copyWith(color: colors.pureWhite),
                    ),
                  ),
                ],
              ),
              if (progress != null) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: colors.pureWhite.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(colors.pureWhite),
                ),
              ],
            ],
          ),
          backgroundColor: colors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
          duration: progress == null ? const Duration(seconds: 3) : const Duration(seconds: 10),
        ),
      );
      return;
    }
    Flushbar(
      message: message,
      messageText: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: bodyMedium.copyWith(color: colors.pureWhite),
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: colors.pureWhite.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(colors.pureWhite),
            ),
          ],
        ],
      ),
      backgroundColor: colors.primary,
      duration: progress == null ? const Duration(seconds: 3) : null,
      flushbarPosition: FlushbarPosition.TOP,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(12),
      icon: Icon(CommonIcons.downloading, color: colors.pureWhite),
    ).show(this);
  }

  void showInAppChatNotification({
    required String senderName,
    required String messageText,
    String? profilePictureUrl,
    required VoidCallback onTap,
  }) {
    InAppNotificationBannerManager.show(
      context: this,
      senderName: senderName,
      messageText: messageText,
      profilePictureUrl: profilePictureUrl,
      onTap: onTap,
    );
  }
}

class InAppNotificationBannerManager {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show({
    required BuildContext context,
    required String senderName,
    required String messageText,
    String? profilePictureUrl,
    required VoidCallback onTap,
  }) {
    final overlay = Overlay.maybeOf(context) ?? navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    // Dismiss existing banner if any
    _dismissCurrent();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _InAppNotificationBannerWidget(
        senderName: senderName,
        messageText: messageText,
        profilePictureUrl: profilePictureUrl,
        onDismiss: () {
          if (_currentEntry == entry) {
            _dismissCurrent();
          }
        },
        onTap: () {
          _dismissCurrent();
          onTap();
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(const Duration(seconds: 4), () {
      if (_currentEntry == entry) {
        _dismissCurrent();
      }
    });
  }

  static void _dismissCurrent() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_currentEntry != null) {
      final entryToDismiss = _currentEntry;
      _currentEntry = null;
      try {
        entryToDismiss?.remove();
      } catch (_) {}
    }
  }
}

class _InAppNotificationBannerWidget extends StatefulWidget {
  final String senderName;
  final String messageText;
  final String? profilePictureUrl;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _InAppNotificationBannerWidget({
    required this.senderName,
    required this.messageText,
    this.profilePictureUrl,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_InAppNotificationBannerWidget> createState() => _InAppNotificationBannerWidgetState();
}

class _InAppNotificationBannerWidgetState extends State<_InAppNotificationBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismissWithAnimation() async {
    try {
      await _controller.reverse();
    } catch (_) {}
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top > 0 ? mediaQuery.padding.top + 8 : 16.0;

    return Positioned(
      top: topPadding,
      left: 12,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: widget.onTap,
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null && details.primaryVelocity! < -80) {
                  _dismissWithAnimation();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF383B3E),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      offset: const Offset(0, 8),
                      blurRadius: 24,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Circular Avatar with App Icon Badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF4A4E54),
                          ),
                          child: ClipOval(
                            child: (widget.profilePictureUrl != null &&
                                    widget.profilePictureUrl!.trim().isNotEmpty)
                                ? Image.network(
                                    widget.profilePictureUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        _buildNotificationAvatarPlaceholder(widget.senderName),
                                  )
                                : _buildNotificationAvatarPlaceholder(widget.senderName),
                          ),
                        ),
                        // Small App Icon Badge in Bottom-Right
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF383B3E),
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.chat_bubble_rounded,
                                color: Colors.white,
                                size: 9,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Content Column (Sender Name + now + chevron, Message text)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.senderName,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'now',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white60,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white54,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.messageText,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildNotificationAvatarPlaceholder(String name) {
  final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'S';
  return Container(
    width: 44,
    height: 44,
    color: const Color(0xFF00873C),
    child: Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    ),
  );
}
