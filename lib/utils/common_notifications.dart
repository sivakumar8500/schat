import 'dart:async';
import 'package:flutter/material.dart';
import 'package:schat/main.dart';

extension NotificationExt on BuildContext {
  void showErrorNotification(String message) {
    debugPrint('Error notification: $message');
    AppToastManager.show(
      context: this,
      message: message,
      type: ToastType.error,
    );
  }

  void showSuccessNotification(String message) {
    debugPrint('Success notification: $message');
    AppToastManager.show(
      context: this,
      message: message,
      type: ToastType.success,
    );
  }

  void showInfoNotification(String message) {
    debugPrint('Info notification: $message');
    AppToastManager.show(
      context: this,
      message: message,
      type: ToastType.info,
    );
  }

  void showDownloadNotification(String message, {double? progress}) {
    debugPrint('Download notification: $message (progress: $progress)');
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

enum ToastType { error, success, info }

class AppToastManager {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show({
    required BuildContext context,
    required String message,
    ToastType type = ToastType.error,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (message.trim().isEmpty) return;
    final overlay = Overlay.maybeOf(context) ?? navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    // Dismiss existing toast
    _dismissCurrent();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _AppToastWidget(
        message: message,
        type: type,
        onDismiss: () {
          if (_currentEntry == entry) {
            _dismissCurrent();
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () {
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

class _AppToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  const _AppToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_AppToastWidget> createState() => _AppToastWidgetState();
}

class _AppToastWidgetState extends State<_AppToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
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
    final topPadding =
        mediaQuery.padding.top > 0 ? mediaQuery.padding.top + 8 : 16.0;

    final Color bgColor;
    final Color borderColor;
    final Color iconColor;
    final IconData iconData;

    switch (widget.type) {
      case ToastType.error:
        bgColor = const Color(0xFF261819);
        borderColor = const Color(0xFFE53935).withValues(alpha: 0.6);
        iconColor = const Color(0xFFFF5252);
        iconData = Icons.error_outline_rounded;
        break;
      case ToastType.success:
        bgColor = const Color(0xFF14241B);
        borderColor = const Color(0xFF00FF87).withValues(alpha: 0.6);
        iconColor = const Color(0xFF00FF87);
        iconData = Icons.check_circle_outline_rounded;
        break;
      case ToastType.info:
        bgColor = const Color(0xFF162330);
        borderColor = const Color(0xFF2196F3).withValues(alpha: 0.6);
        iconColor = const Color(0xFF42A5F5);
        iconData = Icons.info_outline_rounded;
        break;
    }

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: _dismissWithAnimation,
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! < -50) {
                  _dismissWithAnimation();
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      offset: const Offset(0, 6),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(iconData, color: iconColor, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
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
