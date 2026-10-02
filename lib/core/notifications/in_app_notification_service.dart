import 'dart:async';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/call_screen/src/domain/call_sound_service.dart';
import 'package:schat/features/chat_screen/src/domain/models/screen_permission_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_screen/src/presentation/chat_page.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/incoming_screen_permission_bottom_sheet.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/injection.dart';
import 'package:schat/main.dart';
import 'package:schat/utils/common_notifications.dart';

@lazySingleton
class InAppNotificationService {
  final ChatSocketRepository _socketRepository;
  final StorageService _storageService;
  StreamSubscription? _socketSubscription;

  String? _activeConversationId;
  String? _activeRecipientId;

  final Set<String> _shownScreenPermissionRequestIds = {};
  bool _isShowingScreenPermissionSheet = false;

  InAppNotificationService(
    this._socketRepository,
    this._storageService,
  );

  String? get activeConversationId => _activeConversationId;
  String? get activeRecipientId => _activeRecipientId;

  void setActiveChat({String? conversationId, String? recipientId}) {
    _activeConversationId = (conversationId != null && conversationId.trim().isNotEmpty)
        ? conversationId.trim()
        : _activeConversationId;
    _activeRecipientId = (recipientId != null && recipientId.trim().isNotEmpty)
        ? recipientId.trim()
        : _activeRecipientId;
    debugPrint('InAppNotificationService: Active chat set to conv: $_activeConversationId, recipient: $_activeRecipientId');
  }

  void setActiveConversationId(String? conversationId) {
    if (conversationId != null && conversationId.trim().isNotEmpty) {
      _activeConversationId = conversationId.trim();
    }
    debugPrint('InAppNotificationService: Active conversation set to: $_activeConversationId');
  }

  void clearActiveChat() {
    _activeConversationId = null;
    _activeRecipientId = null;
    debugPrint('InAppNotificationService: Active chat cleared');
  }

  bool isChatActive({String? conversationId, String? senderId}) {
    final conv = conversationId?.trim();
    final sender = senderId?.trim();

    if (conv != null &&
        conv.isNotEmpty &&
        _activeConversationId != null &&
        _activeConversationId!.isNotEmpty &&
        conv.toLowerCase() == _activeConversationId!.toLowerCase()) {
      return true;
    }

    if (sender != null &&
        sender.isNotEmpty &&
        _activeRecipientId != null &&
        _activeRecipientId!.isNotEmpty &&
        sender.toLowerCase() == _activeRecipientId!.toLowerCase()) {
      return true;
    }

    return false;
  }

  void initialize() {
    _socketSubscription?.cancel();
    _socketSubscription = _socketRepository.onMessage.listen(_handleSocketMessage);
    debugPrint('InAppNotificationService: Initialized socket listener for in-app message notifications & screen permissions');
  }

