import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

part 'status_model.freezed.dart';
part 'status_model.g.dart';

@freezed
abstract class StatusItemModel with _$StatusItemModel {
  const factory StatusItemModel({
    required String id,
    @JsonKey(name: 'userId') String? userId,
    @JsonKey(name: 'statusType') String? statusType,
    @JsonKey(name: 'textContent') String? text,
    @JsonKey(name: 'mediaUrl') String? imagePath,
    @JsonKey(name: 'createdAt') required DateTime timestamp,
    @JsonKey(name: 'expiresAt') DateTime? expiresAt,
    @JsonKey(name: 'viewCount', defaultValue: 0) int? viewCount,
    @JsonKey(name: 'viewers') @Default([]) List<StatusViewerModel> viewers,
    @JsonKey(name: 'privacyType') String? privacyType,
    @JsonKey(name: 'privacyUserIds') List<String>? privacyUserIds,
    @JsonKey(includeFromJson: false, includeToJson: false) @Default(Colors.black) Color backgroundColor,
    @JsonKey(includeFromJson: false, includeToJson: false) @Default(false) bool viewed,
  }) = _StatusItemModel;

  factory StatusItemModel.fromJson(Map<String, dynamic> json) => _$StatusItemModelFromJson(json);
}

@freezed
abstract class StatusViewerModel with _$StatusViewerModel {
  const factory StatusViewerModel({
    required String viewerId,
    String? username,
    String? displayName,
    @JsonKey(name: 'viewedAt') int? viewedAt,
  }) = _StatusViewerModel;

  factory StatusViewerModel.fromJson(Map<String, dynamic> json) => _$StatusViewerModelFromJson(json);
}

@freezed
abstract class StatusContactModel with _$StatusContactModel {
  const factory StatusContactModel({
    @JsonKey(name: 'userId') required String contactId,
    @JsonKey(name: 'displayName', defaultValue: 'User') required String name,
    @JsonKey(name: 'username') String? username,
    @JsonKey(name: 'profilePictureUrl') String? profilePictureUrl,
    @JsonKey(includeFromJson: false, includeToJson: false) @Default(Colors.blue) Color profileColor,
    @Default([]) List<StatusItemModel> statuses,
    @JsonKey(includeFromJson: false, includeToJson: false) @Default(false) bool isMuted,
  }) = _StatusContactModel;
  
  const StatusContactModel._();

  factory StatusContactModel.fromJson(Map<String, dynamic> json) => _$StatusContactModelFromJson(json);
  
  bool get allViewed => statuses.every((s) => s.viewed);
  int get statusCount => statuses.length;
}
