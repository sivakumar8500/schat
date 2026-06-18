import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

    _listenToSocket();
  }

  bool _isSameConversation(dynamic id1, dynamic id2) {
    if (id1 == null || id2 == null) return false;
    final s1 = id1.toString().replaceAll('-', '').toLowerCase().trim();
    final s2 = id2.toString().replaceAll('-', '').toLowerCase().trim();
    return s1 == s2;
  }

  void _listenToSocket() {
    _socketSubscription = _socketRepository.onMessage.listen((data) {
      debugPrint('DEBUG: ChatBloc RECEIVED DATA: $data');
      
      if (data is Map) {
        final type = data['type']?.toString();
        
        if (type == 'new_message' || type == 'message') {
          final message = data['message'] ?? (data.containsKey('id') ? data : null);
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
          final convId = (data['conversationId'] ?? data['conversation_id'])?.toString();
          final isTypingField = data['is_typing'] ?? data['isTyping'];
          final isTyping = isTypingField is bool ? isTypingField : true;
          
          if (_isSameConversation(convId, _conversationId)) {
            add(UpdateTypingIndicatorEvent(
              conversationId: convId ?? '',
              isTyping: isTyping,
            ));
          }
        } else if (type == 'message_read' || type == 'read_receipt' || type == 'message_opened') {
          final convId = (data['conversationId'] ?? data['conversation_id'])?.toString();
          final msgId = (data['messageId'] ?? data['message_id'] ?? data['id'])?.toString();
          if (_isSameConversation(convId, _conversationId) && msgId != null) {
            add(MarkMessageReadEvent(messageId: msgId, conversationId: convId!));
          }
        } else if (type == 'user_status') {
          final userId = (data['user_id'] ?? data['id'] ?? data['sender_id'])?.toString();
          final status = data['status']?.toString();
          debugPrint('DEBUG: Status Match Check - Event User: $userId, Current Recipient: $_recipientId, Status: $status');
          if (userId == _recipientId) {
            add(UpdateUserStatusEvent(
              userId: userId ?? '',
              isOnline: status == 'online',
            ));
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

    emit(const ChatLoading());
    try {
      final myId = _storageService.getUserId() ?? '';
      final messages = await _chatRepository.getMessages(event.conversationId);
      
      // Mark unread messages from recipient as read
      for (var msg in messages) {
        if (msg.senderId != myId && !msg.isRead) {
          _socketRepository.sendReadReceipt(msg.conversationId, msg.id);
        }
      }

      emit(ChatLoaded(
        messages: messages,
        myId: myId,
        isRecipientOnline: _currentIsOnline,
        isRecipientTyping: _currentIsTyping,
      ));
    } catch (e) {
      emit(ChatError(errorMessage: e.toString()));
    }
  }

  Future<void> _onSendMessage(SendMessageEvent event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final String now = DateTime.now().toIso8601String();
      final newMessage = MessageModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: event.conversationId,
        senderId: currentState.myId,
        content: event.text,
        mediaUrl: event.attachmentPath,
        mediaType: event.type,
        isDeleted: false,
        createdAt: now,
        updatedAt: now,
      );

      final updatedMessages = List<MessageModel>.from(currentState.messages)..add(newMessage);
      emit(currentState.copyWith(messages: updatedMessages));
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
          debugPrint('DEBUG: Message ignored because senderId matches myId');
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
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith(isMuted: event.isMuted));
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
    }
  }

  @override
  Future<void> close() {
    _socketSubscription?.cancel();
    _typingTimer?.cancel();
    return super.close();
  }
}
