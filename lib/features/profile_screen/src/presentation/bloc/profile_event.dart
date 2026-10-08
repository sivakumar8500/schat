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
  final String? category;
  final Uint8List? fileBytes;

  const UpdateProfileEvent({
    required this.username,
    this.imagePath,
    this.about,
    this.category,
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

class UpdateDefaultDisappearingTimerEvent extends ProfileEvent {
  final int? seconds;

  const UpdateDefaultDisappearingTimerEvent({this.seconds});
}

class UpdateGlobalPrivacyEvent extends ProfileEvent {
  final bool? readReceiptsEnabled;
  final bool? typingIndicatorsEnabled;
  final bool? lastSeenEnabled;
  final bool? notificationsEnabled;

  const UpdateGlobalPrivacyEvent({
    this.readReceiptsEnabled,
    this.typingIndicatorsEnabled,
    this.lastSeenEnabled,
    this.notificationsEnabled,
  });
}

class DeleteAccountEvent extends ProfileEvent {
  const DeleteAccountEvent();
}
