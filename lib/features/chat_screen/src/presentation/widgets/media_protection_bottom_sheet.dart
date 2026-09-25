import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:schat/features/chat_screen/src/domain/models/media_permissions_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/media_access_tree_model.dart';
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
  Future<MediaAccessTreeModel?>? _accessTreeFuture;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _accessTreeFuture = getIt<ChatRepository>()
        .getMediaAccessTree(widget.mediaId)
        .then<MediaAccessTreeModel?>((v) => v)
        .catchError((_) => null);

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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                  color: Colors.black,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share & Protection Details',
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                        fontSize: 17,
                      ),
                    ),
                    if (widget.fileName != null)
                      Text(
                        widget.fileName!,
                        style: context.bodySmall.copyWith(
                          color: context.colors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        'Media Access & Lineage',
                        style: context.bodySmall.copyWith(
                          color: context.colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: context.colors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          CommonSpaces.h16,

          // Content
          Flexible(
            child: SingleChildScrollView(
              child: _buildBody(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00FF87),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            CommonSpaces.h12,
            Text(
              'Could not load permissions',
              style: context.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            CommonSpaces.h6,
            Text(
              _errorMessage!,
              style: context.bodySmall.copyWith(color: context.colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            CommonSpaces.h16,
            ElevatedButton.icon(
              onPressed: _fetchPermissions,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    final model = _permissions;
    if (model == null) return const SizedBox.shrink();

    final isDark = context.colors.isDark;
    final cardBg = isDark ? const Color(0xFF1C2420) : const Color(0xFFF6F8F7);
    final borderColor = isDark ? const Color(0xFF2A3630) : const Color(0xFFE5E9E7);
    final permissions = model.permissions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ownership & Media ID Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: model.isOwner
                      ? const Color(0xFF00FF87).withValues(alpha: 0.15)
                      : Colors.blueAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: model.isOwner
                        ? const Color(0xFF00FF87).withValues(alpha: 0.4)
                        : Colors.blueAccent.withValues(alpha: 0.4),
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

        // Full Shared List / Access Lineage Section
        _buildSharedLineageSection(context, cardBg, borderColor, isDark),
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

  Widget _buildSharedLineageSection(
    BuildContext context,
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    const accentGreen = Color(0xFF00FF87);

    return FutureBuilder<MediaAccessTreeModel?>(
      future: _accessTreeFuture,
      builder: (context, snapshot) {
        final isWaiting = snapshot.connectionState == ConnectionState.waiting;
        final accessTreeModel = snapshot.data;
        final grants = accessTreeModel?.accessTree ?? [];
        final totalGrants = accessTreeModel?.totalGrants ?? grants.length;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SHARE & ACCESS LINEAGE',
                    style: context.bodySmall.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  if (!isWaiting)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$totalGrants ${totalGrants == 1 ? 'Share' : 'Shares'}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: accentGreen,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (isWaiting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accentGreen,
                      ),
                    ),
                  ),
                )
              else if (grants.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Icon(Icons.share_outlined, size: 20, color: context.colors.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No one has forwarded or reshared this file yet.',
                          style: context.bodySmall.copyWith(
                            color: context.colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: grants
                      .map((node) => _buildAccessTreeNodeItem(
                            context: context,
                            node: node,
                            isDark: isDark,
                            accentGreen: accentGreen,
                            level: 0,
                          ))
                      .toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccessTreeNodeItem({
    required BuildContext context,
    required AccessTreeNode node,
    required bool isDark,
    required Color accentGreen,
    required int level,
  }) {
    final isActive = node.status.toLowerCase() == 'active';
    final perms = node.effectivePermissions;
    final itemBg = isDark ? const Color(0xFF1E2830) : const Color(0xFFF0F3F2);

    return Padding(
      padding: EdgeInsets.only(left: level * 16.0, bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: itemBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (level > 0)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Text('↳', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  ),
                CircleAvatar(
                  radius: 13,
                  backgroundColor: accentGreen.withValues(alpha: 0.2),
                  child: Text(
                    node.grantee.initials,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.grantee.displayName,
                        style: context.bodySmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (node.granter.displayName.isNotEmpty)
                        Text(
                          'Shared by ${node.granter.displayName}',
                          style: context.bodySmall.copyWith(
                            fontSize: 10,
                            color: context.colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isActive ? accentGreen : Colors.redAccent).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    node.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isActive ? accentGreen : Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Permission Badges
            Row(
              children: [
                _buildPermissionChip('View', perms.canView, isDark),
                const SizedBox(width: 4),
                _buildPermissionChip('Download', perms.canDownload, isDark),
                const SizedBox(width: 4),
                _buildPermissionChip('Share', perms.canShare, isDark),
              ],
            ),
            if (node.downstreamShares.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...node.downstreamShares.map(
                (child) => _buildAccessTreeNodeItem(
                  context: context,
                  node: child,
                  isDark: isDark,
                  accentGreen: accentGreen,
                  level: level + 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionChip(String label, bool allowed, bool isDark) {
    const accentGreen = Color(0xFF00FF87);
    final color = allowed ? accentGreen : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            allowed ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
