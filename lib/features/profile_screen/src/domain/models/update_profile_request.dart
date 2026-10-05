import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_profile_request.freezed.dart';
part 'update_profile_request.g.dart';

@freezed
abstract class UpdateProfileRequest with _$UpdateProfileRequest {
  const factory UpdateProfileRequest({
    String? username,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'profile_picture_url') String? profilePictureUrl,
    String? about,
    @JsonKey(name: 'default_disappearing_timer') int? defaultDisappearingTimer,
    @JsonKey(name: 'read_receipts_enabled') bool? readReceiptsEnabled,
    @JsonKey(name: 'typing_indicators_enabled') bool? typingIndicatorsEnabled,
    @JsonKey(name: 'last_seen_enabled') bool? lastSeenEnabled,
    @JsonKey(name: 'notifications_enabled') bool? notificationsEnabled,
  }) = _UpdateProfileRequest;

  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) => _$UpdateProfileRequestFromJson(json);
}
