import 'package:flutter/material.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';

class AuthHeroHeader extends StatelessWidget {
  final Widget? centerWidget;
  final String? title;
  final String? subtitlePrefix;
  final String? subtitleHighlight;
  final bool showTagline;

  const AuthHeroHeader({
    super.key,
    this.centerWidget,
    this.title,
    this.subtitlePrefix = 'Secure today - ',
    this.subtitleHighlight = 'Safe Tomorrow',
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;
    final primaryGreen = context.colors.primary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Concentric decorative circle with glowing dots and logo in center
          SizedBox(
            width: 176,
            height: 176,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer light green ring
                Container(
                  width: 174,
                  height: 174,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryGreen.withValues(alpha: isDark ? 0.25 : 0.15),
                      width: 1.2,
                    ),
                  ),
                ),

                // Middle soft glow ring
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryGreen.withValues(alpha: isDark ? 0.35 : 0.22),
                      width: 1.2,
                    ),
                    gradient: RadialGradient(
                      colors: [
                        primaryGreen.withValues(alpha: isDark ? 0.18 : 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),

                // Decorative floating dots
                // Left dot
                Positioned(
                  left: 20,
                  top: 92,
                  child: Container(
                    width: 6.5,
                    height: 6.5,
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),

                // Top-right dot
                Positioned(
                  right: 42,
                  top: 24,
                  child: Container(
                    width: 5.5,
                    height: 5.5,
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),

                // Right dot
                Positioned(
                  right: 18,
                  bottom: 56,
                  child: Container(
                    width: 7.5,
                    height: 7.5,
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),

                // Center Icon / App Logo
                centerWidget ??
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2620) : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: primaryGreen.withValues(alpha: isDark ? 0.3 : 0.2),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          CommonIcons.logo,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
              ],
            ),
          ),

          CommonSpaces.h14,

          // S-CHAT Title with green dash
          if (title == null)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'S',
                    style: context.h1.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: '-',
                    style: context.h1.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: primaryGreen,
                    ),
                  ),
                  TextSpan(
                    text: 'CHAT',
                    style: context.h1.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              title!,
              style: context.h1.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: context.colors.textPrimary,
              ),
            ),

          if (showTagline) ...[
            CommonSpaces.h4,
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 15,
                  color: context.colors.textSecondary,
                ),
                CommonSpaces.w6,
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: subtitlePrefix ?? '',
                        style: context.bodyMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textSecondary,
                        ),
                      ),
                      TextSpan(
                        text: subtitleHighlight ?? '',
                        style: context.bodyMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
