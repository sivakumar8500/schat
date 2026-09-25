import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:schat/features/chat_screen/src/domain/models/media_permissions_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_spaces.dart';

class MediaProtectionBottomSheet extends StatefulWidget {
  final String mediaId;
  final String? fileName;
  final MediaPermissionsModel? initialData;

  const MediaProtectionBottomSheet({
    super.key,
    required this.mediaId,
    this.fileName,
    this.initialData,
  });

  static Future<void> show(
    BuildContext context, {
    required String mediaId,
    String? fileName,
    MediaPermissionsModel? initialData,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MediaProtectionBottomSheet(
        mediaId: mediaId,
        fileName: fileName,
        initialData: initialData,
      ),
    );
  }

  @override
  State<MediaProtectionBottomSheet> createState() => _MediaProtectionBottomSheetState();
}

class _MediaProtectionBottomSheetState extends State<MediaProtectionBottomSheet> {
  MediaPermissionsModel? _permissions;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _permissions = widget.initialData;
      _isLoading = false;
    } else {
      _fetchPermissions();
    }
  }

  Future<void> _fetchPermissions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = getIt<ChatRepository>();
      final result = await repo.getMediaPermissions(widget.mediaId);
      if (mounted) {
        setState(() {
          _permissions = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;
    final bgColor = isDark ? const Color(0xFF141916) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1C2420) : const Color(0xFFF6F8F7);
    final borderColor = isDark ? const Color(0xFF2A3630) : const Color(0xFFE5E9E7);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          CommonSpaces.h16,

          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00FF87), Color(0xFF60EFFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF87).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Color(0xFF0B2117),
                  size: 28,
                ),
              ),
              CommonSpaces.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Media Security & Protection',
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.fileName ?? 'Encrypted Attachment Protection',
                      style: context.bodySmall.copyWith(
                        color: context.colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: context.colors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          CommonSpaces.h20,

          // Body Content
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: context.colors.primary,
                      strokeWidth: 3,
                    ),
                    CommonSpaces.h16,
                    Text(
                      'Verifying media permissions...',
                      style: context.bodyMedium.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 36),
                  CommonSpaces.h8,
                  Text(
                    'Unable to fetch permissions',
                    style: context.titleSmall.copyWith(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CommonSpaces.h4,
                  Text(
                    _errorMessage!,
                    style: context.bodySmall.copyWith(color: context.colors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  CommonSpaces.h12,
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try Again'),
                    onPressed: _fetchPermissions,
                  ),
                ],
              ),
            )
          else
            _buildPermissionsContent(
              context,
              _permissions!,
              cardBg: cardBg,
              borderColor: borderColor,
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionsContent(
    BuildContext context,
    MediaPermissionsModel model, {
    required Color cardBg,
    required Color borderColor,
  }) {
    final permissions = model.permissions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ownership & Identity Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: model.isOwner
                      ? const Color(0xFF00FF87).withValues(alpha: 0.15)
                      : Colors.blueAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: model.isOwner
                        ? const Color(0xFF00FF87).withValues(alpha: 0.5)
                        : Colors.blueAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      model.isOwner ? Icons.verified_user_rounded : Icons.person_outline_rounded,
                      size: 14,
                      color: model.isOwner ? const Color(0xFF00FF87) : Colors.blueAccent,
                    ),
                    CommonSpaces.w4,
                    Text(
                      model.isOwner ? 'Owner' : 'Recipient',
                      style: context.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: model.isOwner ? const Color(0xFF00FF87) : Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ),
              CommonSpaces.w10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Media ID',
                      style: context.bodySmall.copyWith(
                        fontSize: 11,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    Text(
                      widget.mediaId,
                      style: context.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: 'Copy Media ID',
                color: context.colors.textSecondary,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.mediaId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Media ID copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        CommonSpaces.h14,

        // Permission Square Grid (View, Download, Share)
        Row(
          children: [
            Expanded(
              child: _buildSquarePermissionCard(
                context,
                title: 'View',
                allowed: permissions.canView,
                icon: Icons.visibility_rounded,
                cardBg: cardBg,
                borderColor: borderColor,
              ),
            ),
            CommonSpaces.w10,
            Expanded(
              child: _buildSquarePermissionCard(
                context,
                title: 'Download',
                allowed: permissions.canDownload,
                icon: Icons.download_rounded,
                cardBg: cardBg,
                borderColor: borderColor,
              ),
            ),
            CommonSpaces.w10,
            Expanded(
              child: _buildSquarePermissionCard(
                context,
                title: 'Share',
                allowed: permissions.canShare,
                icon: Icons.share_rounded,
                cardBg: cardBg,
                borderColor: borderColor,
              ),
            ),
          ],
        ),
        CommonSpaces.h14,

        // Security & Protection Policy Section
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACTIVE PROTECTION POLICIES',
                style: context.bodySmall.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: context.colors.textSecondary,
                ),
              ),
              CommonSpaces.h10,
              _buildProtectionRow(
                context,
                icon: Icons.lock_outline_rounded,
                title: 'End-to-End Encryption',
                subtitle: 'AES-256-GCM encrypted in-transit & at-rest',
                status: 'Enforced',
                statusColor: const Color(0xFF00FF87),
              ),
              const Divider(height: 16, thickness: 0.6),
              _buildProtectionRow(
                context,
                icon: Icons.screenshot_monitor_rounded,
                title: 'Anti-Screenshot & Capture',
                subtitle: 'Protected against unauthorized recording & export',
                status: permissions.canDownload ? 'Allowed' : 'Secured',
                statusColor: permissions.canDownload ? Colors.orangeAccent : const Color(0xFF00FF87),
              ),
              const Divider(height: 16, thickness: 0.6),
              _buildProtectionRow(
                context,
                icon: Icons.security_rounded,
                title: 'DRM Revocation & Access Control',
                subtitle: 'Token authenticated via backend security gateway',
                status: 'Active',
                statusColor: const Color(0xFF00FF87),
              ),
            ],
          ),
        ),
        CommonSpaces.h16,

        // Done Button
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Done',
              style: context.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSquarePermissionCard(
    BuildContext context, {
    required String title,
    required bool allowed,
    required IconData icon,
    required Color cardBg,
    required Color borderColor,
  }) {
    final isDark = context.colors.isDark;
    final activeColor = allowed ? const Color(0xFF00FF87) : Colors.redAccent;
    final badgeBg = activeColor.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allowed
              ? (isDark ? const Color(0xFF00FF87).withValues(alpha: 0.3) : const Color(0xFF00873C).withValues(alpha: 0.3))
              : borderColor,
          width: allowed ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: activeColor,
            ),
          ),
          CommonSpaces.h8,
          Text(
            title,
            style: context.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
            ),
          ),
          CommonSpaces.h4,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              allowed ? 'ALLOWED' : 'BLOCKED',
              style: context.bodySmall.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
                color: activeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtectionRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.colors.textSecondary),
        CommonSpaces.w10,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: context.bodySmall.copyWith(
                  fontSize: 11,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 0.8),
          ),
          child: Text(
            status,
            style: context.bodySmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}
