import 'dart:typed_data';

abstract class StatusEvent {
  const StatusEvent();
}

class LoadStatusUpdatesEvent extends StatusEvent {
  const LoadStatusUpdatesEvent();
}

class UploadTextStatusEvent extends StatusEvent {
  final String text;
  final String? textColor;
  final String? privacyType;
  final List<String>? privacyUserIds;

  const UploadTextStatusEvent({
    required this.text,
    this.textColor,
    this.privacyType,
    this.privacyUserIds,
  });
}


class UploadMediaStatusEvent extends StatusEvent {
  final String? path;
  final Uint8List? bytes;
  final String? caption;
  final String? privacyType;
  final List<String>? privacyUserIds;

  const UploadMediaStatusEvent({
    this.path,
    this.bytes,
    this.caption,
    this.privacyType,
    this.privacyUserIds,
  });
}

class MuteContactEvent extends StatusEvent {
  final String contactId;
  final bool mute;
  const MuteContactEvent({required this.contactId, required this.mute});
}

class DeleteMyStatusEvent extends StatusEvent {
  final String statusId;
  const DeleteMyStatusEvent(this.statusId);
}

class FetchStatusPrivacyEvent extends StatusEvent {
  const FetchStatusPrivacyEvent();
}

class UpdateStatusPrivacyEvent extends StatusEvent {
  final String privacyType;
  final List<String>? includedUserIds;
  final List<String>? excludedUserIds;

  const UpdateStatusPrivacyEvent({
    required this.privacyType,
    this.includedUserIds,
    this.excludedUserIds,
  });
}

