import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_sizes.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:flutter/material.dart';
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
      backgroundColor: context.colors.scaffoldBackground,
      body: Column(
        children: [
          // Top illustration area
          Expanded(
            flex: 5,
            child: Container(
              color: context.colors.scaffoldBackground,
              child: SafeArea(
                bottom: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Image.asset(
                      'assets/images/secure_chats.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Bottom card area
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.colors.cardBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(40),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secure chats',
                      style: context.h1,
                    ),
                    CommonSpaces.h4,
                    Text(
                      'Best in Privacy',
                      style: context.h1Italic,
                    ),
                    CommonSpaces.h24,
                    Text(
                      'Messages that disappear. Calls that can\'t be tapped. Files only you control.',
                      style: context.bodyMedium.copyWith(fontSize: 16),
                    ),
                    CommonSpaces.h40,
                    
                    // Get started Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _onDone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get started',
                              style: context.titleMedium.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: CommonSizes.p8),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CommonIcons.arrowForward,
                                color: context.colors.primary,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    CommonSpaces.h20,
                    
                    // Already have an account? Sign in
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: context.bodyMedium.copyWith(
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
