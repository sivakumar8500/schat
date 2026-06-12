import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    @JsonKey(name: 'phone_number') required String phoneNumber,
    String? username,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'profile_picture_url') String? profilePictureUrl,
    String? about,
    required String id,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'is_online') required bool isOnline,
    @JsonKey(name: 'last_seen') String? lastSeen,
    @JsonKey(name: 'is_subscribed') required bool isSubscribed,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}
