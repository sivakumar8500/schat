import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/injection.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileBloc({ProfileRepository? profileRepository})
      : _profileRepository = profileRepository ?? getIt<ProfileRepository>(),
        super(const ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
  }

  Future<void> _onLoadProfile(LoadProfileEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? '';
      final imagePath = prefs.getString('profile_pic_path');
      emit(ProfileLoaded(username: username, imagePath: imagePath));
    } catch (e) {
      emit(ProfileFailure(errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateProfile(UpdateProfileEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    final username = event.username.trim();
    if (username.isEmpty) {
      emit(const ProfileFailure(errorMessage: 'Please enter a username.'));
      return;
    }

    try {
      File? imageFile;
      if (event.imagePath != null) {
        imageFile = File(event.imagePath!);
      }
      final success = await _profileRepository.updateProfile(username, imageFile);
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAuthenticated', true);
        await prefs.setString('username', username);
        if (event.imagePath != null) {
          await prefs.setString('profile_pic_path', event.imagePath!);
        }
        emit(const ProfileSuccess());
      } else {
        emit(const ProfileFailure(errorMessage: 'Failed to update profile. Please try again.'));
      }
    } catch (e) {
      emit(ProfileFailure(errorMessage: e.toString()));
    }
  }
}
