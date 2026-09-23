import 'dart:async';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/chat_screen/src/presentation/chat_page.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/main.dart';
import 'package:schat/utils/common_notifications.dart';

@lazySingleton
class InAppNotificationService {
  final ChatSocketRepository _socketRepository;
  final StorageService _storageService;
  StreamSubscription? _socketSubscription;

  String? _activeConversationId;

  InAppNotificationService(
    this._socketRepository,
    this._storageService,
  );

  String? get activeConversationId => _activeConversationId;

  void setActiveConversationId(String? conversationId) {
    _activeConversationId = conversationId;
    debugPrint('InAppNotificationService: Active conversation set to: $conversationId');
  }

  void initialize() {
    _socketSubscription?.cancel();
    _socketSubscription = _socketRepository.onMessage.listen(_handleSocketMessage);
    debugPrint('InAppNotificationService: Initialized socket listener for in-app message notifications');
  }

  void _handleSocketMessage(dynamic data) {
    if (data is! Map) return;

    final type = data['type']?.toString();
    if (type != 'new_message' && type != 'message') return;

    final message = data['message'] ?? (data.containsKey('id') ? data : null);
    if (message is! Map) return;

    final convId = (message['conversationId'] ?? message['conversation_id'])?.toString();
    final senderId = (message['senderId'] ?? message['sender_id'] ?? message['sender'])?.toString();
    final myId = _storageService.getUserId() ?? '';

    // Ignore if sent by current user
    if (senderId == null || senderId == myId) return;

    // Ignore if user is currently inside this exact conversation
    if (convId != null && convId == _activeConversationId) {
      debugPrint('InAppNotificationService: Suppressing in-app notification because conversation $convId is currently active');
      return;
    }

    // Extract content preview
    String previewText = 'New message received';
    final content = message['content'];
    if (content is Map) {
      previewText = content['text']?.toString() ?? 'Media message';
    } else if (content is String && content.isNotEmpty) {
      previewText = content;
    } else {
      final msgType = (message['message_type'] ?? message['type'])?.toString();
      if (msgType != null && msgType != 'text') {
        previewText = '📷 [${msgType.toUpperCase()}]';
      }
    }

    // Extract sender name and profile picture
    String senderName = (message['sender_name'] ??
            message['senderName'] ??
            message['username'] ??
            data['sender_name'] ??
            data['senderName'] ??
            'New Message')
        .toString();

    final senderObj = message['sender'] is Map
        ? message['sender'] as Map
        : (data['sender'] is Map ? data['sender'] as Map : null);
    if (senderObj != null && (senderName == 'New Message' || senderName.isEmpty)) {
      senderName = (senderObj['name'] ?? senderObj['username'] ?? senderObj['fullName'] ?? 'New Message').toString();
    }

    String? profilePic = (message['sender_profile_pic'] ??
            message['senderProfilePic'] ??
            message['profile_picture_url'] ??
            message['profilePictureUrl'] ??
            message['profile_picture'] ??
            message['profilePic'] ??
            message['avatar'] ??
            senderObj?['profile_picture_url'] ??
            senderObj?['profilePictureUrl'] ??
            senderObj?['profile_picture'] ??
            senderObj?['profilePic'] ??
            senderObj?['avatar'] ??
            data['sender_profile_pic'] ??
            data['senderProfilePic'] ??
            data['profile_picture_url'] ??
            data['profilePictureUrl'] ??
            data['profile_picture'] ??
            data['avatar'])
        ?.toString();

    if (profilePic != null && profilePic.trim().isEmpty) {
      profilePic = null;
    }

    bool isGroup = message['is_group'] == true || message['isGroup'] == true;

    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    context.showInAppChatNotification(
      senderName: isGroup && message['group_name'] != null ? '${message['group_name']} ($senderName)' : senderName,
      messageText: previewText,
      profilePictureUrl: profilePic,
      onTap: () {
        if (convId != null) {
          _navigateToChat(
            conversationId: convId,
            contactName: senderName,
            recipientId: senderId,
            profilePic: profilePic,
            isGroup: isGroup,
          );
        }
      },
    );
  }

  void _navigateToChat({
    required String conversationId,
    required String contactName,
    required String recipientId,
    String? profilePic,
    bool isGroup = false,
  }) {
    final navState = navigatorKey.currentState;
    if (navState == null) return;

    navState.push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          conversationId: conversationId,
          contactName: contactName,
          contactColor: const Color(0xFF00873C),
          isOnline: true,
          recipientId: recipientId,
          profilePictureUrl: profilePic,
          isGroup: isGroup,
        ),
      ),
    );
  }

  void dispose() {
    _socketSubscription?.cancel();
  }
}
