import 'package:flutter/material.dart';
import '../presentation/splash_page.dart';

class SplashNavigation {
  static void goTo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SplashPage()),
    );
  }
}
