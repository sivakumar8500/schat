import 'package:flutter/material.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_sizes.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: CommonSizes.p40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/no_data/no_chat.png',
            height: 280,
            fit: BoxFit.contain,
          ),
          CommonSpaces.h40,
          Text(
            'Start your message',
            style: context.h2.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 32,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          CommonSpaces.h16,
          Text(
            'Start conversation with other employee in your organization.',
            style: context.bodyLarge.copyWith(
              color: context.colors.textPrimary.withValues(alpha: 0.8),
              fontSize: 18,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          CommonSpaces.h48,
          SizedBox(
            width: double.infinity,
            height: 46,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(CommonSizes.p32),
                boxShadow: [
                  BoxShadow(
                    color: context.colors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onChatNowPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.pureWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(CommonSizes.p32),
                  ),
                ),
                child: Text(
                  'Chat Now',
                  style: context.titleMedium.copyWith(
                    color: context.colors.pureWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

