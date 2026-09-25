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
    if (currentState is! StatusLoaded) {
      emit(const StatusLoading());
    }
    try {
      final recent = await _repository.getRecentUpdates();
      final muted = await _repository.getMutedUpdates();
      final myStatuses = await _repository.getMyStatuses();

      String? myText;
      String? myPath;
      DateTime? myTime;
      if (myStatuses.isNotEmpty) {
        final latest = myStatuses.first;
        myText = latest.text;
        myPath = latest.imagePath;
        myTime = latest.timestamp;
      }

      emit(StatusLoaded(
        recentUpdates: recent,
        mutedUpdates: muted,
        myStatusText: myText,
        myStatusPath: myPath,
        myStatusTime: myTime,
      ));
    } catch (e) {
      if (currentState is StatusLoaded) {
        emit(currentState);
      } else {
        emit(StatusFailure(errorMessage: e.toString()));
      }
    }
  }

  Future<void> _onUploadTextStatus(UploadTextStatusEvent event, Emitter<StatusState> emit) async {
    try {
      await _repository.createStatus(
        statusType: 'text',
        textContent: event.text,
        privacyType: event.privacyType,
        privacyUserIds: event.privacyUserIds,
      );
    } catch (e) {
      // Log and continue to reload
    }
    add(const LoadStatusUpdatesEvent());
  }

  Future<void> _onUploadMediaStatus(UploadMediaStatusEvent event, Emitter<StatusState> emit) async {
    try {
      await _repository.createStatus(
        statusType: event.path != null && event.path!.endsWith('.mp4') ? 'video' : 'image',
        textContent: event.caption,
        filePath: event.path,
        fileBytes: event.bytes,
        fileName: event.path != null ? event.path!.split('/').last : 'media.jpg',
        mimeType: event.path != null && event.path!.endsWith('.mp4') ? 'video/mp4' : 'image/jpeg',
        fileSizeBytes: event.bytes?.length ?? 1024,
        privacyType: event.privacyType,
        privacyUserIds: event.privacyUserIds,
      );
    } catch (e) {
      // Log and continue to reload
    }
    add(const LoadStatusUpdatesEvent());
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

  Future<void> _onDeleteMyStatus(DeleteMyStatusEvent event, Emitter<StatusState> emit) async {
    // We would need a status ID to delete from backend, for now this is just placeholder.
    // If we have myStatuses list, we should delete a specific one.
    // The current UI logic may need changes to support multiple my-statuses.
    emit(const StatusLoading());
    try {
      final myStatuses = await _repository.getMyStatuses();
      if (myStatuses.isNotEmpty) {
        await _repository.deleteStatus(myStatuses.first.id);
      }
      add(const LoadStatusUpdatesEvent());
    } catch (e) {
      emit(StatusFailure(errorMessage: e.toString()));
    }
  }
}
