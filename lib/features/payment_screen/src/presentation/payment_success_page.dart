import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_sizes.dart';
import 'package:schat/utils/common_spaces.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:schat/features/dashboard_screen/dashboard_screen.dart';

class PaymentSuccessPage extends StatefulWidget {
  const PaymentSuccessPage({super.key});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _countdown = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();

    // Start 5-second countdown timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          _timer?.cancel();
          _navigateToDashboard();
        }
      });
    });
  }

  void _navigateToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const DashboardPage()),
      (route) => false, // Remove all previous routes so user can't hit 'Back' to payment
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.primary, // Solid Green Theme
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: context.colors.pureWhite.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CommonIcons.checkCircle,
                  color: context.colors.pureWhite,
                  size: 100,
                ),
              ),
            ),
            CommonSpaces.h32,
            Text(
              'Payment Successful!',
              style: context.h2.copyWith(color: context.colors.pureWhite),
            ),
            CommonSpaces.h16,
            Text(
              'Your subscription is now active.',
              style: context.bodyLarge.copyWith(
                fontSize: 16,
                color: context.colors.pureWhite.withValues(alpha: 0.9),
              ),
            ),
            CommonSpaces.h60,
            Text(
              'Redirecting to dashboard in $_countdown...',
              style: context.bodyMedium.copyWith(
                fontSize: 14,
                color: context.colors.pureWhite.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            CommonSpaces.h24,
            SizedBox(
              width: CommonSizes.p40,
              height: CommonSizes.p40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(context.colors.pureWhite),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

