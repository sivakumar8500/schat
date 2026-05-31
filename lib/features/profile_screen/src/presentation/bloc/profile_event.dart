abstract class ProfileEvent {
  const ProfileEvent();
}

class LoadProfileEvent extends ProfileEvent {
  const LoadProfileEvent();
}

class UpdateProfileEvent extends ProfileEvent {
  final String username;
  final String? imagePath;

  const UpdateProfileEvent({required this.username, this.imagePath});
}
