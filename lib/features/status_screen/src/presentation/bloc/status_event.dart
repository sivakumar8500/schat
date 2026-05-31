import 'dart:typed_data';

abstract class StatusEvent {
  const StatusEvent();
}

class LoadStatusUpdatesEvent extends StatusEvent {
  const LoadStatusUpdatesEvent();
}

class UploadTextStatusEvent extends StatusEvent {
  final String text;
  const UploadTextStatusEvent({required this.text});
}

class UploadMediaStatusEvent extends StatusEvent {
  final String? path;
  final Uint8List? bytes;
  final String? caption;

  const UploadMediaStatusEvent({
    this.path,
    this.bytes,
    this.caption,
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
