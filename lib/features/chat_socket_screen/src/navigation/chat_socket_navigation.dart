import 'package:flutter/material.dart';
import '../presentation/chat_socket_page.dart';

class ChatSocketNavigation {
  void goTo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatSocketPage()),
    );
  }
}
