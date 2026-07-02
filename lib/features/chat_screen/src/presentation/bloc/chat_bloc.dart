import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
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

  String? _conversationId;
  String? _recipientId;
  bool _currentIsOnline = false;
  bool _currentIsTyping = false;

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
    on<CloseChatEvent>((event, emit) => emit(const ChatDeleted()));
    on<ShowNotificationEvent>((event, emit) {
      final currentState = state;
      if (currentState is ChatLoaded) {
        emit(currentState.copyWith(notificationMessage: event.message));
        // Reset notification message after emission so it doesn't show again on next build
        emit(currentState.copyWith(notificationMessage: null));
      }
    });

    _listenToSocket();
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
        } else if (type == 'message_deleted_for_everyone' || type == 'delete_message') {
          final convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          final msgId = (cleanData['messageId'] ?? cleanData['message_id'] ?? cleanData['id'])?.toString();
          if (_isSameConversation(convId, _conversationId) && msgId != null) {
            add(ReceiveDeleteMessageEvent(messageId: msgId, conversationId: convId!));
          }
        } else if (type == 'message_edited' || type == 'edit_message') {
          final message = cleanData['message'];
          String? convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          
          if (message is Map) {
            convId ??= (message['conversationId'] ?? message['conversation_id'] ?? message['conversation'])?.toString();
            final msgId = (message['id'] ?? message['messageId'])?.toString();
            final contentMap = message['content'];
            final newContent = contentMap is Map ? contentMap['text']?.toString() : message['content']?.toString();
            if (_isSameConversation(convId, _conversationId) && msgId != null && newContent != null) {
              add(ReceiveEditMessageEvent(messageId: msgId, conversationId: convId ?? _conversationId!, newContent: newContent));
            }
          } else {
            final msgId = (cleanData['messageId'] ?? cleanData['message_id'] ?? cleanData['id'])?.toString();
            final contentMap = cleanData['content'];
            final newContent = contentMap is Map ? contentMap['text']?.toString() : cleanData['content']?.toString();
            if (_isSameConversation(convId, _conversationId) && msgId != null && newContent != null) {
              add(ReceiveEditMessageEvent(messageId: msgId, conversationId: convId!, newContent: newContent));
            }
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
          if (userId != null && userId != _storageService.getUserId()) {
             final action = type!.split('_').last;
             add(ShowNotificationEvent(message: 'Other participant $action your file'));
          }
        } else if (type == 'conversation_deleted') {
          final convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          if (_isSameConversation(convId, _conversationId)) {
             add(const CloseChatEvent());
          }
        } else if (type == 'user_status') {
          final userId = (cleanData['user_id'] ?? cleanData['id'] ?? cleanData['sender_id'])?.toString();
          final status = cleanData['status']?.toString();
          debugPrint('DEBUG: Status Match Check - Event User: $userId, Current Recipient: $_recipientId, Status: $status');
          if (userId == _recipientId) {
            add(UpdateUserStatusEvent(
              userId: userId ?? '',
              isOnline: status == 'online',
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
        }
else if (type == 'pong') {
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

    final myId = _storageService.getUserId() ?? '';
    Color? savedColor;
    
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
    } catch (e) {
      debugPrint('Error loading cached messages: $e');
    }

    if (cachedMessages.isNotEmpty) {
      emit(ChatLoaded(
        messages: cachedMessages,
        myId: myId,
        isRecipientOnline: _currentIsOnline,
        isRecipientTyping: _currentIsTyping,
        customBgColor: savedColor,
      ));
    } else {
      emit(const ChatLoading());
    }

    // 2. Fetch fresh messages from API in background
    try {
      final messages = await _chatRepository.getMessages(event.conversationId);
      final pinnedMessages = await _chatRepository.getPinnedMessages(event.conversationId);
      
      // Save fresh messages to cache
      _saveToCache(event.conversationId, messages);

      // Mark unread messages from recipient as read
      for (var msg in messages) {
        if (msg.senderId != myId && !msg.isRead) {
          _socketRepository.sendReadReceipt(msg.conversationId, msg.id);
        }
      }

      final currentState = state;
      if (currentState is ChatLoaded) {
        emit(currentState.copyWith(messages: messages, pinnedMessages: pinnedMessages));
      } else {
        emit(ChatLoaded(
          messages: messages,
          pinnedMessages: pinnedMessages,
          myId: myId,
          isRecipientOnline: _currentIsOnline,
          isRecipientTyping: _currentIsTyping,
          customBgColor: savedColor,
        ));
      }
    } catch (e) {
      if (state is! ChatLoaded) {
        emit(ChatError(errorMessage: e.toString()));
      } else {
        debugPrint('Error reloading messages from API: $e');
      }
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

      final updatedMessages = List<MessageModel>.from(currentState.messages)..add(newMessage);
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
        
        if (newMessage.senderId == currentState.myId && newMessage.senderId.isNotEmpty) {
          debugPrint('DEBUG: Message is from me, updating temp message with real ID');
          final updatedMessages = List<MessageModel>.from(currentState.messages);
          int index = updatedMessages.lastIndexWhere((msg) => msg.id.startsWith('temp_') && msg.content == newMessage.content);
          if (index != -1) {
            updatedMessages[index] = newMessage;
            emit(currentState.copyWith(messages: updatedMessages));
            _saveToCache(_conversationId!, updatedMessages);
          } else {
            int lastTempIndex = updatedMessages.lastIndexWhere((msg) => msg.id.startsWith('temp_'));
            if (lastTempIndex != -1) {
              updatedMessages[lastTempIndex] = newMessage;
              emit(currentState.copyWith(messages: updatedMessages));
              _saveToCache(_conversationId!, updatedMessages);
            }
          }
          return;
        }

        final updatedMessages = List<MessageModel>.from(currentState.messages)..add(newMessage);
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

  void _onToggleMute(ToggleMuteEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded && _conversationId != null) {
      _chatRepository.toggleMute(conversationId: _conversationId!, isMuted: event.isMuted);
      emit(currentState.copyWith(isMuted: event.isMuted));
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
    if (_conversationId != null) {
      _chatRepository.setDisappearingTimer(conversationId: _conversationId!, seconds: event.seconds);
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
      emit(currentState.copyWith(isRecipientOnline: _currentIsOnline));
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
      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == event.messageId) {
          return msg.copyWith(isRead: true);
        }
        return msg;
      }).toList();
      emit(currentState.copyWith(messages: updatedMessages));
      _saveToCache(event.conversationId, updatedMessages);
    }
  }

  void _onDeleteMessages(DeleteMessagesEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final updatedMessages = currentState.messages.map((msg) {
        if (event.messageIds.contains(msg.id)) {
          return msg.copyWith(isDeleted: true, content: 'This message was deleted');
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

      emit(currentState.copyWith(messages: updatedMessages));
      _saveToCache(event.conversationId, updatedMessages);
    }
  }

  void _onEditMessage(EditMessageEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == event.messageId) {
          return msg.copyWith(content: event.newContent, isEdited: true);
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
      } else {
        _socketRepository.unpinMessage(messageId: event.messageId);
      }

      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == event.messageId) {
          return msg.copyWith(isPinned: event.isPinned);
        }
        return msg;
      }).toList();
      emit(currentState.copyWith(messages: updatedMessages));
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
      emit(currentState.copyWith(messages: updatedMessages));
      _saveToCache(event.conversationId, updatedMessages);
    }
  }

  void _onReceiveEditMessage(ReceiveEditMessageEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == event.messageId) {
          return msg.copyWith(content: event.newContent, isEdited: true);
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

  void _saveToCache(String conversationId, List<MessageModel> messages) {
    Hive.openBox('cached_messages').then((box) {
      final serializable = messages.map((m) => m.toJson()).toList();
      box.put(conversationId, serializable);
    }).catchError((e) {
      debugPrint('Error saving to cache: $e');
    });
  }

  @override
  Future<void> close() {
    _socketSubscription?.cancel();
    _typingTimer?.cancel();
    return super.close();
  }
}
