import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
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
}

