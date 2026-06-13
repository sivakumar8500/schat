import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/features/dashboard_screen/src/domain/usecases/get_chats_usecase.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/contacts_repository.dart';
import 'package:schat/core/network/api_result.dart';
import 'chats_event.dart';
import 'chats_state.dart';

@lazySingleton
class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  final GetChatsUseCase _getChatsUseCase;
  final ChatRepository _chatRepository;
  final ContactsRepository _contactsRepository;

  ChatsBloc(
    this._getChatsUseCase,
    this._chatRepository,
    this._contactsRepository,
  ) : super(const ChatsInitial()) {
    on<FetchChats>(_onFetchChats);
    on<CreateChat>(_onCreateChat);
  }

  Future<void> _onFetchChats(FetchChats event, Emitter<ChatsState> emit) async {
    emit(const ChatsLoading());
    final result = await _getChatsUseCase.execute();
    result.when(
      success: (chats) => emit(ChatsLoaded(chats)),
      failure: (error) => emit(ChatsError(error)),
    );
  }

  Future<void> _onCreateChat(CreateChat event, Emitter<ChatsState> emit) async {
    emit(const ChatsLoading());
    final result = await _chatRepository.createChat(
      isGroup: false,
      participantIds: [event.participantId],
    );

    await result.when(
      success: (chat) async {
        await _contactsRepository.removeContactFromCache(event.participantId);
        emit(ChatsState.chatCreated(chat, event.contactName));
      },
      failure: (error) {
        emit(ChatsError(error));
      },
    );
  }
}
