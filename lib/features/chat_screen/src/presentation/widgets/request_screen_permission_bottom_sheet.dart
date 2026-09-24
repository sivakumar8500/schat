import 'package:flutter/material.dart';
import 'package:schat/features/chat_screen/src/domain/models/screen_permission_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_notifications.dart';

class RequestScreenPermissionBottomSheet extends StatefulWidget {
  final String conversationId;
  final String contactName;
  final Function(ScreenPermissionModel)? onRequestSent;

  const RequestScreenPermissionBottomSheet({
    super.key,
    required this.conversationId,
    required this.contactName,
    this.onRequestSent,
  });

  @override
  State<RequestScreenPermissionBottomSheet> createState() =>
      _RequestScreenPermissionBottomSheetState();
}

class _RequestScreenPermissionBottomSheetState
    extends State<RequestScreenPermissionBottomSheet> {
  String _selectedType = 'screenshot'; // 'screenshot' or 'screen_record'
  int _selectedScreenshotCount = 1; // 1..10
  int _selectedRecordSeconds = 30; // 10..90
  bool _isLoading = false;

  final List<int> _screenshotCounts = List.generate(10, (i) => i + 1);
  final List<int> _recordDurations = [10, 20, 30, 40, 50, 60, 70, 80, 90];

  Future<void> _submitRequest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repo = getIt<ChatRepository>();
      final result = await repo.requestScreenPermission(
        conversationId: widget.conversationId,
        permissionType: _selectedType,
        allowedCount: _selectedType == 'screenshot' ? _selectedScreenshotCount : null,
        durationSeconds: _selectedType == 'screen_record' ? _selectedRecordSeconds : null,
      );

      // Also emit over websocket if connected
      try {
        final socketRepo = getIt<ChatSocketRepository>();
        if (socketRepo.isConnected) {
          socketRepo.emit('screen_permission_request', {
            'type': 'screen_permission_request',
            'conversation_id': widget.conversationId,
            'permission_type': _selectedType,
            'allowed_count': _selectedType == 'screenshot' ? _selectedScreenshotCount : null,
            'duration_seconds': _selectedType == 'screen_record' ? _selectedRecordSeconds : null,
          });
        }
      } catch (e) {
        debugPrint('Socket emit error for screen permission request: $e');
      }

      if (mounted) {
        context.showSuccessNotification(
          'Request sent to ${widget.contactName}',
        );
        widget.onRequestSent?.call(result);
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorNotification('Failed to send request: $e');
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

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          CommonSpaces.h16,

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.security_rounded, color: colors.primary, size: 22),
                  ),
                  CommonSpaces.w12,
                  Text(
                    'Capture Permission',
                    style: context.titleLarge.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(CommonIcons.close, color: colors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Text(
            'Request permission from ${widget.contactName} to take screenshots or record screen in this conversation.',
            style: context.bodySmall.copyWith(color: colors.textSecondary),
          ),
          CommonSpaces.h20,

          // Type Segment Switcher (Screenshot vs Screen Record)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.scaffoldBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTypeSegment(
                    type: 'screenshot',
                    title: 'Screenshot',
                    icon: Icons.camera_alt_rounded,
                  ),
                ),
                Expanded(
                  child: _buildTypeSegment(
                    type: 'screen_record',
                    title: 'Screen Record',
                    icon: Icons.videocam_rounded,
                  ),
                ),
              ],
            ),
          ),
          CommonSpaces.h20,

          // Count / Duration Options
          if (_selectedType == 'screenshot') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Allowed Screenshots',
                  style: context.titleSmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_selectedScreenshotCount screenshot${_selectedScreenshotCount > 1 ? 's' : ''}',
                    style: context.bodySmall.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            CommonSpaces.h12,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _screenshotCounts.map((count) {
                final isSelected = count == _selectedScreenshotCount;
                return ChoiceChip(
                  label: Text('$count'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedScreenshotCount = count;
                      });
                    }
                  },
                  selectedColor: colors.primary,
                  backgroundColor: colors.scaffoldBackground,
                  labelStyle: TextStyle(
                    color: isSelected ? colors.textLight : colors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? colors.primary : colors.border,
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recording Duration',
                  style: context.titleSmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_selectedRecordSeconds seconds',
                    style: context.bodySmall.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            CommonSpaces.h12,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recordDurations.map((seconds) {
                final isSelected = seconds == _selectedRecordSeconds;
                return ChoiceChip(
                  label: Text('${seconds}s'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedRecordSeconds = seconds;
                      });
                    }
                  },
                  selectedColor: colors.primary,
                  backgroundColor: colors.scaffoldBackground,
                  labelStyle: TextStyle(
                    color: isSelected ? colors.textLight : colors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? colors.primary : colors.border,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          CommonSpaces.h24,

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.textLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: colors.textLight,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 20),
                        CommonSpaces.w8,
                        Text(
                          'Send Request',
                          style: context.titleMedium.copyWith(
                            color: colors.textLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSegment({
    required String type,
    required String title,
    required IconData icon,
  }) {
    final colors = context.colors;
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? colors.textLight : colors.textSecondary,
            ),
            CommonSpaces.w8,
            Text(
              title,
              style: context.bodyMedium.copyWith(
                color: isSelected ? colors.textLight : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
