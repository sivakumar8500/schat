import 'dart:async';
import 'dart:ui';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:schat/main.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fonts.dart';
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
      duration: const Duration(milliseconds: 320),
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
    final topPadding = mediaQuery.padding.top > 0 ? mediaQuery.padding.top + 6 : 16.0;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF111B21);
    final secondaryTextColor = isDarkMode ? const Color(0xFFA0AEC0) : const Color(0xFF64748B);
    final borderHighlightColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.75);

    return Positioned(
      top: topPadding,
      left: 14,
      right: 14,
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
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDarkMode ? 0.40 : 0.14),
                      offset: const Offset(0, 10),
                      blurRadius: 28,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 18, 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDarkMode
                              ? [
                                  const Color(0xFF222831).withValues(alpha: 0.85),
                                  const Color(0xFF1B2028).withValues(alpha: 0.92),
                                ]
                              : [
                                  Colors.white.withValues(alpha: 0.88),
                                  const Color(0xFFF1F5F9).withValues(alpha: 0.94),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: borderHighlightColor,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Squircle Avatar: User Profile Picture or SChat Logo
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : Colors.black.withValues(alpha: 0.08),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: (widget.profilePictureUrl != null &&
                                      widget.profilePictureUrl!.trim().isNotEmpty)
                                  ? Image.network(
                                      widget.profilePictureUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          _buildNotificationAppLogo(),
                                    )
                                  : _buildNotificationAppLogo(),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Content Column (Sender Name + now timestamp, message preview)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.senderName,
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700,
                                          color: primaryTextColor,
                                          fontFamily: CommonFonts.primaryFont,
                                          letterSpacing: -0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'now',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: secondaryTextColor,
                                        fontFamily: CommonFonts.primaryFont,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.messageText,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400,
                                    color: secondaryTextColor,
                                    fontFamily: CommonFonts.primaryFont,
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
          ),
        ),
      ),
    );
  }
}

Widget _buildNotificationAppLogo() {
  return Container(
    width: 44,
    height: 44,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF25D366), Color(0xFF128C7E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    padding: const EdgeInsets.all(7),
    child: Image.asset(
      CommonIcons.logo,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 22),
      ),
    ),
  );
}

