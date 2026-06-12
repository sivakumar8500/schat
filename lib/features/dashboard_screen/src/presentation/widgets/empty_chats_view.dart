import 'package:flutter/material.dart';
import 'package:schat/common/widgets/primary_button.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_spaces.dart';

class EmptyChatsView extends StatelessWidget {
  final VoidCallback onChatNowPressed;

  const EmptyChatsView({
    super.key,
    required this.onChatNowPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/secure_chats.png',
            height: 250,
            fit: BoxFit.contain,
          ),
          CommonSpaces.h32,
          Text(
            'Start your message',
            style: context.h2.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            textAlign: TextAlign.center,
          ),
          CommonSpaces.h12,
          Text(
            'Start conversation with other employee in your organization.',
            style: context.bodyMedium.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          CommonSpaces.h40,
          PrimaryButton(
            text: 'Chat Now',
            onPressed: onChatNowPressed,
          ),
        ],
      ),
    );
  }
}
