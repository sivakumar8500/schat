import 'package:flutter/material.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_sizes.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? context.colors.primary;
    final txt = textColor ?? context.colors.textLight;

    return SizedBox(
      width: double.infinity,
      height: CommonSizes.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: txt,
          disabledBackgroundColor: context.colors.lightBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CommonSizes.r16),
          ),
          elevation: onPressed != null ? 5 : 0,
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: context.colors.textLight, strokeWidth: 3),
              )
            : Text(
                text,
                style: context.titleMedium.copyWith(color: txt),
              ),
      ),
    );
  }
}
