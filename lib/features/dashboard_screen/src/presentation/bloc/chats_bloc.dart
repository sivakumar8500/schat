import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/features/dashboard_screen/src/domain/usecases/get_chats_usecase.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/contacts_repository.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/chat_model.dart';
import 'chats_event.dart';
import 'chats_state.dart';

@lazySingleton
class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  final GetChatsUseCase _getChatsUseCase;
  final DashboardRepository _chatRepository;
  final ContactsRepository _contactsRepository;
  final ChatSocketRepository _socketRepository;
  StreamSubscription? _socketSubscription;

  ChatsBloc(
    this._getChatsUseCase,
    this._chatRepository,
    this._contactsRepository,
    this._socketRepository,
  ) : super(const ChatsInitial()) {
    on<FetchChats>(_onFetchChats);
    on<CreateChat>(_onCreateChat);
    on<UpdateUserStatus>(_onUpdateUserStatus);

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
      if (data is Map) {
        final cleanData = _cleanMap(data);
        final type = cleanData['type']?.toString();
        if (type == 'user_status') {
          final userId = (cleanData['user_id'] ?? cleanData['id'] ?? cleanData['sender_id'])
              ?.toString();
          final status = cleanData['status']?.toString();
          if (userId != null) {
            add(UpdateUserStatus(userId: userId, isOnline: status == 'online'));
          }
        }
      }
    });
  }

  Future<void> _onFetchChats(FetchChats event, Emitter<ChatsState> emit) async {
    emit(const ChatsLoading());
    final result = await _getChatsUseCase.execute();
    result.when(
      success: (chats) => emit(ChatsLoaded(chats)),
      failure: (error, statusCode) => emit(ChatsError(error)),
    );
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
