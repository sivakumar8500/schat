import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';

extension NotificationExt on BuildContext {
  void showErrorNotification(String message) {
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

