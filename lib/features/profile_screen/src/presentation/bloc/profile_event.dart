import 'dart:typed_data';

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
  final Uint8List? fileBytes;

  const UpdateProfileEvent({
    required this.username,
    this.imagePath,
    this.about,
    this.fileBytes,
  });
}

class UpdateAboutEvent extends ProfileEvent {
  final String about;

  const UpdateAboutEvent({required this.about});
}

class LogoutEvent extends ProfileEvent {
  const LogoutEvent();
}
