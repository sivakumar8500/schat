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

@JsonKey(name: '_id', includeIfNull: false) String get id;@JsonKey(name: 'phone_number') String get phoneNumber; String? get username;@JsonKey(name: 'first_name') String? get firstName;@JsonKey(name: 'last_name') String? get lastName;@JsonKey(name: 'profile_picture_url') String? get profilePictureUrl; String? get about;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'is_online') bool get isOnline;@JsonKey(name: 'last_seen') String? get lastSeen;@JsonKey(name: 'is_subscribed') bool get isSubscribed;@JsonKey(name: 'subscription_type') String? get subscriptionType;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'updated_at') String get updatedAt;@JsonKey(name: 'contactName') String? get contactName;
/// Create a copy of RecipientModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipientModelCopyWith<RecipientModel> get copyWith => _$RecipientModelCopyWithImpl<RecipientModel>(this as RecipientModel, _$identity);

  /// Serializes this RecipientModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipientModel&&(identical(other.id, id) || other.id == id)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.username, username) || other.username == username)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl)&&(identical(other.about, about) || other.about == about)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen)&&(identical(other.isSubscribed, isSubscribed) || other.isSubscribed == isSubscribed)&&(identical(other.subscriptionType, subscriptionType) || other.subscriptionType == subscriptionType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.contactName, contactName) || other.contactName == contactName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,phoneNumber,username,firstName,lastName,profilePictureUrl,about,isActive,isOnline,lastSeen,isSubscribed,subscriptionType,createdAt,updatedAt,contactName);

@override
String toString() {
  return 'RecipientModel(id: $id, phoneNumber: $phoneNumber, username: $username, firstName: $firstName, lastName: $lastName, profilePictureUrl: $profilePictureUrl, about: $about, isActive: $isActive, isOnline: $isOnline, lastSeen: $lastSeen, isSubscribed: $isSubscribed, subscriptionType: $subscriptionType, createdAt: $createdAt, updatedAt: $updatedAt, contactName: $contactName)';
}


}

