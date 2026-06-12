import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';

extension NotificationExt on BuildContext {
  void showErrorNotification(String message) {
    Flushbar(
      message: message,
      messageText: Text(
        message,
        style: bodyMedium.copyWith(color: Colors.white),
      ),
      backgroundColor: colors.error,
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(12),
      icon: const Icon(Icons.error_outline, color: Colors.white),
      shouldIconPulse: false,
    ).show(this);
  }

  void showSuccessNotification(String message) {
    Flushbar(
      message: message,
      messageText: Text(
        message,
        style: bodyMedium.copyWith(color: Colors.white),
      ),
      backgroundColor: colors.success,
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(12),
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      shouldIconPulse: false,
    ).show(this);
  }

  void showInfoNotification(String message) {
    Flushbar(
      message: message,
      messageText: Text(
        message,
        style: bodyMedium.copyWith(color: Colors.white),
      ),
      backgroundColor: colors.primary,
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(12),
      icon: const Icon(Icons.info_outline, color: Colors.white),
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
            style: bodyMedium.copyWith(color: Colors.white),
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ],
      ),
      backgroundColor: colors.primary,
      duration: progress == null ? const Duration(seconds: 3) : null,
      flushbarPosition: FlushbarPosition.TOP,
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(12),
      icon: const Icon(Icons.downloading, color: Colors.white),
    ).show(this);
  }
}