  void _handleSocketMessage(dynamic data) {
    if (data is! Map) return;

    final type = data['type']?.toString();

    // Handle screen permission request popup globally (across the entire app)
    if (type == 'screen_permission_request') {
      final reqMap = data['request'] ?? data['data'] ?? data;
      if (reqMap is Map) {
        try {
          final model = ScreenPermissionModel.fromJson(Map<String, dynamic>.from(reqMap));
          final myId = (_storageService.getUserId() ?? '').trim();
          // Never show incoming permission request popup to the requester themselves
          if (myId.isNotEmpty && model.senderId.trim() == myId) {
            return;
          }
          if (model.isPending && (myId.isEmpty || model.receiverId.trim() == myId || model.senderId.trim() != myId)) {
            showIncomingScreenPermissionBottomSheet(model);
          }
        } catch (e) {
          debugPrint('InAppNotificationService: Error parsing screen permission request: $e');
        }
      }
      return;
    }

    if (type != 'new_message' && type != 'message') return;

    final message = data['message'] ?? (data.containsKey('id') ? data : null);
    if (message is! Map) return;

    final convId = (message['conversationId'] ??
            message['conversation_id'] ??
            data['conversation_id'] ??
            data['conversationId'])
        ?.toString()
        .trim();

    final senderId = (message['senderId'] ??
            message['sender_id'] ??
            message['sender'] ??
            data['sender_id'] ??
            data['senderId'])
        ?.toString()
        .trim();

    final myId = (_storageService.getUserId() ?? '').trim();

    // Ignore monitored/transferred messages from triggering popup notifications
    if (data['is_monitored'] == true || data['isMonitored'] == true) return;

    // Ignore if sent by current user
    if (senderId == null || senderId.isEmpty || (myId.isNotEmpty && senderId == myId)) return;

    // For 1-on-1 conversations, ensure receiverId matches current user
    final receiverId = (message['receiverId'] ??
            message['receiver_id'] ??
            data['receiver_id'] ??
            data['receiverId'])
        ?.toString()
        .trim();
    if (receiverId != null && receiverId.isNotEmpty && myId.isNotEmpty && receiverId != myId) {
      debugPrint('InAppNotificationService: Suppressing message not intended for current user (me: $myId, intended: $receiverId)');
      return;
    }

    // Suppress notification if user disabled notifications at app level
    if (!_storageService.getNotificationsEnabled()) {
      debugPrint('InAppNotificationService: Suppressing in-app notification because account notifications are disabled');
      return;
    }

    // Suppress notification if this individual chat is muted
    if (convId != null && _storageService.isChatMuted(convId)) {
      debugPrint('InAppNotificationService: Suppressing in-app notification because chat $convId is muted');
      return;
    }

    // CRITICAL: Suppress in-app notification if user is currently chatting with this person / in this conversation
    if (isChatActive(conversationId: convId, senderId: senderId)) {
      debugPrint('InAppNotificationService: Suppressing in-app notification because user is actively in chat with $senderId / conv $convId');
      return;
    }

    // Determine if the message is a file share / media attachment or call
    final msgType = (message['message_type'] ??
            message['messageType'] ??
            message['type'] ??
            message['media_type'] ??
            message['mediaType'] ??
            data['message_type'] ??
            data['type'])
        ?.toString()
        .toLowerCase();

    final dynamic contentData = message['content'];
    final String? fileUrl = (message['media_url'] ??
            message['mediaUrl'] ??
            message['url'] ??
            message['fileKey'] ??
            message['file_key'] ??
            (contentData is Map
                ? (contentData['fileKey'] ??
                    contentData['file_key'] ??
                    contentData['url'] ??
                    contentData['media_url'])
                : null))
        ?.toString();

    final String? fileName = (message['file_name'] ??
            message['fileName'] ??
            message['attachment_name'] ??
            message['attachmentName'] ??
            (contentData is Map
                ? (contentData['fileName'] ??
                    contentData['file_name'] ??
                    contentData['name'] ??
                    contentData['attachmentName'] ??
                    contentData['attachment_name'])
                : null))
        ?.toString();

    final bool isCall = msgType == 'call' ||
        message['callMeta'] != null ||
        message['call_meta'] != null ||
        data['callMeta'] != null ||
        data['call_meta'] != null;

    final bool isFileShare = (msgType != null &&
            msgType.isNotEmpty &&
            msgType != 'text' &&
            msgType != 'chat' &&
            msgType != 'system') ||
        (fileUrl != null && fileUrl.trim().isNotEmpty) ||
        (fileName != null && fileName.trim().isNotEmpty) ||
        message['has_attachment'] == true ||
        message['is_file'] == true ||
        message['isFileShared'] == true ||
        message['file_shared'] == true ||
        message['is_file_shared'] == true;

    // Play message notification tone for all incoming messages
    try {
      getIt<CallSoundService>().playMessageTone();
    } catch (e) {
      debugPrint('InAppNotificationService: Error playing message tone: $e');
    }

    // REQUIREMENT: Only show in-app banner notification for call and file share. Suppress regular text messages.
    if (!isFileShare && !isCall) {
      debugPrint('InAppNotificationService: Suppressing in-app banner notification for regular text message');
      return;
    }

    // Extract content preview
    String previewText = 'Shared a file';
    if (isCall) {
      previewText = '📞 Call notification';
    } else if (fileName != null && fileName.isNotEmpty) {
      previewText = '📁 $fileName';
    } else if (msgType != null && msgType.isNotEmpty && msgType != 'text') {
      if (msgType == 'image') {
        previewText = '📷 Shared an image';
      } else if (msgType == 'video') {
        previewText = '🎥 Shared a video';
      } else if (msgType == 'document') {
        previewText = '📄 Shared a document';
      } else if (msgType == 'audio' || msgType == 'voice') {
        previewText = '🎵 Shared an audio clip';
      } else {
        previewText = '📁 Shared a file ($msgType)';
      }
    } else if (contentData is Map && contentData['text'] != null && contentData['text'].toString().isNotEmpty) {
      previewText = '📁 ${contentData['text']}';
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

  void showIncomingScreenPermissionBottomSheet(ScreenPermissionModel request) {
    if (!request.isPending || _shownScreenPermissionRequestIds.contains(request.id) || _isShowingScreenPermissionSheet) {
      return;
    }

    final myId = (_storageService.getUserId() ?? '').trim();
    if (myId.isNotEmpty && request.senderId.trim() == myId) {
      return;
    }

    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      // Retry in next frame if context not ready yet
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showIncomingScreenPermissionBottomSheet(request);
      });
      return;
    }

    _shownScreenPermissionRequestIds.add(request.id);
    _isShowingScreenPermissionSheet = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => IncomingScreenPermissionBottomSheet(
        request: request,
        onResponded: (updated) {},
      ),
    ).whenComplete(() {
      _isShowingScreenPermissionSheet = false;
    });
  }

  Future<void> checkPendingScreenPermissions() async {
    try {
      final token = _storageService.getAccessToken();
      if (token == null || token.isEmpty) return;

      final repo = getIt<ChatRepository>();
      final pendingList = await repo.getPendingScreenPermissions();
      final myId = (_storageService.getUserId() ?? '').trim();

      for (final req in pendingList) {
        if (req.isPending && !_shownScreenPermissionRequestIds.contains(req.id)) {
          if (req.receiverId == myId || (myId.isNotEmpty && req.senderId != myId)) {
            showIncomingScreenPermissionBottomSheet(req);
            break; // Show one at a time
          }
        }
      }
    } catch (e) {
      debugPrint('InAppNotificationService: Error checking pending screen permissions: $e');
    }
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
