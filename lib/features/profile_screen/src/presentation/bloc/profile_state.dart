import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';

abstract class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final String username;
  final String? imagePath;
  final UserModel? user;

  const ProfileLoaded({required this.username, this.imagePath, this.user});
}

class ProfileSuccess extends ProfileState {
  const ProfileSuccess();
}

class ProfileFailure extends ProfileState {
  final String errorMessage;

  const ProfileFailure({required this.errorMessage});
}

class ProfileLogoutSuccess extends ProfileState {
  const ProfileLogoutSuccess();
}
