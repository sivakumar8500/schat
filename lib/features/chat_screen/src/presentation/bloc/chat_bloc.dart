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

    _listenToSocket();
  }

  void _listenToSocket() {
    _socketSubscription = _socketRepository.onMessage.listen((data) {
      debugPrint('DEBUG: ChatBloc RECEIVED DATA: $data');
      
      if (data is Map) {
        final type = data['type']?.toString();
        
        if (type == 'new_message') {
          final message = data['message'] as Map<String, dynamic>?;
          if (message != null && (message['conversation_id']?.toString() == _conversationId || message['conversation']?.toString() == _conversationId)) {
            add(ReceiveMessageEvent(messageData: message));
          }
        } else if (type == 'typing') {
          final convId = data['conversation_id']?.toString();
          debugPrint('DEBUG: Typing check - Event Conv: $convId, Current Conv: $_conversationId');
          if (convId == _conversationId) {
            add(UpdateTypingIndicatorEvent(
              conversationId: convId ?? '',
              isTyping: true,
            ));
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
    if (currentState is ChatLoaded) {
      try {
        final newMessage = MessageModel.fromJson(event.messageData);
        
        if (newMessage.senderId == currentState.myId) {
          return;
        }

        final updatedMessages = List<MessageModel>.from(currentState.messages)..add(newMessage);
        _currentIsTyping = false;
        emit(currentState.copyWith(
          messages: updatedMessages,
          isRecipientTyping: false,
        ));
        _typingTimer?.cancel();
      } catch (e) {
        debugPrint('Error parsing incoming message: $e');
      }
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

  @override
  Future<void> close() {
    _socketSubscription?.cancel();
    _typingTimer?.cancel();
    return super.close();
  }
}
