import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/injection.dart';
import 'chat_event.dart';
import 'chat_state.dart';

// Fixed ChatBloc to clear errors
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final StorageService _storageService;

  ChatBloc({ChatRepository? chatRepository, StorageService? storageService})
      : _chatRepository = chatRepository ?? getIt<ChatRepository>(),
        _storageService = storageService ?? getIt<StorageService>(),
        super(const ChatInitial()) {
    on<LoadMessagesEvent>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<ReceiveMessageEvent>(_onReceiveMessage);
    on<ToggleMuteEvent>(_onToggleMute);
    on<ToggleLockEvent>(_onToggleLock);
  }

  Future<void> _onLoadMessages(LoadMessagesEvent event, Emitter<ChatState> emit) async {
    emit(const ChatLoading());
    try {
      final myId = await _storageService.getUserId() ?? '';
      final messages = await _chatRepository.getMessages(event.conversationId);
      emit(ChatLoaded(messages: messages, myId: myId));
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
      emit(ChatLoaded(
        messages: updatedMessages,
        isMuted: currentState.isMuted,
        isLocked: currentState.isLocked,
        myId: currentState.myId,
      ));
    }
  }

  void _onReceiveMessage(ReceiveMessageEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      try {
        final newMessage = MessageModel.fromJson(event.messageData);
        
        // Filter out echoed messages sent by me
        if (newMessage.senderId == currentState.myId) {
          // Optional: You could update the temporary optimistic message with the real one from server here
          return;
        }

        final updatedMessages = List<MessageModel>.from(currentState.messages)..add(newMessage);
        emit(ChatLoaded(
          messages: updatedMessages,
          isMuted: currentState.isMuted,
          isLocked: currentState.isLocked,
          myId: currentState.myId,
        ));
      } catch (e) {
        // Handle parse error
      }
    }
  }

  void _onToggleMute(ToggleMuteEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(ChatLoaded(
        messages: currentState.messages,
        isMuted: event.isMuted,
        isLocked: currentState.isLocked,
        myId: currentState.myId,
      ));
    }
  }

  void _onToggleLock(ToggleLockEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(ChatLoaded(
        messages: currentState.messages,
        isMuted: currentState.isMuted,
        isLocked: event.isLocked,
        myId: currentState.myId,
      ));
    }
  }
}
