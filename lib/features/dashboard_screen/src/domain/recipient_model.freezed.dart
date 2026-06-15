// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipient_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecipientModel {

 String get id;@JsonKey(name: "phone_number") String get phoneNumber;@JsonKey(name: "username") String? get username;@JsonKey(name: "first_name") String? get firstName;@JsonKey(name: "last_name") String? get lastName;@JsonKey(name: "profile_picture_url") String? get profilePictureUrl;@JsonKey(name: "about") String? get about;@JsonKey(name: "is_active") bool get isActive;@JsonKey(name: "is_online") bool get isOnline;@JsonKey(name: "last_seen") String? get lastSeen;@JsonKey(name: "is_subscribed") bool get isSubscribed;@JsonKey(name: "created_at") String get createdAt;@JsonKey(name: "updated_at") String get updatedAt;
/// Create a copy of RecipientModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipientModelCopyWith<RecipientModel> get copyWith => _$RecipientModelCopyWithImpl<RecipientModel>(this as RecipientModel, _$identity);

  /// Serializes this RecipientModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipientModel&&(identical(other.id, id) || other.id == id)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.username, username) || other.username == username)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl)&&(identical(other.about, about) || other.about == about)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen)&&(identical(other.isSubscribed, isSubscribed) || other.isSubscribed == isSubscribed)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,phoneNumber,username,firstName,lastName,profilePictureUrl,about,isActive,isOnline,lastSeen,isSubscribed,createdAt,updatedAt);

