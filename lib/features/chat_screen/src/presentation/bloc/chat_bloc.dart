import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/screen_permission_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/theme_color_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/injection.dart';
import 'chat_event.dart';
import 'chat_state.dart';

// Fixed ChatBloc to clear errors
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final StorageService _storageService;
  final ChatSocketRepository _socketRepository;
  StreamSubscription? _socketSubscription;
  Timer? _typingTimer;
  Timer? _expiryTimer;

  String? _conversationId;
  String? _recipientId;
  bool _currentIsOnline = false;
  bool _currentIsTyping = false;

  int _messagesSkip = 0;
  bool _hasReachedMax = false;
  bool _isFetchingMore = false;

  ChatBloc({
    ChatRepository? chatRepository,
    StorageService? storageService,
    ChatSocketRepository? socketRepository,
  })  : _chatRepository = chatRepository ?? getIt<ChatRepository>(),
        _storageService = storageService ?? getIt<StorageService>(),
        _socketRepository = socketRepository ?? getIt<ChatSocketRepository>(),
        super(const ChatInitial()) {
    on<LoadMessagesEvent>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<ReceiveMessageEvent>(_onReceiveMessage);
    on<ToggleMuteEvent>(_onToggleMute);
    on<ToggleLockEvent>(_onToggleLock);
    on<UpdateUserStatusEvent>(_onUpdateUserStatus);
    on<UpdateTypingIndicatorEvent>(_onUpdateTypingIndicator);
    on<MarkMessageReadEvent>(_onMarkMessageRead);
    on<MarkMessageDeliveredEvent>(_onMarkMessageDelivered);
    on<DeleteMessagesEvent>(_onDeleteMessages);
    on<EditMessageEvent>(_onEditMessage);
    on<PinMessageEvent>(_onPinMessage);
    on<ReceivePinMessageEvent>(_onReceivePinMessage);
    on<ReceiveUnpinMessageEvent>(_onReceiveUnpinMessage);
    on<ReceiveDeleteMessageEvent>(_onReceiveDeleteMessage);
    on<ReceiveEditMessageEvent>(_onReceiveEditMessage);
    on<ChangeBackgroundColorEvent>(_onChangeBackgroundColor);
    on<UpdateAttachmentPermissionsEvent>(_onUpdateAttachmentPermissions);
    on<MarkMessageFailedEvent>(_onMarkMessageFailed);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<SetDisappearingTimerEvent>(_onSetDisappearingTimer);
    on<UpdateGroupInfoEvent>(_onUpdateGroupInfo);
    on<AddGroupParticipantsEvent>(_onAddGroupParticipants);
    on<RemoveGroupParticipantEvent>(_onRemoveGroupParticipant);
    on<ReceiveCallLogUpdateEvent>(_onReceiveCallLogUpdate);
    on<CloseChatEvent>((event, emit) => emit(const ChatDeleted()));
    on<ShowNotificationEvent>((event, emit) async {
      final currentState = state;
      if (currentState is ChatLoaded) {
        emit(currentState.copyWith(notificationMessage: event.message));
        // Reset notification message after emission so it doesn't show again on next build
        await Future.delayed(Duration.zero);
        final latestState = state;
        if (latestState is ChatLoaded) {
          emit(latestState.copyWith(notificationMessage: null));
        }
      }
    });
    on<ClearChatEvent>(_onClearChat);
    on<LoadThemesEvent>(_onLoadThemes);
    on<UpdateThemeEvent>(_onUpdateTheme);
    on<ResetThemeEvent>(_onResetTheme);
    on<LoadMoreMessagesEvent>(_onLoadMoreMessages);
    on<UpdateMessageSecurityEvent>(_onUpdateMessageSecurity);
    on<FetchMessageSharesEvent>(_onFetchMessageShares);
    on<ReceiveGroupUpdatedEvent>(_onReceiveGroupUpdated);
    on<ReceiveGroupAdminUpdatedEvent>(_onReceiveGroupAdminUpdated);
    on<PromoteGroupAdminEvent>(_onPromoteGroupAdmin);
    on<DemoteGroupAdminEvent>(_onDemoteGroupAdmin);
    on<ReceiveFileActionEvent>(_onReceiveFileAction);
    on<ScheduleMessageEvent>(_onScheduleMessage);
    on<CheckExpiredMessagesEvent>(_onCheckExpiredMessages);
    on<ReceiveDisappearingTimerUpdatedEvent>(_onReceiveDisappearingTimerUpdated);
    on<ReceiveScreenPermissionRequestEvent>(_onReceiveScreenPermissionRequest);
    on<ReceiveScreenPermissionResponseEvent>(_onReceiveScreenPermissionResponse);
    on<UpdateActiveScreenPermissionEvent>(_onUpdateActiveScreenPermission);
    on<ConsumeScreenPermissionEvent>(_onConsumeScreenPermission);
    on<DismissIncomingScreenPermissionRequestEvent>(_onDismissIncomingScreenPermissionRequest);

    _listenToSocket();
    _startExpiryTimer();
  }

  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const CheckExpiredMessagesEvent());
    });
  }

  void _onCheckExpiredMessages(CheckExpiredMessagesEvent event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      bool hasExpired = false;
      final filteredMessages = currentState.messages.where((msg) {
        if (msg.expiry != null && msg.expiry! > 0) {
          if (now >= msg.expiry!) {
            hasExpired = true;
            return false;
          }
        }
        return true;
      }).toList();

      if (hasExpired) {
        emit(currentState.copyWith(messages: filteredMessages));
        if (_conversationId != null) {
          _saveToCache(_conversationId!, filteredMessages);
        }
      }
    }
  }

  List<MessageModel> _filterExpiredMessages(List<MessageModel> messages) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return messages.where((msg) {
      if (msg.expiry != null && msg.expiry! > 0) {
        return now < msg.expiry!;
      }
      return true;
    }).toList();
  }

  bool _isSameConversation(dynamic id1, dynamic id2) {
    if (id1 == null || id2 == null) return false;
    final s1 = id1.toString().replaceAll('-', '').toLowerCase().trim();
    final s2 = id2.toString().replaceAll('-', '').toLowerCase().trim();
    return s1 == s2;
  }

  Map<String, dynamic> _cleanMap(Map<dynamic, dynamic> map) {
    final Map<String, dynamic> result = {};
    map.forEach((key, val) {
      final k = key.toString();
      if (val is Map) {
        result[k] = _cleanMap(val);
      } else if (val is List) {
        result[k] = val.map((item) => item is Map ? _cleanMap(item) : item).toList();
      } else {
        result[k] = val;
      }
    });
    return result;
  }

  void _listenToSocket() {
    _socketSubscription = _socketRepository.onMessage.listen((data) {
      debugPrint('DEBUG: ChatBloc RECEIVED DATA: $data');
      
      if (data is Map) {
        final cleanData = _cleanMap(data);
        final type = cleanData['type']?.toString();
        
        if (type == 'new_message' || type == 'message') {
          final message = cleanData['message'] ?? (cleanData.containsKey('id') ? cleanData : null);
          if (message is Map) {
            final msgData = Map<String, dynamic>.from(message);
            final msgConvId = (msgData['conversationId'] ?? msgData['conversation_id'] ?? msgData['conversation'])?.toString();
            
            debugPrint('DEBUG: Received message check. msgConvId=$msgConvId, activeConvId=$_conversationId');
            
            if (_isSameConversation(msgConvId, _conversationId)) {
              add(ReceiveMessageEvent(messageData: msgData));
            } else {
              debugPrint('DEBUG: Conversation ID mismatch. Ignored.');
            }
          }
        } else if (type == 'user_typing' || type == 'typing') {
          final convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          final isTypingField = cleanData['is_typing'] ?? cleanData['isTyping'];
          final isTyping = isTypingField is bool ? isTypingField : true;
          
          if (_isSameConversation(convId, _conversationId)) {
            add(UpdateTypingIndicatorEvent(
              conversationId: convId ?? '',
              isTyping: isTyping,
            ));
          }
        } else if (type == 'message_read' || type == 'read_receipt' || type == 'message_opened') {
          final convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          final msgId = (cleanData['messageId'] ?? cleanData['message_id'] ?? cleanData['id'])?.toString();
          if (_isSameConversation(convId, _conversationId) && msgId != null) {
            add(MarkMessageReadEvent(messageId: msgId, conversationId: convId!));
          }
        } else if (type == 'delivery_receipt' || type == 'message_delivered') {
          final convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          final msgId = (cleanData['messageId'] ?? cleanData['message_id'] ?? cleanData['id'])?.toString();
          if (_isSameConversation(convId, _conversationId) && msgId != null) {
            add(MarkMessageDeliveredEvent(messageId: msgId, conversationId: convId!));
          }
        } else if (type == 'message_deleted_for_everyone' || type == 'delete_message') {
          final convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          final msgId = (cleanData['messageId'] ?? cleanData['message_id'] ?? cleanData['id'])?.toString();
          if (_isSameConversation(convId, _conversationId) && msgId != null) {
            add(ReceiveDeleteMessageEvent(messageId: msgId, conversationId: convId!));
          }
        } else if (type == 'message_edited' || type == 'edit_message') {
          final message = cleanData['message'];
          String? convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          
          final Map<String, dynamic> msgMap = (message is Map) 
              ? Map<String, dynamic>.from(message) 
              : Map<String, dynamic>.from(cleanData);

          convId ??= (msgMap['conversationId'] ?? msgMap['conversation_id'] ?? msgMap['conversation'])?.toString();
          final msgId = (msgMap['id'] ?? msgMap['messageId'] ?? msgMap['message_id'])?.toString();
          
          final contentMap = msgMap['content'];
          final newContent = contentMap is Map ? contentMap['text']?.toString() : msgMap['content']?.toString();
          final updatedAt = (msgMap['updatedAt'] ?? msgMap['updated_at'])?.toString();
          final editedAt = int.tryParse((msgMap['editedAt'] ?? msgMap['edited_at'])?.toString() ?? '');

          final securityMap = msgMap['security'] ?? cleanData['security'];
          final viewControlMap = msgMap['viewControl'] ?? msgMap['view_control'] ?? cleanData['viewControl'] ?? cleanData['view_control'];

          bool? allowShare;
          bool? allowDownload;
          bool? allowView;
          bool? isLocked;

          if (securityMap is Map) {
            if (securityMap['allowShare'] != null) {
              allowShare = securityMap['allowShare'] as bool;
            } else if (securityMap['allow_share'] != null) allowShare = securityMap['allow_share'] as bool;

            if (securityMap['allowDownload'] != null) {
              allowDownload = securityMap['allowDownload'] as bool;
            } else if (securityMap['allow_download'] != null) allowDownload = securityMap['allow_download'] as bool;

            if (securityMap['allowView'] != null) {
              allowView = securityMap['allowView'] as bool;
            } else if (securityMap['allow_view'] != null) allowView = securityMap['allow_view'] as bool;

            if (securityMap['isLocked'] != null) {
              isLocked = securityMap['isLocked'] as bool;
            } else if (securityMap['is_locked'] != null) isLocked = securityMap['is_locked'] as bool;
          }

          if (viewControlMap is Map) {
            if (allowShare == null && viewControlMap['allowShare'] != null) allowShare = viewControlMap['allowShare'] as bool;
            if (allowDownload == null && viewControlMap['allowDownload'] != null) allowDownload = viewControlMap['allowDownload'] as bool;
            if (allowView == null && viewControlMap['allowView'] != null) allowView = viewControlMap['allowView'] as bool;
          }

          if (msgMap['allowShare'] != null) allowShare = msgMap['allowShare'] as bool;
          if (msgMap['allowDownload'] != null) allowDownload = msgMap['allowDownload'] as bool;
          if (msgMap['allowView'] != null) allowView = msgMap['allowView'] as bool;

          if (_isSameConversation(convId, _conversationId) && msgId != null) {
            add(ReceiveEditMessageEvent(
              messageId: msgId,
              conversationId: convId ?? _conversationId!,
              newContent: newContent,
              updatedAt: updatedAt,
              editedAt: editedAt,
              allowShare: allowShare,
              allowDownload: allowDownload,
              allowView: allowView,
              isLocked: isLocked,
            ));
          }
        } else if (type == 'message_pinned' || type == 'pin_message') {
          final convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          if (_isSameConversation(convId, _conversationId)) {
            add(ReceivePinMessageEvent(messageData: cleanData));
          }
        } else if (type == 'message_unpinned' || type == 'unpin_message') {
          final convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          if (_isSameConversation(convId, _conversationId)) {
            add(ReceiveUnpinMessageEvent(messageData: cleanData));
          }
        } else if (type == 'file_viewed' || type == 'file_downloaded' || type == 'file_shared') {
          final userId = (cleanData['user_id'] ?? cleanData['userId'])?.toString();
          final msgId = (cleanData['messageId'] ?? cleanData['message_id'] ?? cleanData['id'])?.toString();
          if (userId != null && userId != _storageService.getUserId()) {
             final action = type!.split('_').last;
             add(ShowNotificationEvent(message: 'Other participant $action your file'));
             if (msgId != null) {
               add(ReceiveFileActionEvent(messageId: msgId, actionType: type));
             }
          }
        } else if (type == 'conversation_deleted') {
          final convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          if (_isSameConversation(convId, _conversationId)) {
             add(const CloseChatEvent());
          }
        } else if (type == 'group_updated') {
          final convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          if (_isSameConversation(convId, _conversationId)) {
            add(ReceiveGroupUpdatedEvent(data: cleanData));
          }
        } else if (type == 'group_admin_updated') {
          final convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          if (_isSameConversation(convId, _conversationId)) {
            add(ReceiveGroupAdminUpdatedEvent(data: cleanData));
          }
        } else if (type == 'user_status' || type == 'user_online' || type == 'user_offline') {
          final userId = (cleanData['user_id'] ?? cleanData['id'] ?? cleanData['sender_id'])?.toString();
          final status = cleanData['status']?.toString();
          final isOnline = type == 'user_online' || (type == 'user_status' && status == 'online');
          final lastSeen = cleanData['last_seen']?.toString();
          debugPrint('DEBUG: Status Match Check - Event User: $userId, Current Recipient: $_recipientId, Type: $type, isOnline: $isOnline, lastSeen: $lastSeen');
          if (userId == _recipientId) {
            add(UpdateUserStatusEvent(
              userId: userId ?? '',
              isOnline: isOnline,
              lastSeen: lastSeen,
            ));
          }
        } else if (type == 'change_background_color') {
          final convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          final contentMap = cleanData['content'];
          final colorStr = contentMap is Map ? contentMap['text']?.toString() : cleanData['content']?.toString();
          if (_isSameConversation(convId, _conversationId) && colorStr != null) {
            final colorVal = int.tryParse(colorStr);
            if (colorVal != null) {
              add(ChangeBackgroundColorEvent(
                color: Color(colorVal),
                conversationId: convId!,
              ));
            }
          }
        } else if (type == 'update_attachment_permissions') {
          final convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          
          final viewControlMap = cleanData['viewControl'] ?? cleanData['view_control'];
          final securityMap = cleanData['security'];
          final contentMap = cleanData['content'];

          var msgId = (cleanData['messageId'] ?? cleanData['message_id'] ?? cleanData['id'])?.toString();
          if (msgId == null && securityMap is Map) {
            msgId = (securityMap['messageId'] ?? securityMap['message_id'])?.toString();
          }
          if (msgId == null && viewControlMap is Map) {
            msgId = (viewControlMap['messageId'] ?? viewControlMap['message_id'])?.toString();
          }
          if (msgId == null && contentMap is Map) {
            msgId = contentMap['text']?.toString();
          }
          
          bool allowShare = true;
          bool allowDownload = true;
          bool allowView = true;

          if (securityMap is Map) {
            allowShare = (securityMap['allowShare'] ?? securityMap['allow_share'] ?? allowShare) as bool;
            allowDownload = (securityMap['allowDownload'] ?? securityMap['allow_download'] ?? allowDownload) as bool;
            allowView = (securityMap['allowView'] ?? securityMap['allow_view'] ?? allowView) as bool;
          }

          if (viewControlMap is Map) {
            allowShare = (viewControlMap['allowShare'] ?? viewControlMap['allow_share'] ?? allowShare) as bool;
            allowDownload = (viewControlMap['allowDownload'] ?? viewControlMap['allow_download'] ?? allowDownload) as bool;
            allowView = (viewControlMap['allowView'] ?? viewControlMap['allow_view'] ?? allowView) as bool;
          }

          allowShare = (cleanData['allowShare'] ?? cleanData['allow_share'] ?? allowShare) as bool;
          allowDownload = (cleanData['allowDownload'] ?? cleanData['allow_download'] ?? allowDownload) as bool;
          allowView = (cleanData['allowView'] ?? cleanData['allow_view'] ?? allowView) as bool;

          if (_isSameConversation(convId, _conversationId) && msgId != null) {
            add(UpdateAttachmentPermissionsEvent(
              messageId: msgId,
              conversationId: convId!,
              allowShare: allowShare,
              allowDownload: allowDownload,
              allowView: allowView,
            ));
          }
        } else if (type == 'call_log_updated') {
          final convId = (cleanData['conversation_id'] ?? cleanData['conversationId'])?.toString();
          if (_isSameConversation(convId, _conversationId)) {
            add(ReceiveCallLogUpdateEvent(callLogData: cleanData));
          }
        } else if (type == 'screen_permission_request') {
          final req = cleanData['request'] ?? cleanData;
          if (req is Map) {
            final convId = (req['conversationId'] ?? req['conversation_id'])?.toString();
            if (_isSameConversation(convId, _conversationId)) {
              add(ReceiveScreenPermissionRequestEvent(requestData: Map<String, dynamic>.from(req)));
            }
          }
        } else if (type == 'screen_permission_response') {
          final req = cleanData['request'] ?? cleanData;
          final action = cleanData['action']?.toString() ?? cleanData['status']?.toString() ?? 'rejected';
          if (req is Map) {
            final convId = (req['conversationId'] ?? req['conversation_id'])?.toString();
            if (_isSameConversation(convId, _conversationId)) {
              add(ReceiveScreenPermissionResponseEvent(requestData: Map<String, dynamic>.from(req), action: action));
            }
          }
        } else if (type == 'conversation_settings_updated' || type == 'disappearing_timer_updated') {
          final convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          if (_isSameConversation(convId, _conversationId)) {
            final dynamic rawTimer = cleanData['disappearing_timer'] ?? cleanData['disappearingTimer'] ?? cleanData['timer'];
            final int? timerSec = rawTimer != null ? int.tryParse(rawTimer.toString()) : null;
            add(ReceiveDisappearingTimerUpdatedEvent(seconds: timerSec));
          }
        } else if (type == 'error') {
          final errorMsg = cleanData['message']?.toString() ?? 'An error occurred';
          add(ShowNotificationEvent(message: errorMsg));
          final currentState = state;
          if (currentState is ChatLoaded) {
            final lastTempIndex = currentState.messages.lastIndexWhere(
              (msg) => msg.senderId == currentState.myId && (msg.id.startsWith('temp_') || msg.isUploading),
            );
            if (lastTempIndex != -1) {
              final failedMsgId = currentState.messages[lastTempIndex].id;
              add(MarkMessageFailedEvent(messageId: failedMsgId, conversationId: _conversationId!));
            }
          }
        } else if (type == 'pong') {
          debugPrint('DEBUG: ChatBloc received Heartbeat PONG');
        } else {
          debugPrint('DEBUG: ChatBloc ignored event type: $type');
        }
      } else {
        debugPrint('DEBUG: ChatBloc received non-map data: ${data.runtimeType} -> $data');
      }
    }, onError: (e) {
      debugPrint('DEBUG: ChatBloc Socket Stream Error: $e');
    });
  }

  Future<void> _onLoadMessages(LoadMessagesEvent event, Emitter<ChatState> emit) async {
    _conversationId = event.conversationId;
    _recipientId = event.recipientId;
    _currentIsOnline = event.initialIsOnline ?? false;

    _messagesSkip = 0;
    _hasReachedMax = false;
    _isFetchingMore = false;

    final myId = _storageService.getUserId() ?? '';
    Color? savedColor;
    bool isMuted = false;
    String? savedWallpaper = event.initialCustomWallpaperUrl;
    ThemeColorModel? savedThemeColor = event.initialThemeColor;
    
    // 1. Try loading from cache first
    List<MessageModel> cachedMessages = [];
    try {
      final msgBox = await Hive.openBox('cached_messages');
      final List<dynamic>? cachedList = msgBox.get(event.conversationId);
      if (cachedList != null) {
        cachedMessages = cachedList
            .map((item) => MessageModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      final bgBox = await Hive.openBox('chat_backgrounds');
      final cachedColorVal = bgBox.get(event.conversationId);
      if (cachedColorVal != null) {
        savedColor = Color(cachedColorVal);
      }

      final wallpaperBox = await Hive.openBox('chat_wallpapers');
      savedWallpaper ??= wallpaperBox.get(event.conversationId) as String?;
      savedWallpaper ??= wallpaperBox.get('default_wallpaper') as String?;

      if (savedThemeColor == null) {
        final themeBox = await Hive.openBox('chat_themes');
        final dynamic rawTheme = themeBox.get(event.conversationId) ?? themeBox.get('default_theme');
        if (rawTheme != null && rawTheme is Map) {
          savedThemeColor = ThemeColorModel.fromJson(Map<String, dynamic>.from(rawTheme));
        }
      }

      final muteBox = await Hive.openBox('muted_chats_box');
      final List<dynamic>? mutedList = muteBox.get('muted_list');
      if (mutedList != null) {
        isMuted = mutedList.contains(event.conversationId);
      }
    } catch (e) {
      debugPrint('Error loading cached messages or theme: $e');
    }

    if (cachedMessages.isNotEmpty) {
      final filteredCached = _filterExpiredMessages(cachedMessages);
      emit(ChatLoaded(
        messages: filteredCached,
        myId: myId,
        isMuted: isMuted,
        isRecipientOnline: _currentIsOnline,
        isRecipientTyping: _currentIsTyping,
        customBgColor: savedColor,
        customWallpaperUrl: savedWallpaper,
        themeColor: savedThemeColor,
        disappearingTimer: event.initialDisappearingTimer,
      ));
    } else {
      emit(const ChatLoading());
    }

    // 2. Fetch fresh messages from API in background
    try {
      var messages = await _chatRepository.getMessages(event.conversationId, limit: 50, skip: 0);
      _messagesSkip = messages.length;
      if (messages.length < 50) {
        _hasReachedMax = true;
      }
      final pinnedMessages = await _chatRepository.getPinnedMessages(event.conversationId);
      
      // Save fresh messages to cache
      _saveToCache(event.conversationId, messages);

      // Mark unread messages from recipient as read (send read receipt to server)
      for (var msg in messages) {
        if (msg.senderId != myId && !msg.isRead) {
          _socketRepository.sendReadReceipt(msg.conversationId, msg.id);
        }
      }

      // ── Infer read/delivered status from message history ──────────────────
      // If the recipient has sent any message AFTER one of our messages,
      // they clearly read everything before it → mark those as isRead=true.
      // Also mark any sent (non-temp) message as at least isDelivered=true
      // since the server acknowledged it.
      String? lastRecipientMessageTime;
      // Walk newest→oldest to find last recipient reply timestamp
      for (final msg in messages.reversed) {
        if (msg.senderId != myId) {
          lastRecipientMessageTime = msg.createdAt;
          break;
        }
      }

      messages = messages.map((msg) {
        if (msg.senderId != myId) return msg;
        // Skip failed messages — keep their status as-is
        if (msg.isFailed) return msg;
        // Our sent message — only infer delivery if the server has confirmed it (non-temp, not failed)
        bool inferredRead = msg.isRead;
        bool inferredDelivered = msg.isDelivered; // only trust server-confirmed flag

        if (!inferredRead && lastRecipientMessageTime != null) {
          // If recipient sent a message after this one, it was read
          final myTime = DateTime.tryParse(msg.createdAt);
          final recipientTime = DateTime.tryParse(lastRecipientMessageTime);
          if (myTime != null && recipientTime != null && recipientTime.isAfter(myTime)) {
            inferredRead = true;
          }
        }
        if (inferredRead == msg.isRead && inferredDelivered == msg.isDelivered) return msg;
        return msg.copyWith(
          isRead: inferredRead,
          isDelivered: inferredDelivered,
        );
      }).toList();

      ScreenPermissionModel? activeScreenPermission;
      try {
        activeScreenPermission = await _chatRepository.getActiveScreenPermission(event.conversationId);
      } catch (_) {}

      final currentState = state;
      if (currentState is ChatLoaded) {
        emit(currentState.copyWith(
          messages: messages,
          pinnedMessages: pinnedMessages,
          themeColor: savedThemeColor ?? currentState.themeColor,
          customWallpaperUrl: savedWallpaper ?? currentState.customWallpaperUrl,
          activeScreenPermission: activeScreenPermission ?? currentState.activeScreenPermission,
        ));
      } else {
        emit(ChatLoaded(
          messages: messages,
          pinnedMessages: pinnedMessages,
          myId: myId,
          isMuted: isMuted,
          isRecipientOnline: _currentIsOnline,
          isRecipientTyping: _currentIsTyping,
          customBgColor: savedColor,
          customWallpaperUrl: savedWallpaper,
          themeColor: savedThemeColor,
          disappearingTimer: event.initialDisappearingTimer,
          activeScreenPermission: activeScreenPermission,
        ));
      }
    } catch (e) {
      if (state is! ChatLoaded) {
        emit(ChatError(errorMessage: e.toString()));
      } else {
        debugPrint('Error reloading messages from API: $e');
      }
    }

    // Fetch recipient profile for initial lastSeen in background
    final rId = event.recipientId;
    if (rId != null && rId.isNotEmpty) {
      getIt<ProfileRepository>().getUserById(rId).then((result) {
        result.when(
          success: (user) {
            final currentState = state;
            if (currentState is ChatLoaded) {
              add(UpdateUserStatusEvent(
                userId: rId,
                isOnline: user.isOnline,
                lastSeen: user.lastSeen,
              ));
            }
          },
          failure: (_, _) {},
        );
      }).catchError((e) {
        debugPrint('Error fetching recipient lastSeen: $e');
      });
    }
  }

  Future<void> _onLoadMoreMessages(LoadMoreMessagesEvent event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is! ChatLoaded || _hasReachedMax || _isFetchingMore) {
      return;
    }

    _isFetchingMore = true;

    try {
      final moreMessages = await _chatRepository.getMessages(
        event.conversationId,
        limit: 50,
        skip: _messagesSkip,
      );

      if (moreMessages.isEmpty) {
        _hasReachedMax = true;
        _isFetchingMore = false;
        return;
      }

      _messagesSkip += moreMessages.length;
      if (moreMessages.length < 50) {
        _hasReachedMax = true;
      }

      // Prepend the older messages to the existing list.
      final filteredMore = _filterExpiredMessages(moreMessages);
      final updatedMessages = List<MessageModel>.from(filteredMore)..addAll(currentState.messages);

      emit(currentState.copyWith(messages: updatedMessages));
      _isFetchingMore = false;
      _saveToCache(event.conversationId, updatedMessages);
    } catch (e) {
      debugPrint('Error loading more messages: $e');
      _isFetchingMore = false;
    }
  }

  Future<void> _onSendMessage(SendMessageEvent event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final String now = DateTime.now().toIso8601String();
      final newMessage = MessageModel(
        id: event.messageId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: event.conversationId,
        senderId: currentState.myId,
        content: event.text,
        mediaUrl: event.attachmentPath,
        mediaType: event.type,
        latitude: event.latitude,
        longitude: event.longitude,
        address: event.address,
        locationTitle: event.title,
        isDeleted: false,
        createdAt: now,
        updatedAt: now,
        isReply: event.replyMessageId != null,
        replyMessageId: event.replyMessageId,
        replyMessageBody: event.replyMessageBody,
        attachmentBytes: event.attachmentBytes,
        attachmentName: event.attachmentName,
        isUploading: event.type != 'text' && event.type != 'location' && event.type != 'contact',
        allowShare: event.allowShare,
        allowDownload: event.allowDownload,
        allowView: event.allowView,
        fileSize: event.fileSize,
      );

      final updatedMessages = _filterExpiredMessages(List<MessageModel>.from(currentState.messages)..add(newMessage));
      emit(currentState.copyWith(messages: updatedMessages));
      _saveToCache(event.conversationId, updatedMessages);
    }
  }

  void _onReceiveMessage(ReceiveMessageEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    debugPrint('DEBUG: _onReceiveMessage called. state is ${currentState.runtimeType}');
    if (currentState is ChatLoaded) {
      try {
        final newMessage = MessageModel.fromJson(event.messageData);
        debugPrint('DEBUG: Decoded new message. ID=${newMessage.id}, sender=${newMessage.senderId}, myId=${currentState.myId}');
        
        // Determine if this is our own echoed message:
        // backend sends userView="send" for the sender's copy
        final userView = (event.messageData['userView'] as String?)?.toLowerCase();
        final isMine = userView == 'send' ||
            (newMessage.senderId == currentState.myId && newMessage.senderId.isNotEmpty);

        if (isMine) {
          debugPrint('DEBUG: Message is from me (userView=$userView), updating temp message with real ID');
          final updatedMessages = List<MessageModel>.from(currentState.messages);

          // The server-confirmed message is at least "delivered" (it was acknowledged)
          final confirmedMessage = (newMessage.isDelivered || newMessage.isRead)
              ? newMessage
              : newMessage.copyWith(isDelivered: true);

          int index = updatedMessages.lastIndexWhere((msg) =>
              msg.id.startsWith('temp_') && msg.content == newMessage.content);
          if (index != -1) {
            updatedMessages[index] = confirmedMessage;
            final filtered = _filterExpiredMessages(updatedMessages);
            emit(currentState.copyWith(messages: filtered));
            _saveToCache(_conversationId!, filtered);
          } else {
            int lastTempIndex = updatedMessages.lastIndexWhere((msg) => msg.id.startsWith('temp_'));
            if (lastTempIndex != -1) {
              updatedMessages[lastTempIndex] = confirmedMessage;
              final filtered = _filterExpiredMessages(updatedMessages);
              emit(currentState.copyWith(messages: filtered));
              _saveToCache(_conversationId!, filtered);
            }
          }
          return;
        }

        final updatedMessages = _filterExpiredMessages(List<MessageModel>.from(currentState.messages)..add(newMessage));
        _currentIsTyping = false;
        
        // Send read receipt back to sender via socket
        _socketRepository.sendReadReceipt(newMessage.conversationId, newMessage.id);

        emit(currentState.copyWith(
          messages: updatedMessages,
          isRecipientTyping: false,
        ));
        _saveToCache(_conversationId!, updatedMessages);
        _typingTimer?.cancel();
      } catch (e) {
        debugPrint('Error parsing incoming message: $e');
      }
    } else {
      debugPrint('DEBUG: Message received but state is not ChatLoaded. Current state: ${currentState.runtimeType}');
    }
  }

  Future<void> _onToggleMute(ToggleMuteEvent event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is ChatLoaded && _conversationId != null) {
      _chatRepository.toggleMute(conversationId: _conversationId!, isMuted: event.isMuted);
      emit(currentState.copyWith(isMuted: event.isMuted));
      
      try {
        final box = await Hive.openBox('muted_chats_box');
        final List<dynamic> list = List.from(box.get('muted_list') ?? []);
        if (event.isMuted) {
          if (!list.contains(_conversationId)) {
            list.add(_conversationId);
          }
        } else {
          list.remove(_conversationId);
        }
        await box.put('muted_list', list);
      } catch (e) {
        debugPrint('Error saving muted status: $e');
      }
    }
  }

  void _onToggleFavorite(ToggleFavoriteEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded && _conversationId != null) {
      _chatRepository.toggleFavorite(conversationId: _conversationId!, isFavorite: event.isFavorite);
      emit(currentState.copyWith(isFavorite: event.isFavorite));
    }
  }

  void _onSetDisappearingTimer(SetDisappearingTimerEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded && _conversationId != null) {
      _chatRepository.setDisappearingTimer(conversationId: _conversationId!, seconds: event.seconds);
      emit(currentState.copyWith(
        disappearingTimer: event.seconds,
      ));
    }
  }

  void _onReceiveDisappearingTimerUpdated(ReceiveDisappearingTimerUpdatedEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith(
        disappearingTimer: event.seconds,
      ));
    }
  }

  Future<void> _onUpdateGroupInfo(UpdateGroupInfoEvent event, Emitter<ChatState> emit) async {
    try {
      await _chatRepository.updateGroupInfo(
        groupId: event.groupId,
        name: event.name,
        description: event.description,
        iconUrl: event.iconUrl,
      );
      add(const ShowNotificationEvent(message: 'Group updated successfully'));
    } catch (e) {
      add(ShowNotificationEvent(message: 'Failed to update group: $e', isError: true));
    }
  }

  Future<void> _onAddGroupParticipants(AddGroupParticipantsEvent event, Emitter<ChatState> emit) async {
    try {
      await _chatRepository.addGroupParticipants(
        groupId: event.groupId,
        userIds: event.userIds,
      );
      add(const ShowNotificationEvent(message: 'Participants added'));
    } catch (e) {
      add(ShowNotificationEvent(message: 'Failed to add participants: $e', isError: true));
    }
  }

  Future<void> _onRemoveGroupParticipant(RemoveGroupParticipantEvent event, Emitter<ChatState> emit) async {
    try {
      await _chatRepository.removeGroupParticipant(
        groupId: event.groupId,
        userId: event.userId,
      );
      add(const ShowNotificationEvent(message: 'Participant removed'));
    } catch (e) {
      add(ShowNotificationEvent(message: 'Failed to remove participant: $e', isError: true));
    }
  }

  void _onToggleLock(ToggleLockEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith(isLocked: event.isLocked));
    }
  }

  void _onUpdateUserStatus(UpdateUserStatusEvent event, Emitter<ChatState> emit) {
    _currentIsOnline = event.isOnline;
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith(
        isRecipientOnline: _currentIsOnline,
        lastSeen: event.lastSeen ?? currentState.lastSeen,
      ));
    }
  }

  void _onUpdateTypingIndicator(UpdateTypingIndicatorEvent event, Emitter<ChatState> emit) {
    _currentIsTyping = event.isTyping;
    final currentState = state;
    if (currentState is ChatLoaded) {
      if (event.isTyping) {
        emit(currentState.copyWith(isRecipientTyping: true));
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 4), () {
          add(UpdateTypingIndicatorEvent(conversationId: event.conversationId, isTyping: false));
        });
      } else {
        emit(currentState.copyWith(isRecipientTyping: false));
      }
    }
  }

  void _onMarkMessageRead(MarkMessageReadEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      // Mark ALL our sent messages up to the target message as read
      final targetIndex = currentState.messages.indexWhere((m) => m.id == event.messageId);
      final msgs = currentState.messages;
      final updated = <MessageModel>[];
      for (int i = 0; i < msgs.length; i++) {
        final msg = msgs[i];
        if (msg.senderId == currentState.myId && !msg.isRead &&
            (targetIndex == -1 || i <= targetIndex)) {
          updated.add(msg.copyWith(isRead: true, isDelivered: true));
        } else {
          updated.add(msg);
        }
      }
      emit(currentState.copyWith(messages: updated));
      _saveToCache(event.conversationId, updated);
    }
  }

  void _onMarkMessageDelivered(MarkMessageDeliveredEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      // Mark ALL our sent messages up to the target message as delivered
      final targetIndex = currentState.messages.indexWhere((m) => m.id == event.messageId);
      final msgs = currentState.messages;
      final updated = <MessageModel>[];
      for (int i = 0; i < msgs.length; i++) {
        final msg = msgs[i];
        if (msg.senderId == currentState.myId && !msg.isDelivered &&
            (targetIndex == -1 || i <= targetIndex)) {
          updated.add(msg.copyWith(isDelivered: true));
        } else {
          updated.add(msg);
        }
      }
      emit(currentState.copyWith(messages: updated));
      _saveToCache(event.conversationId, updated);
    }
  }

  void _onDeleteMessages(DeleteMessagesEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final updatedMessages = currentState.messages.map((msg) {
        if (event.messageIds.contains(msg.id)) {
          if (event.deleteType == 'me') {
            return msg.copyWith(isDeletedForMe: true);
          } else {
            return msg.copyWith(isDeleted: true, content: 'This message was deleted');
          }
        }
        return msg;
      }).toList();

      for (var id in event.messageIds) {
        _socketRepository.deleteMessage(
          conversationId: event.conversationId,
          messageId: id,
          deleteType: event.deleteType,
        );
      }

      final updatedPinned = currentState.pinnedMessages
          .where((m) => !event.messageIds.contains(m.id))
          .toList();

      emit(currentState.copyWith(
        messages: updatedMessages,
        pinnedMessages: updatedPinned,
      ));
      _saveToCache(event.conversationId, updatedMessages);
    }
  }

  void _onEditMessage(EditMessageEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final now = DateTime.now().toIso8601String();
      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == event.messageId) {
          return msg.copyWith(content: event.newContent, isEdited: true, updatedAt: now);
        }
        return msg;
      }).toList();

      _socketRepository.editMessage(
        messageId: event.messageId,
        text: event.newContent,
      );

      emit(currentState.copyWith(messages: updatedMessages));
      _saveToCache(event.conversationId, updatedMessages);
    }
  }

  void _onPinMessage(PinMessageEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      if (event.isPinned) {
        if (currentState.pinnedMessages.length >= 5) {
          emit(currentState.copyWith(notificationMessage: 'Maximum 5 pinned messages allowed'));
          return;
        }
        _socketRepository.pinMessage(messageId: event.messageId);
        _chatRepository.pinMessage(event.messageId).catchError((e) {
          debugPrint('Error pinning message via API: $e');
        });
      } else {
        _socketRepository.unpinMessage(messageId: event.messageId);
        _chatRepository.unpinMessage(event.messageId).catchError((e) {
          debugPrint('Error unpinning message via API: $e');
        });
      }

      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == event.messageId) {
          return msg.copyWith(
            isPinned: event.isPinned,
            pinnedAt: event.isPinned ? (msg.pinnedAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000) : null,
          );
        }
        return msg;
      }).toList();

      final List<MessageModel> updatedPinned;
      if (event.isPinned) {
        final existingIndex = currentState.pinnedMessages.indexWhere((m) => m.id == event.messageId);
        if (existingIndex != -1) {
          updatedPinned = currentState.pinnedMessages;
        } else {
          final targetMsg = currentState.messages.where((m) => m.id == event.messageId).firstOrNull;
          if (targetMsg != null) {
            updatedPinned = List<MessageModel>.from(currentState.pinnedMessages)
              ..add(targetMsg.copyWith(
                isPinned: true,
                pinnedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              ));
          } else {
            updatedPinned = currentState.pinnedMessages;
          }
        }
      } else {
        updatedPinned = currentState.pinnedMessages.where((m) => m.id != event.messageId).toList();
      }

      emit(currentState.copyWith(
        messages: updatedMessages,
        pinnedMessages: updatedPinned,
      ));
      _saveToCache(event.conversationId, updatedMessages);
    }
  }

  void _onReceivePinMessage(ReceivePinMessageEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final messageData = event.messageData['message'];
      if (messageData is Map) {
        final pinnedMsg = MessageModel.fromJson(Map<String, dynamic>.from(messageData));
        
        final updatedMessages = currentState.messages.map((msg) {
          if (msg.id == pinnedMsg.id) {
            return pinnedMsg;
          }
          return msg;
        }).toList();

        final updatedPinned = List<MessageModel>.from(currentState.pinnedMessages);
        final index = updatedPinned.indexWhere((m) => m.id == pinnedMsg.id);
        if (index != -1) {
          updatedPinned[index] = pinnedMsg;
        } else {
          updatedPinned.add(pinnedMsg);
        }
        // Sort by pinnedAt descending (latest first)
        updatedPinned.sort((a, b) => (b.pinnedAt ?? 0).compareTo(a.pinnedAt ?? 0));
        
        emit(currentState.copyWith(
          messages: updatedMessages,
          pinnedMessages: updatedPinned,
        ));
        _saveToCache(_conversationId!, updatedMessages);
      }
    }
  }

  void _onReceiveUnpinMessage(ReceiveUnpinMessageEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final msgId = (event.messageData['message_id'] ?? event.messageData['messageId'])?.toString();
      if (msgId != null) {
        final updatedMessages = currentState.messages.map((msg) {
          if (msg.id == msgId) {
            return msg.copyWith(isPinned: false, pinnedAt: null);
          }
          return msg;
        }).toList();

        final updatedPinned = currentState.pinnedMessages.where((m) => m.id != msgId).toList();
        
        emit(currentState.copyWith(
          messages: updatedMessages,
          pinnedMessages: updatedPinned,
        ));
        _saveToCache(_conversationId!, updatedMessages);
      }
    }
  }

  void _onReceiveDeleteMessage(ReceiveDeleteMessageEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == event.messageId) {
          return msg.copyWith(isDeleted: true, content: 'This message was deleted');
        }
        return msg;
      }).toList();
      final updatedPinned = currentState.pinnedMessages
          .where((m) => m.id != event.messageId)
          .toList();
      emit(currentState.copyWith(
        messages: updatedMessages,
        pinnedMessages: updatedPinned,
      ));
      _saveToCache(event.conversationId, updatedMessages);
    }
  }

  void _onReceiveEditMessage(ReceiveEditMessageEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final editedAtStr = event.updatedAt ?? DateTime.now().toIso8601String();
      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == event.messageId) {
          return msg.copyWith(
            content: event.newContent ?? msg.content,
            isEdited: true,
            updatedAt: editedAtStr,
            editedAt: event.editedAt,
            allowShare: event.allowShare ?? msg.allowShare,
            allowDownload: event.allowDownload ?? msg.allowDownload,
            allowView: event.allowView ?? msg.allowView,
          );
        }
        return msg;
      }).toList();
      emit(currentState.copyWith(messages: updatedMessages));
      _saveToCache(event.conversationId, updatedMessages);
    }
  }

  Future<void> _onChangeBackgroundColor(ChangeBackgroundColorEvent event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      try {
        final bgBox = await Hive.openBox('chat_backgrounds');
        await bgBox.put(event.conversationId, event.color.toARGB32());
      } catch (e) {
        debugPrint('Error saving background color: $e');
      }
      emit(currentState.copyWith(customBgColor: event.color));
    }
  }

  void _onUpdateAttachmentPermissions(UpdateAttachmentPermissionsEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == event.messageId) {
          return msg.copyWith(
            allowShare: event.allowShare,
            allowDownload: event.allowDownload,
            allowView: event.allowView,
          );
        }
        return msg;
      }).toList();
      emit(currentState.copyWith(messages: updatedMessages));
      _saveToCache(event.conversationId, updatedMessages);
    }
  }

  void _onReceiveFileAction(ReceiveFileActionEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == event.messageId) {
          return msg.copyWith(
            isFileViewed: event.actionType == 'file_viewed' ? true : msg.isFileViewed,
            isFileDownloaded: event.actionType == 'file_downloaded' ? true : msg.isFileDownloaded,
            isFileShared: event.actionType == 'file_shared' ? true : msg.isFileShared,
          );
        }
        return msg;
      }).toList();
      emit(currentState.copyWith(messages: updatedMessages));
      if (updatedMessages.isNotEmpty && _conversationId != null) {
        _saveToCache(_conversationId!, updatedMessages);
      }
    }
  }

  void _onMarkMessageFailed(MarkMessageFailedEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == event.messageId) {
          return msg.copyWith(isFailed: true, isUploading: false);
        }
        return msg;
      }).toList();
      emit(currentState.copyWith(messages: updatedMessages));
      _saveToCache(event.conversationId, updatedMessages);
    }
  }

  void _onReceiveCallLogUpdate(ReceiveCallLogUpdateEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final callMetaMap = event.callLogData['call_meta'] ?? event.callLogData['callMeta'];
      var msgId = (event.callLogData['message_id'] ?? event.callLogData['messageId'])?.toString();
      if (msgId == null && callMetaMap is Map) {
        msgId = (callMetaMap['message_id'] ?? callMetaMap['messageId'])?.toString();
      }
      
      if (msgId != null && callMetaMap is Map) {
        final callMeta = CallMeta.fromJson(Map<String, dynamic>.from(callMetaMap));
        final updatedMessages = currentState.messages.map((msg) {
          if (msg.id == msgId) {
            return msg.copyWith(callMeta: callMeta, mediaType: 'call');
          }
          return msg;
        }).toList();
        
        final filteredMessages = _filterExpiredMessages(updatedMessages);
        emit(currentState.copyWith(messages: filteredMessages));
        _saveToCache(_conversationId!, filteredMessages);
      }
    }
  }

  Future<void> _onClearChat(ClearChatEvent event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;
    try {
      final clearedAt = await _chatRepository.clearChat(event.conversationId);

      // Filter messages: keep only those whose createdAt is AFTER clearedAt
      List<MessageModel> remaining;
      if (clearedAt != null) {
        final clearedAtMs = DateTime.tryParse(clearedAt)?.millisecondsSinceEpoch;
        if (clearedAtMs != null) {
          remaining = currentState.messages.where((msg) {
            final msgMs = DateTime.tryParse(msg.createdAt)?.millisecondsSinceEpoch;
            return msgMs != null && msgMs > clearedAtMs;
          }).toList();
        } else {
          remaining = [];
        }
      } else {
        remaining = [];
      }

      // Wipe the Hive cache for this conversation
      Hive.openBox('cached_messages').then((box) => box.delete(event.conversationId));

      emit(currentState.copyWith(
        messages: remaining,
        pinnedMessages: [],
        notificationMessage: 'Chat cleared',
      ));
      // Reset notification toast
      emit(currentState.copyWith(
        messages: remaining,
        pinnedMessages: [],
        notificationMessage: null,
      ));
    } catch (e) {
      debugPrint('Error clearing chat: $e');
      emit(currentState.copyWith(
        notificationMessage: 'Failed to clear chat',
      ));
      emit(currentState.copyWith(notificationMessage: null));
    }
  }

  Future<void> _onLoadThemes(LoadThemesEvent event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;
    try {
      final themes = await _chatRepository.getThemes();
      emit(currentState.copyWith(availableThemes: themes));
    } catch (e) {
      debugPrint('Error loading themes: $e');
    }
  }

  Future<void> _onUpdateTheme(UpdateThemeEvent event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is! ChatLoaded || _conversationId == null) return;
    try {
      final wallpaperBox = await Hive.openBox('chat_wallpapers');
      final themeBox = await Hive.openBox('chat_themes');

      if (event.applyToAll) {
        if (event.customWallpaperUrl != null) {
          await wallpaperBox.put('default_wallpaper', event.customWallpaperUrl);
          await wallpaperBox.put(_conversationId!, event.customWallpaperUrl);
        } else if (event.clearWallpaper) {
          await wallpaperBox.delete('default_wallpaper');
          await wallpaperBox.delete(_conversationId!);
        }

        if (event.themeColor != null) {
          await themeBox.put('default_theme', event.themeColor!.toJson());
          await themeBox.put(_conversationId!, event.themeColor!.toJson());
        } else if (event.themeColorId == null) {
          await themeBox.delete('default_theme');
          await themeBox.delete(_conversationId!);
        }
      } else {
        if (event.customWallpaperUrl != null) {
          await wallpaperBox.put(_conversationId!, event.customWallpaperUrl);
        } else if (event.clearWallpaper) {
          await wallpaperBox.delete(_conversationId!);
        }

        if (event.themeColor != null) {
          await themeBox.put(_conversationId!, event.themeColor!.toJson());
        } else if (event.themeColorId == null) {
          await themeBox.delete(_conversationId!);
        }
      }

      emit(currentState.copyWith(
        themeColor: event.themeColor,
        clearThemeColor: event.themeColorId == null && event.themeColor == null,
        customWallpaperUrl: event.customWallpaperUrl,
        clearCustomWallpaperUrl: event.clearWallpaper || (event.themeColor != null && event.customWallpaperUrl == null),
      ));

      await _chatRepository.updateTheme(
        conversationId: _conversationId!,
        themeColorId: event.themeColorId,
        customWallpaperUrl: event.customWallpaperUrl,
        applyToAll: event.applyToAll,
      );
    } catch (e) {
      debugPrint('Error updating theme: $e');
      final errorMsg = e.toString();
      if (errorMsg.contains('403') || errorMsg.toLowerCase().contains('subscription')) {
        add(const ShowNotificationEvent(
          message: 'Subscription required to customize chat wallpapers & themes.',
          isError: true,
        ));
      } else {
        add(const ShowNotificationEvent(message: 'Failed to update theme', isError: true));
      }
    }
  }

  Future<void> _onResetTheme(ResetThemeEvent event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is! ChatLoaded || _conversationId == null) return;
    try {
      final wallpaperBox = await Hive.openBox('chat_wallpapers');
      final themeBox = await Hive.openBox('chat_themes');

      if (event.resetAll) {
        await wallpaperBox.clear();
        await themeBox.clear();
      } else {
        await wallpaperBox.delete(_conversationId!);
        await themeBox.delete(_conversationId!);
      }

      emit(currentState.copyWith(
        clearThemeColor: true,
        clearCustomWallpaperUrl: true,
      ));

      await _chatRepository.resetTheme(
        conversationId: _conversationId!,
        resetAll: event.resetAll,
      );
      add(const ShowNotificationEvent(message: 'Theme reset to default', isError: false));
    } catch (e) {
      debugPrint('Error resetting theme: $e');
      add(const ShowNotificationEvent(message: 'Failed to reset theme', isError: true));
    }
  }

  void _saveToCache(String conversationId, List<MessageModel> messages) {
    Hive.openBox('cached_messages').then((box) {
      final serializable = messages.map((m) => m.toJson()).toList();
      box.put(conversationId, serializable);
    }).catchError((e) {
      debugPrint('Error saving to cache: $e');
    });
  }

  Future<void> _onUpdateMessageSecurity(
    UpdateMessageSecurityEvent event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;
    try {
      await _chatRepository.updateMessageSecurity(
        event.messageId,
        allowShare: event.allowShare,
        allowDownload: event.allowDownload,
        isLocked: event.isLocked,
      );
      // Update the local message model so the UI reflects the change immediately.
      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == event.messageId) {
          return msg.copyWith(
            allowShare: event.allowShare,
            allowDownload: event.allowDownload,
          );
        }
        return msg;
      }).toList();
      emit(currentState.copyWith(messages: updatedMessages));
      if (_conversationId != null) _saveToCache(_conversationId!, updatedMessages);

      _socketRepository.editMessage(
        messageId: event.messageId,
        security: {
          'isLocked': event.isLocked,
          'allowDownload': event.allowDownload,
          'allowShare': event.allowShare,
          'allowView': true,
        },
      );
      add(ShowNotificationEvent(
        message: event.allowShare ? 'Sharing re-enabled' : 'Sharing disabled for this file',
      ));
    } catch (e) {
      debugPrint('Error updating message security: $e');
      add(ShowNotificationEvent(message: 'Failed to update share settings', isError: true));
    }
  }

  Future<void> _onFetchMessageShares(
    FetchMessageSharesEvent event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;
    try {
      final sharesData = await _chatRepository.getMessageShares(event.messageId);
      emit(currentState.copyWith(
        sharesData: sharesData,
        sharesMessageId: event.messageId,
      ));
    } catch (e) {
      debugPrint('Error fetching message shares: $e');
      add(ShowNotificationEvent(message: 'Failed to load share info', isError: true));
    }
  }

  Future<void> _onReceiveGroupUpdated(
    ReceiveGroupUpdatedEvent event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;
    final data = event.data;
    final newName = (data['group_name'] ?? data['groupName'])?.toString();
    final newPictureUrl = (data['group_picture_url'] ?? data['groupPictureUrl'] ?? data['group_image_url'] ?? data['groupImageUrl'])?.toString();
    emit(currentState.copyWith(
      groupName: newName ?? currentState.groupName,
      groupPictureUrl: newPictureUrl ?? currentState.groupPictureUrl,
    ));
    if (newName != null) {
      add(ShowNotificationEvent(message: 'Group name updated to "$newName"'));
    } else if (newPictureUrl != null) {
      add(ShowNotificationEvent(message: 'Group image was updated'));
    }
  }

  Future<void> _onReceiveGroupAdminUpdated(
    ReceiveGroupAdminUpdatedEvent event,
    Emitter<ChatState> emit,
  ) async {
    final data = event.data;
    final isAdmin = data['is_admin'] ?? data['isAdmin'];
    final label = isAdmin == true ? 'A participant is now an admin' : 'A participant is no longer an admin';
    add(ShowNotificationEvent(message: label));
  }

  Future<void> _onPromoteGroupAdmin(
    PromoteGroupAdminEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.promoteGroupAdmin(groupId: event.groupId, userId: event.userId);
      add(ShowNotificationEvent(message: 'Participant promoted to admin'));
    } catch (e) {
      debugPrint('Error promoting group admin: $e');
      add(ShowNotificationEvent(message: 'Failed to promote admin: $e', isError: true));
    }
  }

  Future<void> _onDemoteGroupAdmin(
    DemoteGroupAdminEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.demoteGroupAdmin(groupId: event.groupId, userId: event.userId);
      add(ShowNotificationEvent(message: 'Admin rights removed'));
    } catch (e) {
      debugPrint('Error demoting group admin: $e');
      add(ShowNotificationEvent(message: 'Failed to remove admin rights: $e', isError: true));
    }
  }

  Future<void> _onScheduleMessage(
    ScheduleMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      try {
        await _chatRepository.scheduleMessage(event.requestData);
        // We do not add the message to the local list yet, it will be delivered by the server when the schedule time hits
      } catch (e) {
        debugPrint('Error scheduling message: $e');
        add(ShowNotificationEvent(message: 'Failed to schedule message: $e', isError: true));
      }
    }
  }

  void _onReceiveScreenPermissionRequest(
    ReceiveScreenPermissionRequestEvent event,
    Emitter<ChatState> emit,
  ) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final model = ScreenPermissionModel.fromJson(event.requestData);
      emit(currentState.copyWith(incomingScreenPermissionRequest: model));
    }
  }

  void _onDismissIncomingScreenPermissionRequest(
    DismissIncomingScreenPermissionRequestEvent event,
    Emitter<ChatState> emit,
  ) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      emit(currentState.copyWith(clearIncomingScreenPermissionRequest: true));
    }
  }

  void _onReceiveScreenPermissionResponse(
    ReceiveScreenPermissionResponseEvent event,
    Emitter<ChatState> emit,
  ) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final model = ScreenPermissionModel.fromJson(event.requestData);
      final isAccepted = event.action.toLowerCase() == 'accept' || model.status == 'accepted';
      final receiverName = model.receiverName ?? 'Contact';
      final permText = model.isScreenshot
          ? '${model.allowedCount ?? 1} screenshot(s)'
          : '${model.durationSeconds ?? 30}s recording';

      if (isAccepted) {
        emit(currentState.copyWith(
          activeScreenPermission: model,
          notificationMessage: '$receiverName accepted your request for $permText!',
        ));
      } else {
        emit(currentState.copyWith(
          clearActiveScreenPermission: true,
          notificationMessage: '$receiverName rejected your request for $permText.',
        ));
      }
    }
  }

  void _onUpdateActiveScreenPermission(
    UpdateActiveScreenPermissionEvent event,
    Emitter<ChatState> emit,
  ) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      if (event.permissionData == null) {
        emit(currentState.copyWith(clearActiveScreenPermission: true));
      } else {
        final model = ScreenPermissionModel.fromJson(event.permissionData!);
        emit(currentState.copyWith(activeScreenPermission: model));
      }
    }
  }

  Future<void> _onConsumeScreenPermission(
    ConsumeScreenPermissionEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final currentPerm = currentState.activeScreenPermission;

      // Optimistically update or clear active permission immediately
      if (currentPerm != null && currentPerm.id == event.requestId) {
        final remaining = (currentPerm.remainingCount ?? currentPerm.allowedCount ?? 1) - 1;
        if (remaining <= 0) {
          emit(currentState.copyWith(clearActiveScreenPermission: true));
        } else {
          emit(currentState.copyWith(
            activeScreenPermission: currentPerm.copyWith(remainingCount: remaining),
          ));
        }
      }

      try {
        final updated = await _chatRepository.consumeScreenPermission(event.requestId);
        if (state is ChatLoaded) {
          final s = state as ChatLoaded;
          if (updated.status == 'completed' || (updated.remainingCount != null && updated.remainingCount! <= 0)) {
            emit(s.copyWith(clearActiveScreenPermission: true));
          } else {
            emit(s.copyWith(activeScreenPermission: updated));
          }
        }
      } catch (e) {
        debugPrint('Error consuming screen permission: $e');
      }
    }
  }

  @override
  Future<void> close() {
    _socketSubscription?.cancel();
    _typingTimer?.cancel();
    _expiryTimer?.cancel();
    return super.close();
  }
}
