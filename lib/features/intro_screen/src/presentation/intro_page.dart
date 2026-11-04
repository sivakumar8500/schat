import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:schat/features/auth_screen/auth_screen.dart';
import 'package:schat/common/widgets/animated_tagline.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  static const Color _primaryGreen = Color(0xFF00A344);
  static const Color _neonGreen = Color(0xFF00E676);
  static const Color _cardBg = Color(0xFF0A1312);
  static const Color _cardBorder = Color(0xFF143026);
  static const Color _subtextColor = Color(0xFF8CA59B);
  static const Color _bottomSheetBg = Color(0xFF141718);

  final List<_SecurityFeature> _features = const [
    _SecurityFeature(
      title: 'End-to-End\nEncryption',
      description: 'Only You Can\nAccess.',
      iconAsset: 'assets/firstscreen/icon_encryption.jpg',
      fallbackIcon: Icons.security_rounded,
    ),
    _SecurityFeature(
      title: 'Private Calls\n& Messages',
      description: 'Your Conversations.\nYour Privacy.',
      iconAsset: 'assets/firstscreen/icon_private_calls.jpg',
      fallbackIcon: Icons.phone_locked_rounded,
    ),
    _SecurityFeature(
      title: 'Disappearing\nMessages',
      description: 'Messages That\nDisappear.',
      iconAsset: 'assets/firstscreen/icon_disappearing.jpg',
      fallbackIcon: Icons.timer_outlined,
    ),
    _SecurityFeature(
      title: 'Lock\nChats',
      description: 'Lock Your Chats.\nStay Safe.',
      iconAsset: 'assets/firstscreen/icon_twostep.jpg',
      fallbackIcon: Icons.lock_rounded,
    ),
    _SecurityFeature(
      title: 'Status\nPrivacy',
      description: 'Your Status.\nYour Choice.',
      iconAsset: 'assets/firstscreen/icon_stealth_mode.jpg',
      fallbackIcon: Icons.visibility_off_rounded,
    ),
    _SecurityFeature(
      title: 'File Sharing\nProtection',
      description: 'Share Securely.\nStay Protected.',
      iconAsset: 'assets/firstscreen/icon_secure_file.jpg',
      fallbackIcon: Icons.folder_shared_rounded,
    ),
    _SecurityFeature(
      title: 'Screen\nSharing',
      description: 'Share Your Screen.\nConnect Instantly.',
      iconAsset: 'assets/firstscreen/icon_multidevice.jpg',
      fallbackIcon: Icons.screen_share_rounded,
    ),
    _SecurityFeature(
      title: 'Screen\nRecording',
      description: 'Capture What\nMatters.',
      iconAsset: 'assets/firstscreen/icon_intrusion.jpg',
      fallbackIcon: Icons.fiber_manual_record_rounded,
    ),
    _SecurityFeature(
      title: 'Secure App\nScreen',
      description: 'Security on\nEvery Screen.',
      iconAsset: 'assets/firstscreen/icon_screenshot.jpg',
      fallbackIcon: Icons.phonelink_lock_rounded,
    ),
    _SecurityFeature(
      title: 'Scheduled\nMessages',
      description: 'Send at the\nPerfect Time.',
      iconAsset: 'assets/intro_designs/Icons/future_messages.png',
      fallbackIcon: Icons.schedule_send_rounded,
    ),
  ];

  Future<void> _navigateToAuth() async {
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
      backgroundColor: Colors.black,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // Top Indicator Dots
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 5.5,
                    height: 5.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155).withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    width: 5.5,
                    height: 5.5,
                    decoration: const BoxDecoration(
                      color: _neonGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _neonGreen,
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Top Hero Graphic Section (Flexible, takes available space)
            Expanded(
              flex: 10,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.topCenter,
                children: [
                  Image.asset(
                    'assets/firstscreen/intro_hero_cyber.png',
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) =>
                        Image.asset(
                      'assets/firstscreen/intro_hero_cyber.jpg',
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  // Smooth gradient blend at the bottom of the image
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 35,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.95),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // S-CHAT Title & Animated Tagline
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'S-CHAT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 3),
                  AnimatedTagline(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    showShieldIcon: true,
                    baseColor: Colors.white70,
                    highlightColor: _neonGreen,
                  ),
                ],
              ),
            ),

            // Core Security Features Container Card (Enriched Height & Spacing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 14.0,
                ),
                decoration: BoxDecoration(
                  color: _cardBg.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _cardBorder,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryGreen.withValues(alpha: 0.12),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header: CORE SECURITY FEATURES
                    const Text(
                      'CORE SECURITY FEATURES',
                      style: TextStyle(
                        color: _neonGreen,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 11),

                    // First Row of 5 Features
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < 5; i++)
                          Expanded(
                            child: _buildFeatureItem(_features[i]),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Second Row of 5 Features
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 5; i < 10; i++)
                          Expanded(
                            child: _buildFeatureItem(_features[i]),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Bottom Rounded Action Sheet
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
              decoration: BoxDecoration(
                color: _bottomSheetBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.7),
                    blurRadius: 16,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // "Get started ->" CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _navigateToAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: _primaryGreen.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Get started',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: _primaryGreen,
                              size: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // "Already have an account? Sign in"
                  GestureDetector(
                    onTap: _navigateToAuth,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        children: [
                          TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Sign in',
                            style: TextStyle(
                              color: _neonGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(_SecurityFeature feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: Column(
        children: [
          // Glowing Neon Icon
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
              border: Border.all(
                color: _neonGreen.withValues(alpha: 0.35),
                width: 0.9,
              ),
              boxShadow: [
                BoxShadow(
                  color: _neonGreen.withValues(alpha: 0.2),
                  blurRadius: 5,
                  spreadRadius: 0.4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                feature.iconAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  feature.fallbackIcon,
                  size: 17,
                  color: _neonGreen,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Feature Title
          SizedBox(
            height: 20,
            child: Center(
              child: Text(
                feature.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7.2,
                  fontWeight: FontWeight.w700,
                  height: 1.08,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),

          // Feature Subtext Description
          SizedBox(
            height: 18,
            child: Center(
              child: Text(
                feature.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _subtextColor,
                  fontSize: 5.6,
                  fontWeight: FontWeight.w400,
                  height: 1.08,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityFeature {
  final String title;
  final String description;
  final String iconAsset;
  final IconData fallbackIcon;

  const _SecurityFeature({
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.fallbackIcon,
  });
}
