import 'dart:math' as math;
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

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<MoleculeParticle> _particles = [];
  final int _particleCount = 30;

  @override
  void initState() {
    super.initState();
    _initParticles();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        _updateParticles();
        setState(() {});
      })..repeat();
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initParticles() {
    final random = math.Random();
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(
        MoleculeParticle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          vx: (random.nextDouble() - 0.5) * 0.0008, // gentle horizontal speed
          vy: (random.nextDouble() - 0.5) * 0.0008, // gentle vertical speed
          size: random.nextDouble() * 3.5 + 1.5,
          opacity: random.nextDouble() * 0.5 + 0.25,
        ),
      );
    }
  }

  void _updateParticles() {
    for (final p in _particles) {
      p.x += p.vx;
      p.y += p.vy;

      if (p.x < 0) p.x = 1.0;
      if (p.x > 1.0) p.x = 0.0;
      if (p.y < 0) p.y = 1.0;
      if (p.y > 1.0) p.y = 0.0;
    }
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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF001F0F), // Rich dark forest green matching logo
                  Color(0xFF000502), // Deep near-black green
                  Color(0xFF000000), // Pure black
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: MoleculePainter(
                particles: _particles,
                particleColor: const Color(0xFF00873C),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00873C).withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset(
                      CommonIcons.logo,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                CommonSpaces.h32,
                Text(
                  'Schat',
                  style: context.h1.copyWith(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
                CommonSpaces.h8,
                Text(
                  'Secure & Private Messaging',
                  style: context.bodyMedium.copyWith(
                    fontSize: 16,
                    color: Colors.white60,
                    letterSpacing: 0.5,
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MoleculeParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double opacity;

  MoleculeParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
  });
}

class MoleculePainter extends CustomPainter {
  final List<MoleculeParticle> particles;
  final Color particleColor;

  MoleculePainter({required this.particles, required this.particleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = particleColor
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final List<Offset> points = particles.map((p) => Offset(p.x * size.width, p.y * size.height)).toList();

    // Draw connecting lines (molecules)
    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final dist = (points[i] - points[j]).distance;
        if (dist < 100) {
          final opacity = (1.0 - (dist / 100)) * 0.15;
          linePaint.color = particleColor.withValues(alpha: opacity);
          canvas.drawLine(points[i], points[j], linePaint);
        }
      }
    }

    // Draw particles
    for (int i = 0; i < points.length; i++) {
      final p = particles[i];
      final glowPaint = Paint()
        ..color = particleColor.withValues(alpha: p.opacity * 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 1.5);
      canvas.drawCircle(points[i], p.size * 2, glowPaint);

      paint.color = particleColor.withValues(alpha: p.opacity);
      canvas.drawCircle(points[i], p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
