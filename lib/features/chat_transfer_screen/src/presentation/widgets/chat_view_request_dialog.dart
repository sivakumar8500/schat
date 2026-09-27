import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/models/chat_view_request_model.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_spaces.dart';

class ChatViewRequestDialog extends StatelessWidget {
  final ChatViewRequestModel request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const ChatViewRequestDialog({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  static Future<void> show(
    BuildContext context, {
    required ChatViewRequestModel request,
    required VoidCallback onAccept,
    required VoidCallback onDecline,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChatViewRequestDialog(
        request: request,
        onAccept: onAccept,
        onDecline: onDecline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final senderName = request.sender?.name.isNotEmpty == true
        ? request.sender!.name
        : (request.sender?.username.isNotEmpty == true
            ? request.sender!.username
            : (request.sender?.phoneNumber.isNotEmpty == true ? request.sender!.phoneNumber : 'Someone'));

    final initial = senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';

    return AlertDialog(
      backgroundColor: context.colors.scaffoldBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE8F5E9),
            ),
            child: ClipOval(
              child: (request.sender?.profilePictureUrl != null && request.sender!.profilePictureUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: request.sender!.profilePictureUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: Text(
                          initial,
                          style: CommonFontStyles.titleSmall(context).copyWith(
                            color: const Color(0xFF00873C),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Text(
                          initial,
                          style: CommonFontStyles.titleSmall(context).copyWith(
                            color: const Color(0xFF00873C),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        initial,
                        style: CommonFontStyles.titleSmall(context).copyWith(
                          color: const Color(0xFF00873C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
          CommonSpaces.w12,
          Expanded(
            child: Text(
              'Chat View Request',
              style: CommonFontStyles.titleMedium(context),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$senderName wants permission to view your conversations and message history.',
            style: CommonFontStyles.bodyMedium(context),
          ),
          CommonSpaces.h12,
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: context.colors.primary, size: 20),
                CommonSpaces.w8,
                Expanded(
                  child: Text(
                    'You can revoke this permission at any time from your settings.',
                    style: CommonFontStyles.caption(context).copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onDecline();
          },
          child: Text(
            'Decline',
            style: CommonFontStyles.buttonText(context).copyWith(color: context.colors.error),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onAccept();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Accept', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
