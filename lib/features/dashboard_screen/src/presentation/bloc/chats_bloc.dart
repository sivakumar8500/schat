import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/features/dashboard_screen/src/domain/usecases/get_chats_usecase.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/contacts_repository.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/last_message_model.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'chats_event.dart';
import 'chats_state.dart';

@lazySingleton
class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  final GetChatsUseCase _getChatsUseCase;
  final DashboardRepository _chatRepository;
  final ContactsRepository _contactsRepository;
  final ChatSocketRepository _socketRepository;
  final StorageService _storageService;
  StreamSubscription? _socketSubscription;

  ChatsBloc(
    this._getChatsUseCase,
    this._chatRepository,
    this._contactsRepository,
    this._socketRepository,
    this._storageService,
  ) : super(const ChatsInitial()) {
    on<FetchChats>(_onFetchChats);
    on<CreateChat>(_onCreateChat);
    on<UpdateUserStatus>(_onUpdateUserStatus);
    on<NewMessageReceived>(_onNewMessageReceived);
    on<MessageEdited>(_onMessageEdited);
    on<RemoveChat>(_onRemoveChat);

    _listenToSocket();
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
      if (data == null) return;
      
      try {
        final Map mapData = data is Map ? data : {};
        if (mapData.isEmpty) return;
        
        final cleanData = _cleanMap(Map<dynamic, dynamic>.from(mapData));
        final type = cleanData['type']?.toString();
        
        if (type == 'user_status') {
          final userId = (cleanData['user_id'] ?? cleanData['id'] ?? cleanData['sender_id'])
              ?.toString();
          final status = cleanData['status']?.toString();
          if (userId != null) {
            add(UpdateUserStatus(userId: userId, isOnline: status == 'online'));
          }
        } else if (type == 'new_message' || type == 'message') {
          final message = cleanData['message'] ?? (cleanData.containsKey('id') ? cleanData : null);
          if (message is Map) {
            final convId = (message['conversationId'] ?? message['conversation_id'])?.toString();
            final updatedAt = (message['updatedAt'] ?? message['created_at'])?.toString();
            final unreadCount = int.tryParse(cleanData['unread_count']?.toString() ?? '') ?? 
                                int.tryParse(cleanData['unread']?.toString() ?? '');
            if (convId != null) {
              add(NewMessageReceived(
                conversationId: convId,
                lastMessage: LastMessageModel.fromJson(Map<String, dynamic>.from(message)),
                updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
                unreadCount: unreadCount,
              ));
            }
          }
        } else if (type == 'message_edited' || type == 'edit_message') {
          final message = cleanData['message'];
          if (message is Map) {
            final convId = (message['conversationId'] ?? message['conversation_id'])?.toString();
            if (convId != null) {
              add(MessageEdited(
                conversationId: convId,
                message: LastMessageModel.fromJson(Map<String, dynamic>.from(message)),
              ));
            }
          }
        } else if (type == 'conversation_deleted') {
          final convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          if (convId != null) {
            add(RemoveChat(conversationId: convId));
          }
        } else if (type == 'participant_left') {
           // If myId left, remove chat. If someone else left and it's a group, maybe update participant count.
           // For now, if we receive participant_left for a 1-on-1, it's basically conversation_deleted.
           final convId = (cleanData['conversation_id'] ?? cleanData['conversationId'])?.toString();
           if (convId != null) {
              // Check if it's 1-on-1 and other user left
              add(RemoveChat(conversationId: convId));
           }
        }
      } catch (e) {
        // Log error
      }
    });
  }

  Future<void> _onFetchChats(FetchChats event, Emitter<ChatsState> emit) async {
    emit(const ChatsLoading());
    final result = await _getChatsUseCase.execute();
    result.when(
      success: (chats) {
        // Sort by updatedAt descending
        final sortedChats = List<ChatModel>.from(chats)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        emit(ChatsLoaded(sortedChats));
      },
      failure: (error, statusCode) => emit(ChatsError(error)),
    );
  }

  void _onNewMessageReceived(NewMessageReceived event, Emitter<ChatsState> emit) {
    final currentState = state;
    if (currentState is ChatsLoaded) {
      final List<ChatModel> updatedChats = List<ChatModel>.from(currentState.chats);
      final index = updatedChats.indexWhere((c) => c.id == event.conversationId);
      final currentUserId = _storageService.getUserId();
      
      if (index != -1) {
        final chat = updatedChats.removeAt(index);
        final isFromMe = event.lastMessage.senderId == currentUserId;
        
        int newUnreadCount = event.unreadCount ?? chat.unreadCount;
        if (event.unreadCount == null && !isFromMe) {
          newUnreadCount = chat.unreadCount + 1;
        } else if (isFromMe) {
          newUnreadCount = 0; // If I sent a message, I've seen it or it's my turn
        }

        final updatedChat = chat.copyWith(
          lastMessage: event.lastMessage,
          updatedAt: event.updatedAt,
          unreadCount: newUnreadCount,
        );
        updatedChats.insert(0, updatedChat);
        emit(ChatsLoaded(updatedChats));
      } else {
        add(const FetchChats());
      }
    }
  }

  void _onMessageEdited(MessageEdited event, Emitter<ChatsState> emit) {
    final currentState = state;
    if (currentState is ChatsLoaded) {
      final List<ChatModel> updatedChats = currentState.chats.map((chat) {
        if (chat.id == event.conversationId && chat.lastMessage?.id == event.message.id) {
          return chat.copyWith(lastMessage: event.message);
        }
        return chat;
      }).toList();
      emit(ChatsLoaded(updatedChats));
    }
  }

  void _onRemoveChat(RemoveChat event, Emitter<ChatsState> emit) {
    final currentState = state;
    if (currentState is ChatsLoaded) {
      final List<ChatModel> updatedChats = currentState.chats
          .where((c) => c.id != event.conversationId)
          .toList();
      emit(ChatsLoaded(updatedChats));
    }
  }

  void _onUpdateUserStatus(UpdateUserStatus event, Emitter<ChatsState> emit) {
    final currentState = state;
    if (currentState is ChatsLoaded) {
       final List<ChatModel> updatedChats = currentState.chats.map((chat) {
        if (!chat.isGroup && chat.recipient.id == event.userId) {
          final updatedRecipient = chat.recipient.copyWith(
            isOnline: event.isOnline,
          );
          return chat.copyWith(recipient: updatedRecipient);
        }
        return chat;
      }).toList();
      emit(ChatsLoaded(updatedChats));
    }
  }

  Future<void> _onCreateChat(CreateChat event, Emitter<ChatsState> emit) async {
    emit(const ChatsLoading());
    final result = await _chatRepository.startDirectChat(event.participantId);

    await result.when(
      success: (chat) async {
        await _contactsRepository.removeContactFromCache(event.participantId);
        emit(
          ChatCreated(
            chat,
            event.contactName,
            profilePictureUrl: event.profilePictureUrl,
          ),
        );
      },
      failure: (error, statusCode) {
        emit(ChatsError(error));
      },
    );
  }

  @override
  Future<void> close() {
    _socketSubscription?.cancel();
    return super.close();
  }
}
