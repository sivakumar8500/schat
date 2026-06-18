import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/profile_screen/profile_screen.dart';
import 'package:schat/features/subscription_screen/subscription_screen.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:schat/features/intro_screen/intro_screen.dart';
import 'package:schat/features/auth_screen/auth_screen.dart';
import 'package:schat/features/dashboard_screen/dashboard_screen.dart';

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
    // Wait for 2 seconds for branding
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final storage = getIt<StorageService>();
    final hasToken = storage.hasToken();

    if (hasToken) {
      final username = storage.getUsername();

      if (username != null && username.isNotEmpty) {
        // If we have a token and a cached username, go straight to Dashboard
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
        return;
      }
    }

    // If no token or no cached username, we need to check profile status properly
    if (!hasToken) {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenIntro = prefs.getBool('hasSeenIntro') ?? false;

      if (!mounted) return;

      if (!hasSeenIntro) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const IntroPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MobileEntryPage()),
        );
      }
      return;
    }

    // Has token but no cached username, check profile status from server
    try {
      final profileRepo = getIt<ProfileRepository>();
      final result = await profileRepo.getProfile();

      if (!mounted) return;

      result.when(
        success: (user) {
          _saveUsernameToPrefs(user.username);
          
          if (user.username == null || user.username!.isEmpty) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          } else if (!user.isSubscribed) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SubscriptionPage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardPage()),
            );
          }
        },
        failure: (message, statusCode) async {
          if (statusCode == 401 || message.contains('401') || message.toLowerCase().contains('unauthorized')) {
             await storage.clearTokens();
             if (!mounted) return;
             Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MobileEntryPage()),
            );
          } else {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardPage()),
            );
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    }
  }

  Future<void> _saveUsernameToPrefs(String? username) async {
    if (username != null && username.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
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