/// @nodoc
abstract mixin class $RecipientModelCopyWith<$Res>  {
  factory $RecipientModelCopyWith(RecipientModel value, $Res Function(RecipientModel) _then) = _$RecipientModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '_id', includeIfNull: false) String id,@JsonKey(name: 'phone_number') String phoneNumber, String? username,@JsonKey(name: 'first_name') String? firstName,@JsonKey(name: 'last_name') String? lastName,@JsonKey(name: 'profile_picture_url') String? profilePictureUrl, String? about,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'is_online') bool isOnline,@JsonKey(name: 'last_seen') String? lastSeen,@JsonKey(name: 'is_subscribed') bool isSubscribed,@JsonKey(name: 'subscription_type') String? subscriptionType,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt,@JsonKey(name: 'contactName') String? contactName
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? phoneNumber = null,Object? username = freezed,Object? firstName = freezed,Object? lastName = freezed,Object? profilePictureUrl = freezed,Object? about = freezed,Object? isActive = null,Object? isOnline = null,Object? lastSeen = freezed,Object? isSubscribed = null,Object? subscriptionType = freezed,Object? createdAt = null,Object? updatedAt = null,Object? contactName = freezed,}) {
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
as bool,subscriptionType: freezed == subscriptionType ? _self.subscriptionType : subscriptionType // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,contactName: freezed == contactName ? _self.contactName : contactName // ignore: cast_nullable_to_non_nullable
as String?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '_id', includeIfNull: false)  String id, @JsonKey(name: 'phone_number')  String phoneNumber,  String? username, @JsonKey(name: 'first_name')  String? firstName, @JsonKey(name: 'last_name')  String? lastName, @JsonKey(name: 'profile_picture_url')  String? profilePictureUrl,  String? about, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'is_online')  bool isOnline, @JsonKey(name: 'last_seen')  String? lastSeen, @JsonKey(name: 'is_subscribed')  bool isSubscribed, @JsonKey(name: 'subscription_type')  String? subscriptionType, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt, @JsonKey(name: 'contactName')  String? contactName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipientModel() when $default != null:
return $default(_that.id,_that.phoneNumber,_that.username,_that.firstName,_that.lastName,_that.profilePictureUrl,_that.about,_that.isActive,_that.isOnline,_that.lastSeen,_that.isSubscribed,_that.subscriptionType,_that.createdAt,_that.updatedAt,_that.contactName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '_id', includeIfNull: false)  String id, @JsonKey(name: 'phone_number')  String phoneNumber,  String? username, @JsonKey(name: 'first_name')  String? firstName, @JsonKey(name: 'last_name')  String? lastName, @JsonKey(name: 'profile_picture_url')  String? profilePictureUrl,  String? about, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'is_online')  bool isOnline, @JsonKey(name: 'last_seen')  String? lastSeen, @JsonKey(name: 'is_subscribed')  bool isSubscribed, @JsonKey(name: 'subscription_type')  String? subscriptionType, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt, @JsonKey(name: 'contactName')  String? contactName)  $default,) {final _that = this;
switch (_that) {
case _RecipientModel():
return $default(_that.id,_that.phoneNumber,_that.username,_that.firstName,_that.lastName,_that.profilePictureUrl,_that.about,_that.isActive,_that.isOnline,_that.lastSeen,_that.isSubscribed,_that.subscriptionType,_that.createdAt,_that.updatedAt,_that.contactName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '_id', includeIfNull: false)  String id, @JsonKey(name: 'phone_number')  String phoneNumber,  String? username, @JsonKey(name: 'first_name')  String? firstName, @JsonKey(name: 'last_name')  String? lastName, @JsonKey(name: 'profile_picture_url')  String? profilePictureUrl,  String? about, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'is_online')  bool isOnline, @JsonKey(name: 'last_seen')  String? lastSeen, @JsonKey(name: 'is_subscribed')  bool isSubscribed, @JsonKey(name: 'subscription_type')  String? subscriptionType, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt, @JsonKey(name: 'contactName')  String? contactName)?  $default,) {final _that = this;
switch (_that) {
case _RecipientModel() when $default != null:
return $default(_that.id,_that.phoneNumber,_that.username,_that.firstName,_that.lastName,_that.profilePictureUrl,_that.about,_that.isActive,_that.isOnline,_that.lastSeen,_that.isSubscribed,_that.subscriptionType,_that.createdAt,_that.updatedAt,_that.contactName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecipientModel extends RecipientModel {
  const _RecipientModel({@JsonKey(name: '_id', includeIfNull: false) this.id = '', @JsonKey(name: 'phone_number') this.phoneNumber = '', this.username, @JsonKey(name: 'first_name') this.firstName, @JsonKey(name: 'last_name') this.lastName, @JsonKey(name: 'profile_picture_url') this.profilePictureUrl, this.about, @JsonKey(name: 'is_active') this.isActive = false, @JsonKey(name: 'is_online') this.isOnline = false, @JsonKey(name: 'last_seen') this.lastSeen, @JsonKey(name: 'is_subscribed') this.isSubscribed = false, @JsonKey(name: 'subscription_type') this.subscriptionType, @JsonKey(name: 'created_at') this.createdAt = '', @JsonKey(name: 'updated_at') this.updatedAt = '', @JsonKey(name: 'contactName') this.contactName}): super._();
  factory _RecipientModel.fromJson(Map<String, dynamic> json) => _$RecipientModelFromJson(json);

@override@JsonKey(name: '_id', includeIfNull: false) final  String id;
@override@JsonKey(name: 'phone_number') final  String phoneNumber;
@override final  String? username;
@override@JsonKey(name: 'first_name') final  String? firstName;
@override@JsonKey(name: 'last_name') final  String? lastName;
@override@JsonKey(name: 'profile_picture_url') final  String? profilePictureUrl;
@override final  String? about;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'is_online') final  bool isOnline;
@override@JsonKey(name: 'last_seen') final  String? lastSeen;
@override@JsonKey(name: 'is_subscribed') final  bool isSubscribed;
@override@JsonKey(name: 'subscription_type') final  String? subscriptionType;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'updated_at') final  String updatedAt;
@override@JsonKey(name: 'contactName') final  String? contactName;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipientModel&&(identical(other.id, id) || other.id == id)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.username, username) || other.username == username)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl)&&(identical(other.about, about) || other.about == about)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen)&&(identical(other.isSubscribed, isSubscribed) || other.isSubscribed == isSubscribed)&&(identical(other.subscriptionType, subscriptionType) || other.subscriptionType == subscriptionType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.contactName, contactName) || other.contactName == contactName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,phoneNumber,username,firstName,lastName,profilePictureUrl,about,isActive,isOnline,lastSeen,isSubscribed,subscriptionType,createdAt,updatedAt,contactName);

@override
String toString() {
  return 'RecipientModel(id: $id, phoneNumber: $phoneNumber, username: $username, firstName: $firstName, lastName: $lastName, profilePictureUrl: $profilePictureUrl, about: $about, isActive: $isActive, isOnline: $isOnline, lastSeen: $lastSeen, isSubscribed: $isSubscribed, subscriptionType: $subscriptionType, createdAt: $createdAt, updatedAt: $updatedAt, contactName: $contactName)';
}


}

/// @nodoc
abstract mixin class _$RecipientModelCopyWith<$Res> implements $RecipientModelCopyWith<$Res> {
  factory _$RecipientModelCopyWith(_RecipientModel value, $Res Function(_RecipientModel) _then) = __$RecipientModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '_id', includeIfNull: false) String id,@JsonKey(name: 'phone_number') String phoneNumber, String? username,@JsonKey(name: 'first_name') String? firstName,@JsonKey(name: 'last_name') String? lastName,@JsonKey(name: 'profile_picture_url') String? profilePictureUrl, String? about,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'is_online') bool isOnline,@JsonKey(name: 'last_seen') String? lastSeen,@JsonKey(name: 'is_subscribed') bool isSubscribed,@JsonKey(name: 'subscription_type') String? subscriptionType,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt,@JsonKey(name: 'contactName') String? contactName
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? phoneNumber = null,Object? username = freezed,Object? firstName = freezed,Object? lastName = freezed,Object? profilePictureUrl = freezed,Object? about = freezed,Object? isActive = null,Object? isOnline = null,Object? lastSeen = freezed,Object? isSubscribed = null,Object? subscriptionType = freezed,Object? createdAt = null,Object? updatedAt = null,Object? contactName = freezed,}) {
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
as bool,subscriptionType: freezed == subscriptionType ? _self.subscriptionType : subscriptionType // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,contactName: freezed == contactName ? _self.contactName : contactName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