@override
String toString() {
  return 'RecipientModel(id: $id, phoneNumber: $phoneNumber, username: $username, firstName: $firstName, lastName: $lastName, profilePictureUrl: $profilePictureUrl, about: $about, isActive: $isActive, isOnline: $isOnline, lastSeen: $lastSeen, isSubscribed: $isSubscribed, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $RecipientModelCopyWith<$Res>  {
  factory $RecipientModelCopyWith(RecipientModel value, $Res Function(RecipientModel) _then) = _$RecipientModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: "phone_number") String phoneNumber,@JsonKey(name: "username") String? username,@JsonKey(name: "first_name") String? firstName,@JsonKey(name: "last_name") String? lastName,@JsonKey(name: "profile_picture_url") String? profilePictureUrl,@JsonKey(name: "about") String? about,@JsonKey(name: "is_active") bool isActive,@JsonKey(name: "is_online") bool isOnline,@JsonKey(name: "last_seen") String? lastSeen,@JsonKey(name: "is_subscribed") bool isSubscribed,@JsonKey(name: "created_at") String createdAt,@JsonKey(name: "updated_at") String updatedAt
});




}
/// @nodoc
class _$RecipientModelCopyWithImpl<$Res>
    implements $RecipientModelCopyWith<$Res> {
  _$RecipientModelCopyWithImpl(this._self, this._then);

  final RecipientModel _self;
  final $Res Function(RecipientModel) _then;

/// Create a copy of RecipientModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? phoneNumber = null,Object? username = freezed,Object? firstName = freezed,Object? lastName = freezed,Object? profilePictureUrl = freezed,Object? about = freezed,Object? isActive = null,Object? isOnline = null,Object? lastSeen = freezed,Object? isSubscribed = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,about: freezed == about ? _self.about : about // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,lastSeen: freezed == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as String?,isSubscribed: null == isSubscribed ? _self.isSubscribed : isSubscribed // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RecipientModel].
extension RecipientModelPatterns on RecipientModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipientModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipientModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipientModel value)  $default,){
final _that = this;
switch (_that) {
case _RecipientModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipientModel value)?  $default,){
final _that = this;
switch (_that) {
case _RecipientModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: "phone_number")  String phoneNumber, @JsonKey(name: "username")  String? username, @JsonKey(name: "first_name")  String? firstName, @JsonKey(name: "last_name")  String? lastName, @JsonKey(name: "profile_picture_url")  String? profilePictureUrl, @JsonKey(name: "about")  String? about, @JsonKey(name: "is_active")  bool isActive, @JsonKey(name: "is_online")  bool isOnline, @JsonKey(name: "last_seen")  String? lastSeen, @JsonKey(name: "is_subscribed")  bool isSubscribed, @JsonKey(name: "created_at")  String createdAt, @JsonKey(name: "updated_at")  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipientModel() when $default != null:
return $default(_that.id,_that.phoneNumber,_that.username,_that.firstName,_that.lastName,_that.profilePictureUrl,_that.about,_that.isActive,_that.isOnline,_that.lastSeen,_that.isSubscribed,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: "phone_number")  String phoneNumber, @JsonKey(name: "username")  String? username, @JsonKey(name: "first_name")  String? firstName, @JsonKey(name: "last_name")  String? lastName, @JsonKey(name: "profile_picture_url")  String? profilePictureUrl, @JsonKey(name: "about")  String? about, @JsonKey(name: "is_active")  bool isActive, @JsonKey(name: "is_online")  bool isOnline, @JsonKey(name: "last_seen")  String? lastSeen, @JsonKey(name: "is_subscribed")  bool isSubscribed, @JsonKey(name: "created_at")  String createdAt, @JsonKey(name: "updated_at")  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _RecipientModel():
return $default(_that.id,_that.phoneNumber,_that.username,_that.firstName,_that.lastName,_that.profilePictureUrl,_that.about,_that.isActive,_that.isOnline,_that.lastSeen,_that.isSubscribed,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: "phone_number")  String phoneNumber, @JsonKey(name: "username")  String? username, @JsonKey(name: "first_name")  String? firstName, @JsonKey(name: "last_name")  String? lastName, @JsonKey(name: "profile_picture_url")  String? profilePictureUrl, @JsonKey(name: "about")  String? about, @JsonKey(name: "is_active")  bool isActive, @JsonKey(name: "is_online")  bool isOnline, @JsonKey(name: "last_seen")  String? lastSeen, @JsonKey(name: "is_subscribed")  bool isSubscribed, @JsonKey(name: "created_at")  String createdAt, @JsonKey(name: "updated_at")  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _RecipientModel() when $default != null:
return $default(_that.id,_that.phoneNumber,_that.username,_that.firstName,_that.lastName,_that.profilePictureUrl,_that.about,_that.isActive,_that.isOnline,_that.lastSeen,_that.isSubscribed,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecipientModel implements RecipientModel {
  const _RecipientModel({required this.id, @JsonKey(name: "phone_number") required this.phoneNumber, @JsonKey(name: "username") this.username, @JsonKey(name: "first_name") this.firstName, @JsonKey(name: "last_name") this.lastName, @JsonKey(name: "profile_picture_url") this.profilePictureUrl, @JsonKey(name: "about") this.about, @JsonKey(name: "is_active") required this.isActive, @JsonKey(name: "is_online") required this.isOnline, @JsonKey(name: "last_seen") this.lastSeen, @JsonKey(name: "is_subscribed") required this.isSubscribed, @JsonKey(name: "created_at") required this.createdAt, @JsonKey(name: "updated_at") required this.updatedAt});
  factory _RecipientModel.fromJson(Map<String, dynamic> json) => _$RecipientModelFromJson(json);

@override final  String id;
@override@JsonKey(name: "phone_number") final  String phoneNumber;
@override@JsonKey(name: "username") final  String? username;
@override@JsonKey(name: "first_name") final  String? firstName;
@override@JsonKey(name: "last_name") final  String? lastName;
@override@JsonKey(name: "profile_picture_url") final  String? profilePictureUrl;
@override@JsonKey(name: "about") final  String? about;
@override@JsonKey(name: "is_active") final  bool isActive;
@override@JsonKey(name: "is_online") final  bool isOnline;
@override@JsonKey(name: "last_seen") final  String? lastSeen;
@override@JsonKey(name: "is_subscribed") final  bool isSubscribed;
@override@JsonKey(name: "created_at") final  String createdAt;
@override@JsonKey(name: "updated_at") final  String updatedAt;

/// Create a copy of RecipientModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipientModelCopyWith<_RecipientModel> get copyWith => __$RecipientModelCopyWithImpl<_RecipientModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecipientModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipientModel&&(identical(other.id, id) || other.id == id)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.username, username) || other.username == username)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl)&&(identical(other.about, about) || other.about == about)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen)&&(identical(other.isSubscribed, isSubscribed) || other.isSubscribed == isSubscribed)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,phoneNumber,username,firstName,lastName,profilePictureUrl,about,isActive,isOnline,lastSeen,isSubscribed,createdAt,updatedAt);

@override
String toString() {
  return 'RecipientModel(id: $id, phoneNumber: $phoneNumber, username: $username, firstName: $firstName, lastName: $lastName, profilePictureUrl: $profilePictureUrl, about: $about, isActive: $isActive, isOnline: $isOnline, lastSeen: $lastSeen, isSubscribed: $isSubscribed, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$RecipientModelCopyWith<$Res> implements $RecipientModelCopyWith<$Res> {
  factory _$RecipientModelCopyWith(_RecipientModel value, $Res Function(_RecipientModel) _then) = __$RecipientModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: "phone_number") String phoneNumber,@JsonKey(name: "username") String? username,@JsonKey(name: "first_name") String? firstName,@JsonKey(name: "last_name") String? lastName,@JsonKey(name: "profile_picture_url") String? profilePictureUrl,@JsonKey(name: "about") String? about,@JsonKey(name: "is_active") bool isActive,@JsonKey(name: "is_online") bool isOnline,@JsonKey(name: "last_seen") String? lastSeen,@JsonKey(name: "is_subscribed") bool isSubscribed,@JsonKey(name: "created_at") String createdAt,@JsonKey(name: "updated_at") String updatedAt
});




}
/// @nodoc
class __$RecipientModelCopyWithImpl<$Res>
    implements _$RecipientModelCopyWith<$Res> {
  __$RecipientModelCopyWithImpl(this._self, this._then);

  final _RecipientModel _self;
  final $Res Function(_RecipientModel) _then;

/// Create a copy of RecipientModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? phoneNumber = null,Object? username = freezed,Object? firstName = freezed,Object? lastName = freezed,Object? profilePictureUrl = freezed,Object? about = freezed,Object? isActive = null,Object? isOnline = null,Object? lastSeen = freezed,Object? isSubscribed = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_RecipientModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,about: freezed == about ? _self.about : about // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,lastSeen: freezed == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as String?,isSubscribed: null == isSubscribed ? _self.isSubscribed : isSubscribed // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
