import 'package:flutter/material.dart';
import '../presentation/chat_transfer_page.dart';

class ChatTransferNavigation {
  static Route<dynamic> route() {
    return MaterialPageRoute<dynamic>(
      builder: (_) => const ChatTransferPage(),
    );
  }

  static void openChatTransfer(BuildContext context) {
    Navigator.push(context, route());
  }
}
