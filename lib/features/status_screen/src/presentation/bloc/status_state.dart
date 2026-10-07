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
  final List<StatusItemModel> myStatuses;
  final Uint8List? myStatusBytes;
  final String? myStatusPath;
  final String? myStatusText;
  final DateTime? myStatusTime;

  // Privacy
  final StatusPrivacyModel? privacyModel;

  // Upload indicators
  final bool isUploading;
  final double? uploadProgress;
  final String? uploadStatusMessage;
  final String? uploadSuccessMessage;
  final String? uploadError;

  const StatusLoaded({
    required this.recentUpdates,
    required this.mutedUpdates,
    this.myStatuses = const [],
    this.myStatusBytes,
    this.myStatusPath,
    this.myStatusText,
    this.myStatusTime,
    this.privacyModel,
    this.isUploading = false,
    this.uploadProgress,
    this.uploadStatusMessage,
    this.uploadSuccessMessage,
    this.uploadError,
  });

  StatusLoaded copyWith({
    List<StatusContactModel>? recentUpdates,
    List<StatusContactModel>? mutedUpdates,
    List<StatusItemModel>? myStatuses,
    Uint8List? Function()? myStatusBytes,
    String? Function()? myStatusPath,
    String? Function()? myStatusText,
    DateTime? Function()? myStatusTime,
    StatusPrivacyModel? privacyModel,
    bool? isUploading,
    double? Function()? uploadProgress,
    String? Function()? uploadStatusMessage,
    String? Function()? uploadSuccessMessage,
    String? Function()? uploadError,
  }) {
    return StatusLoaded(
      recentUpdates: recentUpdates ?? this.recentUpdates,
      mutedUpdates: mutedUpdates ?? this.mutedUpdates,
      myStatuses: myStatuses ?? this.myStatuses,
      myStatusBytes: myStatusBytes != null ? myStatusBytes() : this.myStatusBytes,
      myStatusPath: myStatusPath != null ? myStatusPath() : this.myStatusPath,
      myStatusText: myStatusText != null ? myStatusText() : this.myStatusText,
      myStatusTime: myStatusTime != null ? myStatusTime() : this.myStatusTime,
      privacyModel: privacyModel ?? this.privacyModel,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress != null ? uploadProgress() : this.uploadProgress,
      uploadStatusMessage: uploadStatusMessage != null ? uploadStatusMessage() : this.uploadStatusMessage,
      uploadSuccessMessage: uploadSuccessMessage != null ? uploadSuccessMessage() : this.uploadSuccessMessage,
      uploadError: uploadError != null ? uploadError() : this.uploadError,
    );
  }
}



class StatusFailure extends StatusState {
  final String errorMessage;
  const StatusFailure({required this.errorMessage});
}
