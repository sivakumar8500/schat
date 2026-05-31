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

  const ProfileLoaded({required this.username, this.imagePath});
}

class ProfileSuccess extends ProfileState {
  const ProfileSuccess();
}

class ProfileFailure extends ProfileState {
  final String errorMessage;

  const ProfileFailure({required this.errorMessage});
}
