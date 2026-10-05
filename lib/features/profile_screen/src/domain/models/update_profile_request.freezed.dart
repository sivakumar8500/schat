// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_profile_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpdateProfileRequest {

 String? get username;@JsonKey(name: 'first_name') String? get firstName;@JsonKey(name: 'last_name') String? get lastName;@JsonKey(name: 'profile_picture_url') String? get profilePictureUrl; String? get about;@JsonKey(name: 'default_disappearing_timer') int? get defaultDisappearingTimer;@JsonKey(name: 'read_receipts_enabled') bool? get readReceiptsEnabled;@JsonKey(name: 'typing_indicators_enabled') bool? get typingIndicatorsEnabled;@JsonKey(name: 'last_seen_enabled') bool? get lastSeenEnabled;@JsonKey(name: 'notifications_enabled') bool? get notificationsEnabled;
/// Create a copy of UpdateProfileRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateProfileRequestCopyWith<UpdateProfileRequest> get copyWith => _$UpdateProfileRequestCopyWithImpl<UpdateProfileRequest>(this as UpdateProfileRequest, _$identity);

  /// Serializes this UpdateProfileRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateProfileRequest&&(identical(other.username, username) || other.username == username)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl)&&(identical(other.about, about) || other.about == about)&&(identical(other.defaultDisappearingTimer, defaultDisappearingTimer) || other.defaultDisappearingTimer == defaultDisappearingTimer)&&(identical(other.readReceiptsEnabled, readReceiptsEnabled) || other.readReceiptsEnabled == readReceiptsEnabled)&&(identical(other.typingIndicatorsEnabled, typingIndicatorsEnabled) || other.typingIndicatorsEnabled == typingIndicatorsEnabled)&&(identical(other.lastSeenEnabled, lastSeenEnabled) || other.lastSeenEnabled == lastSeenEnabled)&&(identical(other.notificationsEnabled, notificationsEnabled) || other.notificationsEnabled == notificationsEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,firstName,lastName,profilePictureUrl,about,defaultDisappearingTimer,readReceiptsEnabled,typingIndicatorsEnabled,lastSeenEnabled,notificationsEnabled);

@override
String toString() {
  return 'UpdateProfileRequest(username: $username, firstName: $firstName, lastName: $lastName, profilePictureUrl: $profilePictureUrl, about: $about, defaultDisappearingTimer: $defaultDisappearingTimer, readReceiptsEnabled: $readReceiptsEnabled, typingIndicatorsEnabled: $typingIndicatorsEnabled, lastSeenEnabled: $lastSeenEnabled, notificationsEnabled: $notificationsEnabled)';
}


}

