import 'package:flutter/material.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/models/chat_view_request_model.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';

enum RequestCardType { incomingPending, outgoingPending, activeMonitored, activeViewer }

class ChatViewRequestCard extends StatelessWidget {
  final ChatViewRequestModel request;
  final RequestCardType type;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onRevoke;
  final VoidCallback? onTap;

  const ChatViewRequestCard({
    super.key,
    required this.request,
    required this.type,
    this.onAccept,
    this.onReject,
    this.onRevoke,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherUser = type == RequestCardType.incomingPending || type == RequestCardType.activeViewer
        ? request.sender
        : request.receiver;

    final displayName = otherUser?.name.isNotEmpty == true
        ? otherUser!.name
        : (otherUser?.username.isNotEmpty == true
            ? otherUser!.username
            : (otherUser?.phoneNumber.isNotEmpty == true ? otherUser!.phoneNumber : 'User'));

    final subtitle = otherUser?.phoneNumber.isNotEmpty == true
        ? otherUser!.phoneNumber
        : '@${otherUser?.username ?? ""}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.colors.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: context.colors.primary.withValues(alpha: 0.2),
                  backgroundImage: otherUser?.profilePictureUrl != null &&
                          otherUser!.profilePictureUrl!.isNotEmpty
                      ? NetworkImage(otherUser.profilePictureUrl!)
                      : null,
                  child: otherUser?.profilePictureUrl == null ||
                          otherUser!.profilePictureUrl!.isEmpty
                      ? Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                          style: CommonFontStyles.titleMedium(context).copyWith(
                            color: context.colors.primary,
                          ),
                        )
                      : null,
                ),
                CommonSpaces.w12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: CommonFontStyles.titleSmall(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      CommonSpaces.h4,
                      Text(
                        subtitle,
                        style: CommonFontStyles.bodySmall(context).copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(context),
              ],
            ),
            if (type == RequestCardType.incomingPending) ...[
              CommonSpaces.h12,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.colors.error,
                        side: BorderSide(color: context.colors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  CommonSpaces.w12,
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ] else if (type == RequestCardType.activeMonitored) ...[
              CommonSpaces.h12,
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onTap,
                      icon: Icon(CommonIcons.chatBubble, size: 16, color: Colors.white),
                      label: const Text('View Live Chats'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  CommonSpaces.w8,
                  IconButton(
                    tooltip: 'Revoke Access',
                    onPressed: onRevoke,
                    icon: Icon(CommonIcons.delete, color: context.colors.error, size: 20),
                  ),
                ],
              ),
            ] else if (type == RequestCardType.activeViewer) ...[
              CommonSpaces.h12,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Can view your messages',
                    style: CommonFontStyles.caption(context).copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onRevoke,
                    icon: Icon(CommonIcons.close, color: context.colors.error, size: 16),
                    label: Text(
                      'Revoke',
                      style: CommonFontStyles.buttonText(context).copyWith(
                        color: context.colors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (type == RequestCardType.outgoingPending) ...[
              CommonSpaces.h8,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Awaiting acceptance...',
                    style: CommonFontStyles.caption(context).copyWith(
                      color: context.colors.warning,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  TextButton(
                    onPressed: onRevoke,
                    child: Text(
                      'Cancel',
                      style: CommonFontStyles.buttonText(context).copyWith(
                        color: context.colors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (request.status) {
      case 'accepted':
        bg = context.colors.success.withValues(alpha: 0.15);
        fg = context.colors.success;
        label = 'Active';
        break;
      case 'pending':
        bg = context.colors.warning.withValues(alpha: 0.15);
        fg = context.colors.warning;
        label = 'Pending';
        break;
      case 'rejected':
        bg = context.colors.error.withValues(alpha: 0.15);
        fg = context.colors.error;
        label = 'Rejected';
        break;
      default:
        bg = context.colors.grey.withValues(alpha: 0.15);
        fg = context.colors.grey;
        label = request.status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: CommonFontStyles.caption(context).copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
