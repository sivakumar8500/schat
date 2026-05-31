import 'package:flutter/material.dart';
import '../presentation/dashboard_page.dart';

class DashboardNavigation {
  static void goTo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DashboardPage()),
    );
  }
}
