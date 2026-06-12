abstract class ProfileEvent {
  const ProfileEvent();
}

class LoadProfileEvent extends ProfileEvent {
  const LoadProfileEvent();
}

class UpdateProfileEvent extends ProfileEvent {
  final String username;
  final String? firstName;
  final String? lastName;
  final String? about;
  final String? imagePath;

  const UpdateProfileEvent({
    required this.username,
    this.firstName,
    this.lastName,
    this.about,
    this.imagePath,
  });
}

class LogoutEvent extends ProfileEvent {
  const LogoutEvent();
}
