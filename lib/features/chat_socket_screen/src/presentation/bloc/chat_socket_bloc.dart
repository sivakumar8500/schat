import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/features/chat_socket_screen/src/domain/usecases/connect_socket_usecase.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'chat_socket_event.dart';
import 'chat_socket_state.dart';

@injectable
class ChatSocketBloc extends Bloc<ChatSocketEvent, ChatSocketState> {
  final ConnectSocketUseCase _connectSocketUseCase;
  final ChatSocketRepository _repository;
  StreamSubscription? _messageSubscription;

  ChatSocketBloc(this._connectSocketUseCase, this._repository) : super(ChatSocketInitial()) {
    on<ConnectSocket>(_onConnectSocket);
    on<DisconnectSocket>(_onDisconnectSocket);
    on<SendMessage>(_onSendMessage);
    on<SendTypingIndicator>(_onSendTypingIndicator);
    on<SendReadReceipt>(_onSendReadReceipt);
    
    _messageSubscription = _repository.onMessage.listen((data) {
      // Handle incoming messages/events here if needed to update state
      // For example, if data['type'] == 'new_message', we could emit a state
      // but usually chat UI listens to the repository stream directly or via a different Bloc
    });
  }

  void _onConnectSocket(ConnectSocket event, Emitter<ChatSocketState> emit) {
    debugPrint('DEBUG: ChatSocketBloc received ConnectSocket event');
    emit(ChatSocketConnecting());
    _connectSocketUseCase.execute();
    emit(ChatSocketConnected());
  }

  void _onDisconnectSocket(DisconnectSocket event, Emitter<ChatSocketState> emit) {
    _repository.disconnect();
    emit(ChatSocketDisconnected());
  }

  void _onSendMessage(SendMessage event, Emitter<ChatSocketState> emit) {
    _repository.sendMessage(
      conversationId: event.conversationId,
      type: event.type,
      text: event.text,
      fileKey: event.fileKey,
      thumbnail: event.thumbnail,
      fileName: event.fileName,
      fileSize: event.fileSize,
      mimeType: event.mimeType,
      duration: event.duration,
      replyMessageId: event.replyMessageId,
      security: event.security,
      viewControl: event.viewControl,
      expiry: event.expiry,
      callMeta: event.callMeta,
    );
  }

  void _onSendTypingIndicator(SendTypingIndicator event, Emitter<ChatSocketState> emit) {
    _repository.sendTypingIndicator(event.conversationId, isTyping: event.isTyping);
  }

  void _onSendReadReceipt(SendReadReceipt event, Emitter<ChatSocketState> emit) {
    _repository.sendReadReceipt(event.conversationId, event.messageId);
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _repository.disconnect();
    return super.close();
  }
}
