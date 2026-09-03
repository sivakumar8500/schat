import 'dart:typed_data';

abstract class StatusEvent {
  const StatusEvent();
}

class LoadStatusUpdatesEvent extends StatusEvent {
  const LoadStatusUpdatesEvent();
}

class UploadTextStatusEvent extends StatusEvent {
  final String text;
  final String? privacyType;
  final List<String>? privacyUserIds;

  const UploadTextStatusEvent({
    required this.text,
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
  const DeleteMyStatusEvent();
}
