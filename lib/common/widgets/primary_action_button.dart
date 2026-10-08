import 'package:flutter/material.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';

class PrimaryActionButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? trailingIcon;
  final double height;
  final double borderRadius;

  const PrimaryActionButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.isLoading = false,
    this.trailingIcon,
    this.height = 56,
    this.borderRadius = 28,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;
    final primaryColor = context.colors.primary;
    final isDisabled = onPressed == null || isLoading;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: isDisabled
            ? null
            : const LinearGradient(
                colors: [
                  Color(0xFF007A37),
                  Color(0xFF00873C),
                  Color(0xFF00A850),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: isDisabled
            ? (isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE5E7EB))
            : null,
        boxShadow: isDisabled
            ? null
            : [
                BoxShadow(
                  color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: isDisabled ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Center Title / Loading
                Center(
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          title,
                          style: context.titleMedium.copyWith(
                            color: isDisabled
                                ? (isDark ? Colors.white38 : Colors.black38)
                                : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),

                // Trailing White Circle Arrow on the right
                if (!isLoading && !isDisabled)
                  Align(
                    alignment: Alignment.centerRight,
                    child: trailingIcon ??
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: primaryColor,
                              size: 16,
                            ),
                          ),
                        ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
