import 'package:flutter/material.dart';
import '../presentation/status_page.dart';

class StatusNavigation {
  void goTo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StatusPage()),
    );
  }
}
