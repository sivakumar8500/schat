import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipient_model.freezed.dart';
part 'recipient_model.g.dart';

@freezed
abstract class RecipientModel with _$RecipientModel {
  const factory RecipientModel({
    @JsonKey(name: '_id', includeIfNull: false) @Default('') String id,
    @JsonKey(name: 'phone_number') @Default('') String phoneNumber,
    String? username,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'profile_picture_url') String? profilePictureUrl,
    String? about,
    @JsonKey(name: 'is_active') @Default(false) bool isActive,
    @JsonKey(name: 'is_online') @Default(false) bool isOnline,
    @JsonKey(name: 'last_seen') String? lastSeen,
    @JsonKey(name: 'is_subscribed') @Default(false) bool isSubscribed,
    @JsonKey(name: 'subscription_type') String? subscriptionType,
    @JsonKey(name: 'created_at') @Default('') String createdAt,
    @JsonKey(name: 'updated_at') @Default('') String updatedAt,
  }) = _RecipientModel;

  factory RecipientModel.fromJson(Map<String, dynamic> json) => _$RecipientModelFromJson(_normalizeRecipientJson(json));

  Map<String, dynamic> toJson();
}

Map<String, dynamic> _normalizeRecipientJson(Map<String, dynamic> json) {
  final normalizedJson = Map<String, dynamic>.from(json);
  normalizedJson['_id'] = (json['id'] ?? json['_id'])?.toString() ?? '';
  return normalizedJson;
}
