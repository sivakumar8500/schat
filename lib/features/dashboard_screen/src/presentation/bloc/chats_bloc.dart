import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/features/dashboard_screen/src/domain/usecases/get_chats_usecase.dart';
import 'chats_event.dart';
import 'chats_state.dart';

@injectable
class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  final GetChatsUseCase _getChatsUseCase;

  ChatsBloc(this._getChatsUseCase) : super(const ChatsInitial()) {
    on<FetchChats>(_onFetchChats);
  }

  Future<void> _onFetchChats(FetchChats event, Emitter<ChatsState> emit) async {
    emit(const ChatsLoading());
    final result = await _getChatsUseCase.execute();
    result.when(
      success: (chats) => emit(ChatsLoaded(chats)),
      failure: (error) => emit(ChatsError(error)),
    );
  }
}
