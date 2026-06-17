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
    on<LogoutEvent>(_onLogout);
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
    
    final request = UpdateProfileRequest(
      username: event.username,
      firstName: event.firstName,
      lastName: event.lastName,
      about: event.about,
      profilePictureUrl: event.imagePath,
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
}
