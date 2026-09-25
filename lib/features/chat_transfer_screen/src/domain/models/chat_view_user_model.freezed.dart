// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_view_user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatViewUserModel {

 String get id; String get username; String get phoneNumber; String get name;@JsonKey(name: 'profilePictureUrl') String? get profilePictureUrl; bool get isSubscribed; String? get subscriptionType;
/// Create a copy of ChatViewUserModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatViewUserModelCopyWith<ChatViewUserModel> get copyWith => _$ChatViewUserModelCopyWithImpl<ChatViewUserModel>(this as ChatViewUserModel, _$identity);

  /// Serializes this ChatViewUserModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatViewUserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.name, name) || other.name == name)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl)&&(identical(other.isSubscribed, isSubscribed) || other.isSubscribed == isSubscribed)&&(identical(other.subscriptionType, subscriptionType) || other.subscriptionType == subscriptionType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,phoneNumber,name,profilePictureUrl,isSubscribed,subscriptionType);

@override
String toString() {
  return 'ChatViewUserModel(id: $id, username: $username, phoneNumber: $phoneNumber, name: $name, profilePictureUrl: $profilePictureUrl, isSubscribed: $isSubscribed, subscriptionType: $subscriptionType)';
}


}

/// @nodoc
abstract mixin class $ChatViewUserModelCopyWith<$Res>  {
  factory $ChatViewUserModelCopyWith(ChatViewUserModel value, $Res Function(ChatViewUserModel) _then) = _$ChatViewUserModelCopyWithImpl;
@useResult
$Res call({
 String id, String username, String phoneNumber, String name,@JsonKey(name: 'profilePictureUrl') String? profilePictureUrl, bool isSubscribed, String? subscriptionType
});




}
/// @nodoc
class _$ChatViewUserModelCopyWithImpl<$Res>
    implements $ChatViewUserModelCopyWith<$Res> {
  _$ChatViewUserModelCopyWithImpl(this._self, this._then);

  final ChatViewUserModel _self;
  final $Res Function(ChatViewUserModel) _then;

/// Create a copy of ChatViewUserModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? username = null,Object? phoneNumber = null,Object? name = null,Object? profilePictureUrl = freezed,Object? isSubscribed = null,Object? subscriptionType = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,isSubscribed: null == isSubscribed ? _self.isSubscribed : isSubscribed // ignore: cast_nullable_to_non_nullable
as bool,subscriptionType: freezed == subscriptionType ? _self.subscriptionType : subscriptionType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatViewUserModel].
extension ChatViewUserModelPatterns on ChatViewUserModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatViewUserModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatViewUserModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatViewUserModel value)  $default,){
final _that = this;
switch (_that) {
case _ChatViewUserModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatViewUserModel value)?  $default,){
final _that = this;
switch (_that) {
case _ChatViewUserModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String username,  String phoneNumber,  String name, @JsonKey(name: 'profilePictureUrl')  String? profilePictureUrl,  bool isSubscribed,  String? subscriptionType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatViewUserModel() when $default != null:
return $default(_that.id,_that.username,_that.phoneNumber,_that.name,_that.profilePictureUrl,_that.isSubscribed,_that.subscriptionType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String username,  String phoneNumber,  String name, @JsonKey(name: 'profilePictureUrl')  String? profilePictureUrl,  bool isSubscribed,  String? subscriptionType)  $default,) {final _that = this;
switch (_that) {
case _ChatViewUserModel():
return $default(_that.id,_that.username,_that.phoneNumber,_that.name,_that.profilePictureUrl,_that.isSubscribed,_that.subscriptionType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String username,  String phoneNumber,  String name, @JsonKey(name: 'profilePictureUrl')  String? profilePictureUrl,  bool isSubscribed,  String? subscriptionType)?  $default,) {final _that = this;
switch (_that) {
case _ChatViewUserModel() when $default != null:
return $default(_that.id,_that.username,_that.phoneNumber,_that.name,_that.profilePictureUrl,_that.isSubscribed,_that.subscriptionType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatViewUserModel implements ChatViewUserModel {
  const _ChatViewUserModel({this.id = '', this.username = '', this.phoneNumber = '', this.name = '', @JsonKey(name: 'profilePictureUrl') this.profilePictureUrl, this.isSubscribed = false, this.subscriptionType});
  factory _ChatViewUserModel.fromJson(Map<String, dynamic> json) => _$ChatViewUserModelFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String username;
@override@JsonKey() final  String phoneNumber;
@override@JsonKey() final  String name;
@override@JsonKey(name: 'profilePictureUrl') final  String? profilePictureUrl;
@override@JsonKey() final  bool isSubscribed;
@override final  String? subscriptionType;

/// Create a copy of ChatViewUserModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatViewUserModelCopyWith<_ChatViewUserModel> get copyWith => __$ChatViewUserModelCopyWithImpl<_ChatViewUserModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatViewUserModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatViewUserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.name, name) || other.name == name)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl)&&(identical(other.isSubscribed, isSubscribed) || other.isSubscribed == isSubscribed)&&(identical(other.subscriptionType, subscriptionType) || other.subscriptionType == subscriptionType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,phoneNumber,name,profilePictureUrl,isSubscribed,subscriptionType);

@override
String toString() {
  return 'ChatViewUserModel(id: $id, username: $username, phoneNumber: $phoneNumber, name: $name, profilePictureUrl: $profilePictureUrl, isSubscribed: $isSubscribed, subscriptionType: $subscriptionType)';
}


}

/// @nodoc
abstract mixin class _$ChatViewUserModelCopyWith<$Res> implements $ChatViewUserModelCopyWith<$Res> {
  factory _$ChatViewUserModelCopyWith(_ChatViewUserModel value, $Res Function(_ChatViewUserModel) _then) = __$ChatViewUserModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String username, String phoneNumber, String name,@JsonKey(name: 'profilePictureUrl') String? profilePictureUrl, bool isSubscribed, String? subscriptionType
});




}
/// @nodoc
class __$ChatViewUserModelCopyWithImpl<$Res>
    implements _$ChatViewUserModelCopyWith<$Res> {
  __$ChatViewUserModelCopyWithImpl(this._self, this._then);

  final _ChatViewUserModel _self;
  final $Res Function(_ChatViewUserModel) _then;

/// Create a copy of ChatViewUserModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = null,Object? phoneNumber = null,Object? name = null,Object? profilePictureUrl = freezed,Object? isSubscribed = null,Object? subscriptionType = freezed,}) {
  return _then(_ChatViewUserModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,isSubscribed: null == isSubscribed ? _self.isSubscribed : isSubscribed // ignore: cast_nullable_to_non_nullable
as bool,subscriptionType: freezed == subscriptionType ? _self.subscriptionType : subscriptionType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
