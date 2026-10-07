import 'package:flutter/material.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/chat_screen/src/domain/models/screen_permission_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/core/notifications/in_app_notification_service.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_notifications.dart';

class RequestScreenPermissionBottomSheet extends StatefulWidget {
  final String conversationId;
  final String contactName;
  final int initialTabIndex;
  final ScreenPermissionModel? incomingRequest;
  final Function(ScreenPermissionModel)? onRequestSent;
  final Function(ScreenPermissionModel)? onResponded;

  const RequestScreenPermissionBottomSheet({
    super.key,
    required this.conversationId,
    required this.contactName,
    this.initialTabIndex = 0,
    this.incomingRequest,
    this.onRequestSent,
    this.onResponded,
  });

  @override
  State<RequestScreenPermissionBottomSheet> createState() =>
      _RequestScreenPermissionBottomSheetState();
}

class _RequestScreenPermissionBottomSheetState
    extends State<RequestScreenPermissionBottomSheet> {
  late int _activeTabIndex;
  String _selectedType = 'screenshot'; // 'screenshot' or 'screen_record'
  int _selectedScreenshotCount = 1; // 1..10
  int _selectedRecordSeconds = 30; // 10..90
  bool _isLoading = false;
  bool _isLoadingPending = true;
  String? _respondingRequestId;

  List<ScreenPermissionModel> _pendingRequests = [];

  final List<int> _screenshotCounts = List.generate(10, (i) => i + 1);
  final List<int> _recordDurations = [10, 20, 30, 40, 50, 60, 70, 80, 90];

  @override
  void initState() {
    super.initState();
    _activeTabIndex = widget.initialTabIndex;
    if (widget.incomingRequest != null) {
      _pendingRequests.add(widget.incomingRequest!);
      _isLoadingPending = false;
    }
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    try {
      final repo = getIt<ChatRepository>();
      final myId = (getIt<StorageService>().getUserId() ?? '').trim();
      final allPending = await repo.getPendingScreenPermissions();

      final filtered = allPending.where((req) {
        final matchesConv = req.conversationId == widget.conversationId;
        final isRecipient = req.receiverId == myId || (myId.isNotEmpty && req.senderId != myId);
        return req.isPending && matchesConv && isRecipient;
      }).toList();

      if (mounted) {
        setState(() {
          _pendingRequests = filtered;
          _isLoadingPending = false;
          if (_pendingRequests.isNotEmpty && widget.initialTabIndex == 1) {
            _activeTabIndex = 1;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingPending = false;
        });
      }
    }
  }

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

  Future<void> _respondToRequest(ScreenPermissionModel request, String action) async {
    setState(() {
      _respondingRequestId = request.id;
    });

    try {
      final repo = getIt<ChatRepository>();
      final updated = await repo.respondToScreenPermission(
        requestId: request.id,
        action: action,
      );

      try {
        getIt<InAppNotificationService>().markScreenPermissionHandled(request.id);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _pendingRequests.removeWhere((r) => r.id == request.id);
        });

        if (action == 'accept') {
          context.showSuccessNotification('Permission granted to ${request.senderName ?? widget.contactName}');
        } else {
          context.showInfoNotification('Permission request rejected');
        }
        widget.onResponded?.call(updated);

        if (_pendingRequests.isEmpty && _activeTabIndex == 1) {
          Navigator.pop(context, updated);
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorNotification('Failed to respond: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _respondingRequestId = null;
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
          CommonSpaces.h12,

          // Tab Switcher: Send Request vs Received Requests
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
                  child: _buildHeaderTab(
                    index: 0,
                    title: 'Send Request',
                    icon: Icons.send_rounded,
                  ),
                ),
                Expanded(
                  child: _buildHeaderTab(
                    index: 1,
                    title: 'Received',
                    icon: Icons.inbox_rounded,
                    badgeCount: _pendingRequests.length,
                  ),
                ),
              ],
            ),
          ),
          CommonSpaces.h16,

          // Tab Content
          if (_activeTabIndex == 0)
            _buildSendRequestTab(context)
          else
            _buildReceivedRequestsTab(context),
        ],
      ),
    );
  }

  Widget _buildHeaderTab({
    required int index,
    required String title,
    required IconData icon,
    int badgeCount = 0,
  }) {
    final colors = context.colors;
    final isSelected = _activeTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? colors.textLight : colors.textSecondary,
            ),
            CommonSpaces.w6,
            Text(
              title,
              style: context.bodyMedium.copyWith(
                color: isSelected ? colors.textLight : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (badgeCount > 0) ...[
              CommonSpaces.w6,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.redAccent : Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSendRequestTab(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // If there's an incoming request from contact, show an alert banner
        if (_pendingRequests.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: colors.primary, size: 20),
                CommonSpaces.w10,
                Expanded(
                  child: Text(
                    '${widget.contactName} sent you a capture request.',
                    style: context.bodySmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _activeTabIndex = 1;
                    });
                  },
                  child: Text(
                    'View',
                    style: context.bodySmall.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          CommonSpaces.h14,
        ],

        Text(
          'Request permission from ${widget.contactName} to take screenshots or record screen in this conversation.',
          style: context.bodySmall.copyWith(color: colors.textSecondary),
        ),
        CommonSpaces.h16,

        // Type Switcher (Screenshot vs Screen Record)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.scaffoldBackground,
            borderRadius: BorderRadius.circular(14),
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
        CommonSpaces.h16,

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
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.textLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_rounded, size: 18),
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
    );
  }

  Widget _buildReceivedRequestsTab(BuildContext context) {
    final colors = context.colors;

    if (_isLoadingPending) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: CircularProgressIndicator(color: colors.primary),
        ),
      );
    }

    if (_pendingRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 48,
                color: colors.primary.withValues(alpha: 0.6),
              ),
              CommonSpaces.h12,
              Text(
                'No Pending Requests',
                style: context.titleMedium.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              CommonSpaces.h4,
              Text(
                'No incoming capture permission requests from ${widget.contactName}.',
                textAlign: TextAlign.center,
                style: context.bodySmall.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _pendingRequests.map((req) {
        final isScreenshot = req.isScreenshot;
        final senderName = req.senderName ?? widget.contactName;
        final detailText = isScreenshot
            ? '${req.allowedCount ?? 1} screenshot${(req.allowedCount ?? 1) > 1 ? 's' : ''}'
            : '${req.durationSeconds ?? 30}s screen recording';
        final isResponding = _respondingRequestId == req.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.scaffoldBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isScreenshot ? Icons.camera_alt_rounded : Icons.videocam_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  CommonSpaces.w12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          senderName,
                          style: context.bodyMedium.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Requested $detailText',
                          style: context.bodySmall.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              CommonSpaces.h16,
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: isResponding ? null : () => _respondToRequest(req, 'reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Reject',
                          style: context.bodySmall.copyWith(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  CommonSpaces.w12,
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: isResponding ? null : () => _respondToRequest(req, 'accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.textLight,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isResponding
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: colors.textLight,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Accept',
                                style: context.bodySmall.copyWith(
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
      }).toList(),
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
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
