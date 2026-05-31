import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:schat/features/intro_screen/intro_screen.dart';
import 'package:schat/features/dashboard_screen/dashboard_screen.dart';
import 'package:schat/features/auth_screen/auth_screen.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check shared preferences
    final prefs = await SharedPreferences.getInstance();
    final hasSeenIntro = prefs.getBool('hasSeenIntro') ?? false;
    final isAuthenticated = prefs.getBool('isAuthenticated') ?? false;

    if (!mounted) return;

    if (!hasSeenIntro) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const IntroPage()),
      );
    } else if (!isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MobileEntryPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CommonIcons.chatBubble,
              size: 100,
              color: context.colors.scaffoldBackground,
            ),
            CommonSpaces.h20,
            Text(
              'Schat',
              style: context.h1.copyWith(
                fontSize: 40,
                color: context.colors.scaffoldBackground,
              ),
            ),
            CommonSpaces.h50,
            CircularProgressIndicator(
              color: context.colors.scaffoldBackground,
            ),
          ],
        ),
      ),
    );
  }
}
