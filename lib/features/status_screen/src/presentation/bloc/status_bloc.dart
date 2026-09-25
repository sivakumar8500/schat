import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/features/status_screen/src/domain/repositories/status_repository.dart';
import 'package:schat/features/status_screen/src/domain/status_model.dart';
import 'package:schat/injection.dart';
import 'status_event.dart';
import 'status_state.dart';

class StatusBloc extends Bloc<StatusEvent, StatusState> {
  final StatusRepository _repository;
  final ChatSocketRepository _socketRepository;
  StreamSubscription? _socketSubscription;

  StatusBloc({
    StatusRepository? repository,
    ChatSocketRepository? socketRepository,
  })  : _repository = repository ?? getIt<StatusRepository>(),
        _socketRepository = socketRepository ?? getIt<ChatSocketRepository>(),
        super(const StatusInitial()) {
    on<LoadStatusUpdatesEvent>(_onLoadStatusUpdates);
    on<UploadTextStatusEvent>(_onUploadTextStatus);
    on<UploadMediaStatusEvent>(_onUploadMediaStatus);
    on<MuteContactEvent>(_onMuteContact);
    on<DeleteMyStatusEvent>(_onDeleteMyStatus);
    on<FetchStatusPrivacyEvent>(_onFetchStatusPrivacy);
    on<UpdateStatusPrivacyEvent>(_onUpdateStatusPrivacy);

    _listenToSocket();
  }

  void _listenToSocket() {
    _socketSubscription = _socketRepository.onMessage.listen((data) {
      if (data is Map) {
        final type = data['type']?.toString();
        if (type == 'status_created' ||
            type == 'status_deleted' ||
            type == 'status_viewed' ||
            type == 'status_update') {
          add(const LoadStatusUpdatesEvent());
        }
      }
    });
  }

  @override
  Future<void> close() {
    _socketSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadStatusUpdates(LoadStatusUpdatesEvent event, Emitter<StatusState> emit) async {
    final currentState = state;
    if (currentState is! StatusLoaded) {
      emit(const StatusLoading());
    }
    try {
      final results = await Future.wait([
        _repository.getRecentUpdates(),
        _repository.getMyStatuses(),
        _repository.getMutedUpdates(),
        _repository.getStatusPrivacy(),
      ]);

      final recent = results[0] as List<StatusContactModel>;
      final myStatuses = results[1] as List<StatusItemModel>;
      final muted = results[2] as List<StatusContactModel>;
      final privacy = results[3] as StatusPrivacyModel;

      String? myText;
      String? myPath;
      DateTime? myTime;
      if (myStatuses.isNotEmpty) {
        final latest = myStatuses.first;
        myText = latest.text;
        myPath = latest.imagePath;
        myTime = latest.timestamp;
      }

      if (currentState is StatusLoaded) {
        emit(currentState.copyWith(
          recentUpdates: recent,
          mutedUpdates: muted,
          myStatuses: myStatuses,
          myStatusText: () => myText,
          myStatusPath: () => myPath,
          myStatusTime: () => myTime,
          privacyModel: privacy,
        ));
      } else {
        emit(StatusLoaded(
          recentUpdates: recent,
          mutedUpdates: muted,
          myStatuses: myStatuses,
          myStatusText: myText,
          myStatusPath: myPath,
          myStatusTime: myTime,
          privacyModel: privacy,
        ));
      }
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
        textColor: event.textColor,
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
    emit(const StatusLoading());
    try {
      await _repository.deleteStatus(event.statusId);
      add(const LoadStatusUpdatesEvent());
    } catch (e) {
      emit(StatusFailure(errorMessage: e.toString()));
    }
  }

  Future<void> _onFetchStatusPrivacy(FetchStatusPrivacyEvent event, Emitter<StatusState> emit) async {
    try {
      final privacy = await _repository.getStatusPrivacy();
      final currentState = state;
      if (currentState is StatusLoaded) {
        emit(currentState.copyWith(privacyModel: privacy));
      }
    } catch (_) {}
  }

  Future<void> _onUpdateStatusPrivacy(UpdateStatusPrivacyEvent event, Emitter<StatusState> emit) async {
    try {
      await _repository.updateStatusPrivacy(
        privacyType: event.privacyType,
        includedUserIds: event.includedUserIds,
        excludedUserIds: event.excludedUserIds,
      );
      final privacy = await _repository.getStatusPrivacy();
      final currentState = state;
      if (currentState is StatusLoaded) {
        emit(currentState.copyWith(privacyModel: privacy));
      }
    } catch (e) {
      emit(StatusFailure(errorMessage: e.toString()));
    }
  }
}

