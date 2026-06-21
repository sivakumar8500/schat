import 'package:flutter/material.dart';
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
    return Scaffold(
      backgroundColor: context.colors.pureBlack,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top illustration area with globe and hexagon icon
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/main_bg_img.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Gradient overlay to blend image into black background
                  Positioned(
                    bottom: -1,
                    left: 0,
                    right: 0,
                    height: 200,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            context.colors.pureBlack.withValues(alpha: 0),
                            context.colors.pureBlack.withValues(alpha: 0.8),
                            context.colors.pureBlack,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Area - Unified with Background
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: CommonSizes.p32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Secure chats',
                    style: context.h1.copyWith(
                      color: context.colors.pureWhite,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  CommonSpaces.h4,
                  Text(
                    'Best in Privacy',
                    style: context.h1Italic.copyWith(
                      color: context.colors.pureWhite,
                    ),
                  ),
                  CommonSpaces.h24,
                  Text(
                    'Messages that disappear. Calls that can\'t be tapped. Files only you control.',
                    style: context.bodyMedium.copyWith(
                      color: context.colors.pureWhite.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                  CommonSpaces.h40,

                  // Get started Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _onDone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: context.colors.pureWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(CommonSizes.r24),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        children: [
                          const Spacer(flex: 3),
                          Text(
                            'Get started',
                            style: context.titleMedium.copyWith(
                              color: context.colors.pureWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(flex: 2),
                          Container(
                            padding: const EdgeInsets.all(CommonSizes.p8),
                            decoration: BoxDecoration(
                              color: context.colors.pureWhite,
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
                          color: context.colors.pureWhite.withValues(
                            alpha: 0.5,
                          ),
                          fontSize: 15,
                        ),
                      ),
                      GestureDetector(
                        onTap: _onDone,
                        child: Text(
                          'Sign in',
                          style: context.bodyMedium.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  CommonSpaces.h40,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
