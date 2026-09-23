import 'package:flutter/material.dart';
import '../navigation/chat_transfer_navigation.dart';

class ChatTransferFlow {
  final BuildContext context;
  ChatTransferFlow(this.context);

  void start() {
    ChatTransferNavigation.openChatTransfer(context);
  }
}
