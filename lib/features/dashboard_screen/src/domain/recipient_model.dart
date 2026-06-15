import "package:freezed_annotation/freezed_annotation.dart";

part "recipient_model.freezed.dart";
part "recipient_model.g.dart";

@freezed
abstract class RecipientModel with _$RecipientModel {
  const factory RecipientModel({
    required String id,
    @JsonKey(name: "phone_number") required String phoneNumber,
    @JsonKey(name: "username") String? username,
    @JsonKey(name: "first_name") String? firstName,
    @JsonKey(name: "last_name") String? lastName,
    @JsonKey(name: "profile_picture_url") String? profilePictureUrl,
    @JsonKey(name: "about") String? about,
    @JsonKey(name: "is_active") required bool isActive,
    @JsonKey(name: "is_online") required bool isOnline,
    @JsonKey(name: "last_seen") String? lastSeen,
    @JsonKey(name: "is_subscribed") required bool isSubscribed,
    @JsonKey(name: "created_at") required String createdAt,
    @JsonKey(name: "updated_at") required String updatedAt,
  }) = _RecipientModel;

  factory RecipientModel.fromJson(Map<String, dynamic> json) => _$RecipientModelFromJson(json);
}
