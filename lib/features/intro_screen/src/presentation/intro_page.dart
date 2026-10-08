import 'package:flutter/material.dart';
import 'package:schat/common/widgets/animated_tagline.dart';
import 'package:schat/common/widgets/mesh_background.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_sizes.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:schat/features/auth_screen/auth_screen.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  Future<void> _onDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenIntro', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MobileEntryPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;

    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      body: MeshBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              children: [
                const Spacer(flex: 3),
                // Center Brand Hero
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.primary
                            .withValues(alpha: isDark ? 0.35 : 0.25),
                        blurRadius: 36,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset(
                      CommonIcons.logo,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                CommonSpaces.h24,
                Text(
                  'S-CHAT',
                  style: context.h1.copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: context.colors.textPrimary,
                  ),
                ),
                CommonSpaces.h10,
                const AnimatedTagline(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  showShieldIcon: true,
                ),

                const Spacer(flex: 4),

                // Headlines
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure chats',
                        style: context.h1.copyWith(
                          color: context.colors.textPrimary,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      CommonSpaces.h4,
                      Text(
                        'Best in Privacy',
                        style: context.h1Italic.copyWith(
                          color: context.colors.primary,
                          fontSize: 32,
                        ),
                      ),
                      CommonSpaces.h12,
                      Text(
                        'Messages that disappear. Calls that can\'t be tapped. Files only you control.',
                        style: context.bodyMedium.copyWith(
                          color: context.colors.textSecondary,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                CommonSpaces.h32,

                // Get started Button
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.primary
                            .withValues(alpha: isDark ? 0.35 : 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      children: [
                        const Spacer(flex: 3),
                        Text(
                          'Get started',
                          style: context.titleMedium.copyWith(
                            color: isDark ? Colors.black : Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(flex: 2),
                        Container(
                          padding: const EdgeInsets.all(CommonSizes.p8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CommonIcons.arrowForward,
                            color: context.colors.primary,
                            size: CommonSizes.iconSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                CommonSpaces.h20,

                // Sign in Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: context.bodyMedium.copyWith(
                        color: context.colors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: _onDone,
                      child: Text(
                        'Sign in',
                        style: context.bodyMedium.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                CommonSpaces.h24,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

