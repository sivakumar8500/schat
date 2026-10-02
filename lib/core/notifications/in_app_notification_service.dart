import 'dart:async';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/chat_screen/src/domain/models/screen_permission_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/incoming_screen_permission_bottom_sheet.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/injection.dart';
import 'package:schat/main.dart';

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

    // Foreground message notification is handled via system push notification (PushNotificationService),
    // so in-app banner is disabled to avoid duplicate notifications.
    return;
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

  void dispose() {
    _socketSubscription?.cancel();
  }
}
