import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/auth_screen/src/domain/repositories/auth_repository.dart';
import 'package:schat/features/profile_screen/src/domain/models/update_profile_request.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/injection.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;
  final AuthRepository _authRepository;

  ProfileBloc({
    ProfileRepository? profileRepository,
    AuthRepository? authRepository,
  })  : _profileRepository = profileRepository ?? getIt<ProfileRepository>(),
        _authRepository = authRepository ?? getIt<AuthRepository>(),
        super(const ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UpdateAboutEvent>(_onUpdateAbout);
    on<LogoutEvent>(_onLogout);
    on<UpdateDefaultDisappearingTimerEvent>(_onUpdateDefaultDisappearingTimer);
  }

  Future<void> _onUpdateAbout(UpdateAboutEvent event, Emitter<ProfileState> emit) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(const ProfileLoading());
      final request = UpdateProfileRequest(
        username: currentState.username,
        about: event.about,
        profilePictureUrl: currentState.imagePath,
      );
      final result = await _profileRepository.updateProfile(request);
      result.when(
        success: (user) => emit(ProfileSuccess(user: user)),
        failure: (message, _) => emit(ProfileFailure(errorMessage: message)),
      );
    }
  }

  Future<void> _onLoadProfile(LoadProfileEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    final result = await _profileRepository.getProfile();
    
    result.when(
      success: (user) {
        emit(ProfileLoaded(
          username: user.username ?? '',
          imagePath: user.profilePictureUrl,
          user: user,
        ));
      },
      failure: (message, statusCode) => emit(ProfileFailure(errorMessage: message)),
    );
  }

  Future<void> _onUpdateProfile(UpdateProfileEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    
    String? profileImageUrl = event.imagePath;

    // Handle media upload
    if (event.fileBytes != null) {
      try {
        final uploadedKey = await _profileRepository.uploadProfilePicture(
          filePath: event.imagePath ?? '',
          fileName: 'profile_pic.png',
          mimeType: 'image/png',
          fileSizeBytes: event.fileBytes!.length,
          fileBytes: event.fileBytes,
        );
        if (uploadedKey != null) {
          profileImageUrl = uploadedKey;
        }
      } catch (e) {
        emit(ProfileFailure(errorMessage: 'Failed to upload profile picture: $e'));
        return;
      }
    } else if (event.imagePath != null && 
               !event.imagePath!.startsWith('http') && 
               !event.imagePath!.startsWith('https') &&
               !event.imagePath!.startsWith('blob:') &&
               !kIsWeb) {
      try {
        final file = File(event.imagePath!);
        if (await file.exists()) {
          final fileName = file.path.split('/').last;
          final fileSize = await file.length();
          // Simple mime type detection for images
          String mimeType = 'image/jpeg';
          if (fileName.toLowerCase().endsWith('.png')) mimeType = 'image/png';
          if (fileName.toLowerCase().endsWith('.gif')) mimeType = 'image/gif';
          if (fileName.toLowerCase().endsWith('.webp')) mimeType = 'image/webp';

          final uploadedKey = await _profileRepository.uploadProfilePicture(
            filePath: file.path,
            fileName: fileName,
            mimeType: mimeType,
            fileSizeBytes: fileSize,
          );
          
          if (uploadedKey != null) {
            profileImageUrl = uploadedKey;
          }
        }
      } catch (e) {
        emit(ProfileFailure(errorMessage: 'Failed to upload profile picture: $e'));
        return;
      }
    }
    final request = UpdateProfileRequest(
      username: event.username.trim(),
      firstName: null,
      lastName: null,
      about: event.about ?? "",
      profilePictureUrl: profileImageUrl,
    );

    final result = await _profileRepository.updateProfile(request);
    
    result.when(
      success: (user) {
        emit(ProfileSuccess(user: user));
      },
      failure: (message, statusCode) => emit(ProfileFailure(errorMessage: message)),
    );
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    try {
      await _authRepository.logout();
      emit(const ProfileLogoutSuccess());
    } catch (e) {
      emit(ProfileFailure(errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateDefaultDisappearingTimer(
    UpdateDefaultDisappearingTimerEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(const ProfileLoading());
      final request = UpdateProfileRequest(
        defaultDisappearingTimer: event.seconds,
      );
      final result = await _profileRepository.updateProfile(request);
      result.when(
        success: (user) => emit(ProfileSuccess(user: user)),
        failure: (message, _) => emit(ProfileFailure(errorMessage: message)),
      );
    }
  }
}
