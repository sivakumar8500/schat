import 'package:flutter/material.dart';
import '../presentation/tickets_page.dart';

class TicketsNavigation {
  void goTo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TicketsPage()),
    );
  }
}
