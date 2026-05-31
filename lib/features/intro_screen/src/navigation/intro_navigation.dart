import 'package:flutter/material.dart';
import '../presentation/intro_page.dart';

class IntroNavigation {
  static void goTo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const IntroPage()),
    );
  }
}
