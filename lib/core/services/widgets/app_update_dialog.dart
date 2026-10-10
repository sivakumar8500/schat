import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

enum UpdateDialogState {
  available,
  downloading,
  readyToRestart,
  error,
}

class AppUpdateDialog extends StatefulWidget {
  final ShorebirdUpdater? updater;
  final String? releaseNotes;
  final VoidCallback? onUpdateCompleted;

  const AppUpdateDialog({
    super.key,
    this.updater,
    this.releaseNotes,
    this.onUpdateCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    ShorebirdUpdater? updater,
    String? releaseNotes,
    VoidCallback? onUpdateCompleted,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AppUpdateDialog(
        updater: updater,
        releaseNotes: releaseNotes,
        onUpdateCompleted: onUpdateCompleted,
      ),
    );
  }

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog>
    with SingleTickerProviderStateMixin {
  UpdateDialogState _state = UpdateDialogState.available;
  String _errorMessage = '';
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _startUpdate() async {
    setState(() {
      _state = UpdateDialogState.downloading;
      _errorMessage = '';
    });

    try {
      final updater = widget.updater ?? ShorebirdUpdater();
      await updater.update();
      if (mounted) {
        setState(() {
          _state = UpdateDialogState.readyToRestart;
        });
        widget.onUpdateCompleted?.call();
      }
    } catch (e) {
      debugPrint('AppUpdateDialog: Update error -> $e');
      if (mounted) {
        setState(() {
          _state = UpdateDialogState.error;
          _errorMessage = e.toString().contains('network') ||
                  e.toString().contains('SocketException')
              ? 'Network error. Please check your internet connection and try again.'
              : 'Failed to download the update. Please try again.';
        });
      }
    }
  }

  void _restartApp() {
    Navigator.of(context).pop();
    if (!kIsWeb && Platform.isAndroid) {
      SystemNavigator.pop();
    } else if (!kIsWeb && Platform.isIOS) {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeaderIcon(context),
              CommonSpaces.h16,
              _buildTitle(context),
              CommonSpaces.h8,
              _buildBodyContent(context),
              CommonSpaces.h20,
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(BuildContext context) {
    Color bgGradientStart;
    Color bgGradientEnd;
    IconData icon;
    Color iconColor;

    switch (_state) {
      case UpdateDialogState.available:
        bgGradientStart = const Color(0xFF00A859);
        bgGradientEnd = const Color(0xFF00873C);
        icon = Icons.rocket_launch_rounded;
        iconColor = Colors.white;
        break;
      case UpdateDialogState.downloading:
        bgGradientStart = const Color(0xFF2196F3);
        bgGradientEnd = const Color(0xFF1976D2);
        icon = Icons.cloud_download_rounded;
        iconColor = Colors.white;
        break;
      case UpdateDialogState.readyToRestart:
        bgGradientStart = const Color(0xFF4CAF50);
        bgGradientEnd = const Color(0xFF388E3C);
        icon = Icons.check_circle_rounded;
        iconColor = Colors.white;
        break;
      case UpdateDialogState.error:
        bgGradientStart = const Color(0xFFE53935);
        bgGradientEnd = const Color(0xFFC62828);
        icon = Icons.error_outline_rounded;
        iconColor = Colors.white;
        break;
    }

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [bgGradientStart, bgGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: bgGradientStart.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: 34, color: iconColor),
    );
  }

  Widget _buildTitle(BuildContext context) {
    String title;
    switch (_state) {
      case UpdateDialogState.available:
        title = 'New Update Available';
        break;
      case UpdateDialogState.downloading:
        title = 'Downloading Update...';
        break;
      case UpdateDialogState.readyToRestart:
        title = 'Update Ready!';
        break;
      case UpdateDialogState.error:
        title = 'Update Failed';
        break;
    }

    return Text(
      title,
      textAlign: TextAlign.center,
      style: context.titleLarge.copyWith(
        fontWeight: FontWeight.bold,
        color: context.colors.textPrimary,
        fontSize: 20,
      ),
    );
  }

  Widget _buildBodyContent(BuildContext context) {
    switch (_state) {
      case UpdateDialogState.available:
        return Column(
          children: [
            Text(
              'A new release is available for SChat with improvements, new features, and bug fixes.',
              textAlign: TextAlign.center,
              style: context.bodyMedium.copyWith(
                color: context.colors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (widget.releaseNotes != null &&
                widget.releaseNotes!.isNotEmpty) ...[
              CommonSpaces.h12,
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.lightBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.releaseNotes!,
                  style: context.bodySmall.copyWith(
                    color: context.colors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        );

      case UpdateDialogState.downloading:
        return Column(
          children: [
            Text(
              'Please keep SChat open while we download and verify the new release...',
              textAlign: TextAlign.center,
              style: context.bodyMedium.copyWith(
                color: context.colors.textSecondary,
                fontSize: 13.5,
              ),
            ),
            CommonSpaces.h16,
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                backgroundColor:
                    context.colors.textHint.withValues(alpha: 0.2),
                valueColor:
                    AlwaysStoppedAnimation<Color>(context.colors.primary),
                minHeight: 6,
              ),
            ),
          ],
        );

      case UpdateDialogState.readyToRestart:
        return Text(
          'The update has been downloaded successfully. Restart SChat now to start using the new release.',
          textAlign: TextAlign.center,
          style: context.bodyMedium.copyWith(
            color: context.colors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        );

      case UpdateDialogState.error:
        return Text(
          _errorMessage.isNotEmpty
              ? _errorMessage
              : 'An unexpected error occurred during the update.',
          textAlign: TextAlign.center,
          style: context.bodyMedium.copyWith(
            color: context.colors.error,
            fontSize: 13.5,
          ),
        );
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    switch (_state) {
      case UpdateDialogState.available:
        return Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Later',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            CommonSpaces.w12,
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _startUpdate,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text(
                  'Start Update',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00873C),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );

      case UpdateDialogState.downloading:
        return const SizedBox.shrink();

      case UpdateDialogState.readyToRestart:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _restartApp,
            icon: const Icon(Icons.restart_alt_rounded, size: 20),
            label: const Text(
              'Restart App',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00873C),
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );

      case UpdateDialogState.error:
        return Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Dismiss',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            CommonSpaces.w12,
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _startUpdate,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Retry',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}
