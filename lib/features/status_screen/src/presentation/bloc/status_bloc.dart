import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/status_screen/src/domain/repositories/status_repository.dart';
import 'package:schat/injection.dart';
import 'status_event.dart';
import 'status_state.dart';

class StatusBloc extends Bloc<StatusEvent, StatusState> {
  final StatusRepository _repository;

  StatusBloc({StatusRepository? repository})
      : _repository = repository ?? getIt<StatusRepository>(),
        super(const StatusInitial()) {
    on<LoadStatusUpdatesEvent>(_onLoadStatusUpdates);
    on<UploadTextStatusEvent>(_onUploadTextStatus);
    on<UploadMediaStatusEvent>(_onUploadMediaStatus);
    on<MuteContactEvent>(_onMuteContact);
    on<DeleteMyStatusEvent>(_onDeleteMyStatus);
  }

  Future<void> _onLoadStatusUpdates(LoadStatusUpdatesEvent event, Emitter<StatusState> emit) async {
    final currentState = state;
    emit(const StatusLoading());
    try {
      final recent = await _repository.getRecentUpdates();
      final muted = await _repository.getMutedUpdates();
      
      if (currentState is StatusLoaded) {
        emit(currentState.copyWith(
          recentUpdates: recent,
          mutedUpdates: muted,
        ));
      } else {
        emit(StatusLoaded(
          recentUpdates: recent,
          mutedUpdates: muted,
        ));
      }
    } catch (e) {
      emit(StatusFailure(errorMessage: e.toString()));
    }
  }

  void _onUploadTextStatus(UploadTextStatusEvent event, Emitter<StatusState> emit) {
    final currentState = state;
    if (currentState is StatusLoaded) {
      emit(currentState.copyWith(
        myStatusText: () => event.text,
        myStatusBytes: () => null,
        myStatusPath: () => null,
        myStatusTime: () => DateTime.now(),
      ));
    } else {
      emit(StatusLoaded(
        recentUpdates: const [],
        mutedUpdates: const [],
        myStatusText: event.text,
        myStatusTime: DateTime.now(),
      ));
    }
  }

  void _onUploadMediaStatus(UploadMediaStatusEvent event, Emitter<StatusState> emit) {
    final currentState = state;
    if (currentState is StatusLoaded) {
      emit(currentState.copyWith(
        myStatusText: () => event.caption,
        myStatusBytes: () => event.bytes,
        myStatusPath: () => event.path,
        myStatusTime: () => DateTime.now(),
      ));
    } else {
      emit(StatusLoaded(
        recentUpdates: const [],
        mutedUpdates: const [],
        myStatusText: event.caption,
        myStatusBytes: event.bytes,
        myStatusPath: event.path,
        myStatusTime: DateTime.now(),
      ));
    }
  }

  Future<void> _onMuteContact(MuteContactEvent event, Emitter<StatusState> emit) async {
    try {
      await _repository.muteContact(event.contactId, event.mute);
      // Reload updates
      final recent = await _repository.getRecentUpdates();
      final muted = await _repository.getMutedUpdates();
      final currentState = state;
      if (currentState is StatusLoaded) {
        emit(currentState.copyWith(
          recentUpdates: recent,
          mutedUpdates: muted,
        ));
      } else {
        emit(StatusLoaded(
          recentUpdates: recent,
          mutedUpdates: muted,
        ));
      }
    } catch (e) {
      emit(StatusFailure(errorMessage: e.toString()));
    }
  }

  void _onDeleteMyStatus(DeleteMyStatusEvent event, Emitter<StatusState> emit) {
    final currentState = state;
    if (currentState is StatusLoaded) {
      emit(currentState.copyWith(
        myStatusText: () => null,
        myStatusBytes: () => null,
        myStatusPath: () => null,
        myStatusTime: () => null,
      ));
    }
  }
}
