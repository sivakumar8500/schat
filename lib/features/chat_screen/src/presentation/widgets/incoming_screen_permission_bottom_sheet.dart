import 'package:flutter/material.dart';
import 'package:schat/features/chat_screen/src/domain/models/screen_permission_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_notifications.dart';

class IncomingScreenPermissionBottomSheet extends StatefulWidget {
  final ScreenPermissionModel request;
  final Function(ScreenPermissionModel)? onResponded;

  const IncomingScreenPermissionBottomSheet({
    super.key,
    required this.request,
    this.onResponded,
  });

  @override
  State<IncomingScreenPermissionBottomSheet> createState() =>
      _IncomingScreenPermissionBottomSheetState();
}

class _IncomingScreenPermissionBottomSheetState
    extends State<IncomingScreenPermissionBottomSheet> {
  bool _isLoading = false;

  Future<void> _respond(String action) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repo = getIt<ChatRepository>();
      final updated = await repo.respondToScreenPermission(
        requestId: widget.request.id,
        action: action,
      );

      // Also emit over socket if connected
      try {
        final socketRepo = getIt<ChatSocketRepository>();
        if (socketRepo.isConnected) {
          socketRepo.emit('screen_permission_respond', {
            'type': 'screen_permission_respond',
            'request_id': widget.request.id,
            'action': action,
          });
        }
      } catch (e) {
        debugPrint('Socket emit error for screen permission respond: $e');
      }

      if (mounted) {
        if (action == 'accept') {
          context.showSuccessNotification('Permission granted');
        } else {
          context.showInfoNotification('Permission rejected');
        }
        widget.onResponded?.call(updated);
        Navigator.pop(context, updated);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorNotification('Failed to respond: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final req = widget.request;
    final senderName = req.senderName ?? 'Contact';
    final isScreenshot = req.isScreenshot;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textHint.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          CommonSpaces.h20,

          // Icon badge
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isScreenshot ? Icons.camera_alt_rounded : Icons.videocam_rounded,
              color: colors.primary,
              size: 32,
            ),
          ),
          CommonSpaces.h16,

          // Title
          Text(
            isScreenshot ? 'Screenshot Permission' : 'Screen Record Permission',
            style: context.titleLarge.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          CommonSpaces.h8,

          // Description
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: context.bodyMedium.copyWith(color: colors.textSecondary),
              children: [
                TextSpan(
                  text: senderName,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: isScreenshot
                      ? ' is requesting permission to take '
                      : ' is requesting permission to record the screen for ',
                ),
                TextSpan(
                  text: isScreenshot
                      ? '${req.allowedCount ?? 1} screenshot${(req.allowedCount ?? 1) > 1 ? 's' : ''}'
                      : '${req.durationSeconds ?? 30} seconds',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' in this chat.'),
              ],
            ),
          ),
          CommonSpaces.h24,

          // Action buttons
          Row(
            children: [
              // Reject Button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => _respond('reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Reject',
                      style: context.bodyMedium.copyWith(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              CommonSpaces.w16,

              // Accept Button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _respond('accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.textLight,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: colors.textLight,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Accept',
                            style: context.bodyMedium.copyWith(
                              color: colors.textLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
