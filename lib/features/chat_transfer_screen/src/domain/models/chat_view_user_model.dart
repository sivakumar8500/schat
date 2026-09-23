import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_view_user_model.freezed.dart';
part 'chat_view_user_model.g.dart';

@freezed
abstract class ChatViewUserModel with _$ChatViewUserModel {
  const factory ChatViewUserModel({
    @Default('') String id,
    @Default('') String username,
    @Default('') String phoneNumber,
    @Default('') String name,
    @JsonKey(name: 'profilePictureUrl') String? profilePictureUrl,
    @Default(false) bool isSubscribed,
    String? subscriptionType,
  }) = _ChatViewUserModel;

  factory ChatViewUserModel.fromJson(Map<String, dynamic> json) => _$ChatViewUserModelFromJson(_normalizeUserJson(json));
}

Map<String, dynamic> _normalizeUserJson(Map<String, dynamic> json) {
  final map = Map<String, dynamic>.from(json);
  map['id'] = (json['id'] ?? json['_id'] ?? '').toString();
  map['username'] = (json['username'] ?? '').toString();
  map['phoneNumber'] = (json['phoneNumber'] ?? json['phone_number'] ?? '').toString();
  map['name'] = (json['name'] ?? json['username'] ?? '').toString();
  map['profilePictureUrl'] = (json['profilePictureUrl'] ?? json['profile_picture_url'] ?? json['profile_pic_url'])?.toString();
  map['isSubscribed'] = json['isSubscribed'] ?? json['is_subscribed'] ?? false;
  map['subscriptionType'] = (json['subscriptionType'] ?? json['subscription_type'])?.toString();
  return map;
}
