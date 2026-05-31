import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/injection.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;

  ChatBloc({ChatRepository? chatRepository})
      : _chatRepository = chatRepository ?? getIt<ChatRepository>(),
        super(const ChatInitial()) {
    on<LoadMessagesEvent>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<ToggleMuteEvent>(_onToggleMute);
    on<ToggleLockEvent>(_onToggleLock);
  }

  Future<void> _onLoadMessages(LoadMessagesEvent event, Emitter<ChatState> emit) async {
    emit(const ChatLoading());
    try {
      final messages = await _chatRepository.getMessages(event.contactName);
      emit(ChatLoaded(messages: messages));
    } catch (e) {
      emit(ChatError(errorMessage: e.toString()));
    }
  }

  Future<void> _onSendMessage(SendMessageEvent event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final newMessage = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: event.text,
        time: 'Just now',
        isMe: true,
        isRead: false,
        type: event.type,
        attachmentPath: event.attachmentPath,
        attachmentName: event.attachmentName,
        attachmentBytes: event.attachmentBytes,
      );

      final updatedMessages = List<MessageModel>.from(currentState.messages)..add(newMessage);
      emit(ChatLoaded(
        messages: updatedMessages,
        isMuted: currentState.isMuted,
        isLocked: currentState.isLocked,
      ));

      try {
        await _chatRepository.sendMessage(newMessage);
      } catch (e) {
        emit(ChatError(errorMessage: e.toString()));
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
      ));
    }
  }
}
