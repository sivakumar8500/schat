abstract class ProfileEvent {
  const ProfileEvent();
}

class LoadProfileEvent extends ProfileEvent {
  const LoadProfileEvent();
}

class UpdateProfileEvent extends ProfileEvent {
  final String username;
  final String? imagePath;
  final String? about;

  const UpdateProfileEvent({
    required this.username,
    this.imagePath,
    this.about,
  });
}

class UpdateAboutEvent extends ProfileEvent {
  final String about;

  const UpdateAboutEvent({required this.about});
}

class LogoutEvent extends ProfileEvent {
  const LogoutEvent();
}