/// @nodoc
abstract mixin class $UpdateProfileRequestCopyWith<$Res>  {
  factory $UpdateProfileRequestCopyWith(UpdateProfileRequest value, $Res Function(UpdateProfileRequest) _then) = _$UpdateProfileRequestCopyWithImpl;
@useResult
$Res call({
 String? username,@JsonKey(name: 'first_name') String? firstName,@JsonKey(name: 'last_name') String? lastName,@JsonKey(name: 'profile_picture_url') String? profilePictureUrl, String? about,@JsonKey(name: 'default_disappearing_timer') int? defaultDisappearingTimer,@JsonKey(name: 'read_receipts_enabled') bool? readReceiptsEnabled,@JsonKey(name: 'typing_indicators_enabled') bool? typingIndicatorsEnabled,@JsonKey(name: 'last_seen_enabled') bool? lastSeenEnabled,@JsonKey(name: 'notifications_enabled') bool? notificationsEnabled
});




}
/// @nodoc
class _$UpdateProfileRequestCopyWithImpl<$Res>
    implements $UpdateProfileRequestCopyWith<$Res> {
  _$UpdateProfileRequestCopyWithImpl(this._self, this._then);

  final UpdateProfileRequest _self;
  final $Res Function(UpdateProfileRequest) _then;

/// Create a copy of UpdateProfileRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? username = freezed,Object? firstName = freezed,Object? lastName = freezed,Object? profilePictureUrl = freezed,Object? about = freezed,Object? defaultDisappearingTimer = freezed,Object? readReceiptsEnabled = freezed,Object? typingIndicatorsEnabled = freezed,Object? lastSeenEnabled = freezed,Object? notificationsEnabled = freezed,}) {
  return _then(_self.copyWith(
username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,about: freezed == about ? _self.about : about // ignore: cast_nullable_to_non_nullable
as String?,defaultDisappearingTimer: freezed == defaultDisappearingTimer ? _self.defaultDisappearingTimer : defaultDisappearingTimer // ignore: cast_nullable_to_non_nullable
as int?,readReceiptsEnabled: freezed == readReceiptsEnabled ? _self.readReceiptsEnabled : readReceiptsEnabled // ignore: cast_nullable_to_non_nullable
as bool?,typingIndicatorsEnabled: freezed == typingIndicatorsEnabled ? _self.typingIndicatorsEnabled : typingIndicatorsEnabled // ignore: cast_nullable_to_non_nullable
as bool?,lastSeenEnabled: freezed == lastSeenEnabled ? _self.lastSeenEnabled : lastSeenEnabled // ignore: cast_nullable_to_non_nullable
as bool?,notificationsEnabled: freezed == notificationsEnabled ? _self.notificationsEnabled : notificationsEnabled // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateProfileRequest].
extension UpdateProfileRequestPatterns on UpdateProfileRequest {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateProfileRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateProfileRequest() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateProfileRequest value)  $default,){
final _that = this;
switch (_that) {
case _UpdateProfileRequest():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateProfileRequest value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateProfileRequest() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? username, @JsonKey(name: 'first_name')  String? firstName, @JsonKey(name: 'last_name')  String? lastName, @JsonKey(name: 'profile_picture_url')  String? profilePictureUrl,  String? about, @JsonKey(name: 'default_disappearing_timer')  int? defaultDisappearingTimer, @JsonKey(name: 'read_receipts_enabled')  bool? readReceiptsEnabled, @JsonKey(name: 'typing_indicators_enabled')  bool? typingIndicatorsEnabled, @JsonKey(name: 'last_seen_enabled')  bool? lastSeenEnabled, @JsonKey(name: 'notifications_enabled')  bool? notificationsEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateProfileRequest() when $default != null:
return $default(_that.username,_that.firstName,_that.lastName,_that.profilePictureUrl,_that.about,_that.defaultDisappearingTimer,_that.readReceiptsEnabled,_that.typingIndicatorsEnabled,_that.lastSeenEnabled,_that.notificationsEnabled);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? username, @JsonKey(name: 'first_name')  String? firstName, @JsonKey(name: 'last_name')  String? lastName, @JsonKey(name: 'profile_picture_url')  String? profilePictureUrl,  String? about, @JsonKey(name: 'default_disappearing_timer')  int? defaultDisappearingTimer, @JsonKey(name: 'read_receipts_enabled')  bool? readReceiptsEnabled, @JsonKey(name: 'typing_indicators_enabled')  bool? typingIndicatorsEnabled, @JsonKey(name: 'last_seen_enabled')  bool? lastSeenEnabled, @JsonKey(name: 'notifications_enabled')  bool? notificationsEnabled)  $default,) {final _that = this;
switch (_that) {
case _UpdateProfileRequest():
return $default(_that.username,_that.firstName,_that.lastName,_that.profilePictureUrl,_that.about,_that.defaultDisappearingTimer,_that.readReceiptsEnabled,_that.typingIndicatorsEnabled,_that.lastSeenEnabled,_that.notificationsEnabled);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? username, @JsonKey(name: 'first_name')  String? firstName, @JsonKey(name: 'last_name')  String? lastName, @JsonKey(name: 'profile_picture_url')  String? profilePictureUrl,  String? about, @JsonKey(name: 'default_disappearing_timer')  int? defaultDisappearingTimer, @JsonKey(name: 'read_receipts_enabled')  bool? readReceiptsEnabled, @JsonKey(name: 'typing_indicators_enabled')  bool? typingIndicatorsEnabled, @JsonKey(name: 'last_seen_enabled')  bool? lastSeenEnabled, @JsonKey(name: 'notifications_enabled')  bool? notificationsEnabled)?  $default,) {final _that = this;
switch (_that) {
case _UpdateProfileRequest() when $default != null:
return $default(_that.username,_that.firstName,_that.lastName,_that.profilePictureUrl,_that.about,_that.defaultDisappearingTimer,_that.readReceiptsEnabled,_that.typingIndicatorsEnabled,_that.lastSeenEnabled,_that.notificationsEnabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateProfileRequest implements UpdateProfileRequest {
  const _UpdateProfileRequest({this.username, @JsonKey(name: 'first_name') this.firstName, @JsonKey(name: 'last_name') this.lastName, @JsonKey(name: 'profile_picture_url') this.profilePictureUrl, this.about, @JsonKey(name: 'default_disappearing_timer') this.defaultDisappearingTimer, @JsonKey(name: 'read_receipts_enabled') this.readReceiptsEnabled, @JsonKey(name: 'typing_indicators_enabled') this.typingIndicatorsEnabled, @JsonKey(name: 'last_seen_enabled') this.lastSeenEnabled, @JsonKey(name: 'notifications_enabled') this.notificationsEnabled});
  factory _UpdateProfileRequest.fromJson(Map<String, dynamic> json) => _$UpdateProfileRequestFromJson(json);

@override final  String? username;
@override@JsonKey(name: 'first_name') final  String? firstName;
@override@JsonKey(name: 'last_name') final  String? lastName;
@override@JsonKey(name: 'profile_picture_url') final  String? profilePictureUrl;
@override final  String? about;
@override@JsonKey(name: 'default_disappearing_timer') final  int? defaultDisappearingTimer;
@override@JsonKey(name: 'read_receipts_enabled') final  bool? readReceiptsEnabled;
@override@JsonKey(name: 'typing_indicators_enabled') final  bool? typingIndicatorsEnabled;
@override@JsonKey(name: 'last_seen_enabled') final  bool? lastSeenEnabled;
@override@JsonKey(name: 'notifications_enabled') final  bool? notificationsEnabled;

/// Create a copy of UpdateProfileRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateProfileRequestCopyWith<_UpdateProfileRequest> get copyWith => __$UpdateProfileRequestCopyWithImpl<_UpdateProfileRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateProfileRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateProfileRequest&&(identical(other.username, username) || other.username == username)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl)&&(identical(other.about, about) || other.about == about)&&(identical(other.defaultDisappearingTimer, defaultDisappearingTimer) || other.defaultDisappearingTimer == defaultDisappearingTimer)&&(identical(other.readReceiptsEnabled, readReceiptsEnabled) || other.readReceiptsEnabled == readReceiptsEnabled)&&(identical(other.typingIndicatorsEnabled, typingIndicatorsEnabled) || other.typingIndicatorsEnabled == typingIndicatorsEnabled)&&(identical(other.lastSeenEnabled, lastSeenEnabled) || other.lastSeenEnabled == lastSeenEnabled)&&(identical(other.notificationsEnabled, notificationsEnabled) || other.notificationsEnabled == notificationsEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,firstName,lastName,profilePictureUrl,about,defaultDisappearingTimer,readReceiptsEnabled,typingIndicatorsEnabled,lastSeenEnabled,notificationsEnabled);

@override
String toString() {
  return 'UpdateProfileRequest(username: $username, firstName: $firstName, lastName: $lastName, profilePictureUrl: $profilePictureUrl, about: $about, defaultDisappearingTimer: $defaultDisappearingTimer, readReceiptsEnabled: $readReceiptsEnabled, typingIndicatorsEnabled: $typingIndicatorsEnabled, lastSeenEnabled: $lastSeenEnabled, notificationsEnabled: $notificationsEnabled)';
}


}

/// @nodoc
abstract mixin class _$UpdateProfileRequestCopyWith<$Res> implements $UpdateProfileRequestCopyWith<$Res> {
  factory _$UpdateProfileRequestCopyWith(_UpdateProfileRequest value, $Res Function(_UpdateProfileRequest) _then) = __$UpdateProfileRequestCopyWithImpl;
@override @useResult
$Res call({
 String? username,@JsonKey(name: 'first_name') String? firstName,@JsonKey(name: 'last_name') String? lastName,@JsonKey(name: 'profile_picture_url') String? profilePictureUrl, String? about,@JsonKey(name: 'default_disappearing_timer') int? defaultDisappearingTimer,@JsonKey(name: 'read_receipts_enabled') bool? readReceiptsEnabled,@JsonKey(name: 'typing_indicators_enabled') bool? typingIndicatorsEnabled,@JsonKey(name: 'last_seen_enabled') bool? lastSeenEnabled,@JsonKey(name: 'notifications_enabled') bool? notificationsEnabled
});




}
/// @nodoc
class __$UpdateProfileRequestCopyWithImpl<$Res>
    implements _$UpdateProfileRequestCopyWith<$Res> {
  __$UpdateProfileRequestCopyWithImpl(this._self, this._then);

  final _UpdateProfileRequest _self;
  final $Res Function(_UpdateProfileRequest) _then;

/// Create a copy of UpdateProfileRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? username = freezed,Object? firstName = freezed,Object? lastName = freezed,Object? profilePictureUrl = freezed,Object? about = freezed,Object? defaultDisappearingTimer = freezed,Object? readReceiptsEnabled = freezed,Object? typingIndicatorsEnabled = freezed,Object? lastSeenEnabled = freezed,Object? notificationsEnabled = freezed,}) {
  return _then(_UpdateProfileRequest(
username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,about: freezed == about ? _self.about : about // ignore: cast_nullable_to_non_nullable
as String?,defaultDisappearingTimer: freezed == defaultDisappearingTimer ? _self.defaultDisappearingTimer : defaultDisappearingTimer // ignore: cast_nullable_to_non_nullable
as int?,readReceiptsEnabled: freezed == readReceiptsEnabled ? _self.readReceiptsEnabled : readReceiptsEnabled // ignore: cast_nullable_to_non_nullable
as bool?,typingIndicatorsEnabled: freezed == typingIndicatorsEnabled ? _self.typingIndicatorsEnabled : typingIndicatorsEnabled // ignore: cast_nullable_to_non_nullable
as bool?,lastSeenEnabled: freezed == lastSeenEnabled ? _self.lastSeenEnabled : lastSeenEnabled // ignore: cast_nullable_to_non_nullable
as bool?,notificationsEnabled: freezed == notificationsEnabled ? _self.notificationsEnabled : notificationsEnabled // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
