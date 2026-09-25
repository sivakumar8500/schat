import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:schat/core/services/link_metadata_service.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkPreviewCard extends StatefulWidget {
  final String url;
  final bool isMe;

  const LinkPreviewCard({
    super.key,
    required this.url,
    required this.isMe,
  });

  @override
  State<LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends State<LinkPreviewCard> {
  LinkMetadata? _metadata;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  @override
  void didUpdateWidget(covariant LinkPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loadMetadata();
    }
  }

  Future<void> _loadMetadata() async {
    final meta = await LinkMetadataService.instance.fetchMetadata(widget.url);
    if (mounted) {
      setState(() {
        _metadata = meta;
        _isLoading = false;
      });
    }
  }

  Future<void> _openLink() async {
    final normalized = LinkMetadataService.normalizeUrl(widget.url);
    final uri = Uri.tryParse(normalized);
    if (uri != null) {
      try {
        final can = await canLaunchUrl(uri);
        if (can) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            context.showErrorNotification('Could not open link');
          }
        }
      } catch (e) {
        if (mounted) {
          context.showErrorNotification('Error opening link');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Shimmer / skeleton placeholder
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isMe
              ? Colors.black.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.isMe ? Colors.white70 : context.colors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Loading preview...',
                style: context.bodySmall.copyWith(
                  color: widget.isMe ? Colors.white70 : context.colors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    final meta = _metadata;
    if (meta == null || !meta.hasContent) {
      return const SizedBox.shrink();
    }

    final hasImage = meta.imageUrl != null && meta.imageUrl!.isNotEmpty;
    final hasDescription = meta.description != null && meta.description!.isNotEmpty;
    final hasTitle = meta.title != null && meta.title!.isNotEmpty;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = widget.isMe
        ? Colors.black.withValues(alpha: 0.18)
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.12));

    final textColor = widget.isMe ? Colors.white : context.colors.textPrimary;
    final subtextColor = widget.isMe
        ? Colors.white.withValues(alpha: 0.8)
        : context.colors.textSecondary;
    final domainColor = widget.isMe
        ? Colors.white.withValues(alpha: 0.65)
        : context.colors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isMe
              ? Colors.white.withValues(alpha: 0.15)
              : context.colors.cardBackground.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openLink,
          splashColor: widget.isMe
              ? Colors.white.withValues(alpha: 0.15)
              : context.colors.primary.withValues(alpha: 0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large Top Preview Image
              if (hasImage)
                CachedNetworkImage(
                  imageUrl: meta.imageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 140,
                    width: double.infinity,
                    color: Colors.black12,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),

              // Content Details
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Domain Row
                    Row(
                      children: [
                        if (meta.faviconUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: CachedNetworkImage(
                              imageUrl: meta.faviconUrl!,
                              width: 14,
                              height: 14,
                              errorWidget: (context, url, error) => Icon(
                                Icons.language,
                                size: 14,
                                color: domainColor,
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.language,
                              size: 14,
                              color: domainColor,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            meta.domain.toUpperCase(),
                            style: context.bodySmall.copyWith(
                              color: domainColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.open_in_new,
                          size: 13,
                          color: domainColor.withValues(alpha: 0.7),
                        ),
                      ],
                    ),

                    if (hasTitle) ...[
                      const SizedBox(height: 4),
                      Text(
                        meta.title!,
                        style: context.bodyMedium.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    if (hasDescription) ...[
                      const SizedBox(height: 4),
                      Text(
                        meta.description!,
                        style: context.bodySmall.copyWith(
                          color: subtextColor,
                          fontSize: 12,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
