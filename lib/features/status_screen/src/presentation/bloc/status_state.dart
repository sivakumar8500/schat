import 'dart:typed_data';
import 'package:schat/features/status_screen/src/domain/status_model.dart';

abstract class StatusState {
  const StatusState();
}

class StatusInitial extends StatusState {
  const StatusInitial();
}

class StatusLoading extends StatusState {
  const StatusLoading();
}

class StatusLoaded extends StatusState {
  final List<StatusContactModel> recentUpdates;
  final List<StatusContactModel> mutedUpdates;
  
  // My status
  final Uint8List? myStatusBytes;
  final String? myStatusPath;
  final String? myStatusText;
  final DateTime? myStatusTime;

  const StatusLoaded({
    required this.recentUpdates,
    required this.mutedUpdates,
    this.myStatusBytes,
    this.myStatusPath,
    this.myStatusText,
    this.myStatusTime,
  });

  StatusLoaded copyWith({
    List<StatusContactModel>? recentUpdates,
    List<StatusContactModel>? mutedUpdates,
    Uint8List? Function()? myStatusBytes,
    String? Function()? myStatusPath,
    String? Function()? myStatusText,
    DateTime? Function()? myStatusTime,
  }) {
    return StatusLoaded(
      recentUpdates: recentUpdates ?? this.recentUpdates,
      mutedUpdates: mutedUpdates ?? this.mutedUpdates,
      myStatusBytes: myStatusBytes != null ? myStatusBytes() : this.myStatusBytes,
      myStatusPath: myStatusPath != null ? myStatusPath() : this.myStatusPath,
      myStatusText: myStatusText != null ? myStatusText() : this.myStatusText,
      myStatusTime: myStatusTime != null ? myStatusTime() : this.myStatusTime,
    );
  }
}

class StatusFailure extends StatusState {
  final String errorMessage;
  const StatusFailure({required this.errorMessage});
}
