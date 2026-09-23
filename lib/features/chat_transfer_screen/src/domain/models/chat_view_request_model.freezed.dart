// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_view_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatViewRequestModel {

 String get id; String get senderId; String get receiverId; String get status; String? get sharedConversationId; String? get sharedAccessToken; String? get sharedRefreshToken; ChatViewUserModel? get sender; ChatViewUserModel? get receiver; String? get createdAt; String? get updatedAt;
/// Create a copy of ChatViewRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatViewRequestModelCopyWith<ChatViewRequestModel> get copyWith => _$ChatViewRequestModelCopyWithImpl<ChatViewRequestModel>(this as ChatViewRequestModel, _$identity);

  /// Serializes this ChatViewRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatViewRequestModel&&(identical(other.id, id) || other.id == id)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.receiverId, receiverId) || other.receiverId == receiverId)&&(identical(other.status, status) || other.status == status)&&(identical(other.sharedConversationId, sharedConversationId) || other.sharedConversationId == sharedConversationId)&&(identical(other.sharedAccessToken, sharedAccessToken) || other.sharedAccessToken == sharedAccessToken)&&(identical(other.sharedRefreshToken, sharedRefreshToken) || other.sharedRefreshToken == sharedRefreshToken)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.receiver, receiver) || other.receiver == receiver)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,senderId,receiverId,status,sharedConversationId,sharedAccessToken,sharedRefreshToken,sender,receiver,createdAt,updatedAt);

@override
String toString() {
  return 'ChatViewRequestModel(id: $id, senderId: $senderId, receiverId: $receiverId, status: $status, sharedConversationId: $sharedConversationId, sharedAccessToken: $sharedAccessToken, sharedRefreshToken: $sharedRefreshToken, sender: $sender, receiver: $receiver, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ChatViewRequestModelCopyWith<$Res>  {
  factory $ChatViewRequestModelCopyWith(ChatViewRequestModel value, $Res Function(ChatViewRequestModel) _then) = _$ChatViewRequestModelCopyWithImpl;
@useResult
$Res call({
 String id, String senderId, String receiverId, String status, String? sharedConversationId, String? sharedAccessToken, String? sharedRefreshToken, ChatViewUserModel? sender, ChatViewUserModel? receiver, String? createdAt, String? updatedAt
});


$ChatViewUserModelCopyWith<$Res>? get sender;$ChatViewUserModelCopyWith<$Res>? get receiver;

}
/// @nodoc
class _$ChatViewRequestModelCopyWithImpl<$Res>
    implements $ChatViewRequestModelCopyWith<$Res> {
  _$ChatViewRequestModelCopyWithImpl(this._self, this._then);

  final ChatViewRequestModel _self;
  final $Res Function(ChatViewRequestModel) _then;

/// Create a copy of ChatViewRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? senderId = null,Object? receiverId = null,Object? status = null,Object? sharedConversationId = freezed,Object? sharedAccessToken = freezed,Object? sharedRefreshToken = freezed,Object? sender = freezed,Object? receiver = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,receiverId: null == receiverId ? _self.receiverId : receiverId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,sharedConversationId: freezed == sharedConversationId ? _self.sharedConversationId : sharedConversationId // ignore: cast_nullable_to_non_nullable
as String?,sharedAccessToken: freezed == sharedAccessToken ? _self.sharedAccessToken : sharedAccessToken // ignore: cast_nullable_to_non_nullable
as String?,sharedRefreshToken: freezed == sharedRefreshToken ? _self.sharedRefreshToken : sharedRefreshToken // ignore: cast_nullable_to_non_nullable
as String?,sender: freezed == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as ChatViewUserModel?,receiver: freezed == receiver ? _self.receiver : receiver // ignore: cast_nullable_to_non_nullable
as ChatViewUserModel?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ChatViewRequestModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatViewUserModelCopyWith<$Res>? get sender {
    if (_self.sender == null) {
    return null;
  }

  return $ChatViewUserModelCopyWith<$Res>(_self.sender!, (value) {
    return _then(_self.copyWith(sender: value));
  });
}/// Create a copy of ChatViewRequestModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatViewUserModelCopyWith<$Res>? get receiver {
    if (_self.receiver == null) {
    return null;
  }

  return $ChatViewUserModelCopyWith<$Res>(_self.receiver!, (value) {
    return _then(_self.copyWith(receiver: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatViewRequestModel].
extension ChatViewRequestModelPatterns on ChatViewRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatViewRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatViewRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatViewRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _ChatViewRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatViewRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _ChatViewRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String senderId,  String receiverId,  String status,  String? sharedConversationId,  String? sharedAccessToken,  String? sharedRefreshToken,  ChatViewUserModel? sender,  ChatViewUserModel? receiver,  String? createdAt,  String? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatViewRequestModel() when $default != null:
return $default(_that.id,_that.senderId,_that.receiverId,_that.status,_that.sharedConversationId,_that.sharedAccessToken,_that.sharedRefreshToken,_that.sender,_that.receiver,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String senderId,  String receiverId,  String status,  String? sharedConversationId,  String? sharedAccessToken,  String? sharedRefreshToken,  ChatViewUserModel? sender,  ChatViewUserModel? receiver,  String? createdAt,  String? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ChatViewRequestModel():
return $default(_that.id,_that.senderId,_that.receiverId,_that.status,_that.sharedConversationId,_that.sharedAccessToken,_that.sharedRefreshToken,_that.sender,_that.receiver,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String senderId,  String receiverId,  String status,  String? sharedConversationId,  String? sharedAccessToken,  String? sharedRefreshToken,  ChatViewUserModel? sender,  ChatViewUserModel? receiver,  String? createdAt,  String? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ChatViewRequestModel() when $default != null:
return $default(_that.id,_that.senderId,_that.receiverId,_that.status,_that.sharedConversationId,_that.sharedAccessToken,_that.sharedRefreshToken,_that.sender,_that.receiver,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatViewRequestModel implements ChatViewRequestModel {
  const _ChatViewRequestModel({this.id = '', this.senderId = '', this.receiverId = '', this.status = 'pending', this.sharedConversationId, this.sharedAccessToken, this.sharedRefreshToken, this.sender, this.receiver, this.createdAt, this.updatedAt});
  factory _ChatViewRequestModel.fromJson(Map<String, dynamic> json) => _$ChatViewRequestModelFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String senderId;
@override@JsonKey() final  String receiverId;
@override@JsonKey() final  String status;
@override final  String? sharedConversationId;
@override final  String? sharedAccessToken;
@override final  String? sharedRefreshToken;
@override final  ChatViewUserModel? sender;
@override final  ChatViewUserModel? receiver;
@override final  String? createdAt;
@override final  String? updatedAt;

/// Create a copy of ChatViewRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatViewRequestModelCopyWith<_ChatViewRequestModel> get copyWith => __$ChatViewRequestModelCopyWithImpl<_ChatViewRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatViewRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatViewRequestModel&&(identical(other.id, id) || other.id == id)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.receiverId, receiverId) || other.receiverId == receiverId)&&(identical(other.status, status) || other.status == status)&&(identical(other.sharedConversationId, sharedConversationId) || other.sharedConversationId == sharedConversationId)&&(identical(other.sharedAccessToken, sharedAccessToken) || other.sharedAccessToken == sharedAccessToken)&&(identical(other.sharedRefreshToken, sharedRefreshToken) || other.sharedRefreshToken == sharedRefreshToken)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.receiver, receiver) || other.receiver == receiver)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,senderId,receiverId,status,sharedConversationId,sharedAccessToken,sharedRefreshToken,sender,receiver,createdAt,updatedAt);

@override
String toString() {
  return 'ChatViewRequestModel(id: $id, senderId: $senderId, receiverId: $receiverId, status: $status, sharedConversationId: $sharedConversationId, sharedAccessToken: $sharedAccessToken, sharedRefreshToken: $sharedRefreshToken, sender: $sender, receiver: $receiver, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ChatViewRequestModelCopyWith<$Res> implements $ChatViewRequestModelCopyWith<$Res> {
  factory _$ChatViewRequestModelCopyWith(_ChatViewRequestModel value, $Res Function(_ChatViewRequestModel) _then) = __$ChatViewRequestModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String senderId, String receiverId, String status, String? sharedConversationId, String? sharedAccessToken, String? sharedRefreshToken, ChatViewUserModel? sender, ChatViewUserModel? receiver, String? createdAt, String? updatedAt
});


@override $ChatViewUserModelCopyWith<$Res>? get sender;@override $ChatViewUserModelCopyWith<$Res>? get receiver;

}
/// @nodoc
class __$ChatViewRequestModelCopyWithImpl<$Res>
    implements _$ChatViewRequestModelCopyWith<$Res> {
  __$ChatViewRequestModelCopyWithImpl(this._self, this._then);

  final _ChatViewRequestModel _self;
  final $Res Function(_ChatViewRequestModel) _then;

/// Create a copy of ChatViewRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? senderId = null,Object? receiverId = null,Object? status = null,Object? sharedConversationId = freezed,Object? sharedAccessToken = freezed,Object? sharedRefreshToken = freezed,Object? sender = freezed,Object? receiver = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_ChatViewRequestModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,receiverId: null == receiverId ? _self.receiverId : receiverId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,sharedConversationId: freezed == sharedConversationId ? _self.sharedConversationId : sharedConversationId // ignore: cast_nullable_to_non_nullable
as String?,sharedAccessToken: freezed == sharedAccessToken ? _self.sharedAccessToken : sharedAccessToken // ignore: cast_nullable_to_non_nullable
as String?,sharedRefreshToken: freezed == sharedRefreshToken ? _self.sharedRefreshToken : sharedRefreshToken // ignore: cast_nullable_to_non_nullable
as String?,sender: freezed == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as ChatViewUserModel?,receiver: freezed == receiver ? _self.receiver : receiver // ignore: cast_nullable_to_non_nullable
as ChatViewUserModel?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ChatViewRequestModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatViewUserModelCopyWith<$Res>? get sender {
    if (_self.sender == null) {
    return null;
  }

  return $ChatViewUserModelCopyWith<$Res>(_self.sender!, (value) {
    return _then(_self.copyWith(sender: value));
  });
}/// Create a copy of ChatViewRequestModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatViewUserModelCopyWith<$Res>? get receiver {
    if (_self.receiver == null) {
    return null;
  }

  return $ChatViewUserModelCopyWith<$Res>(_self.receiver!, (value) {
    return _then(_self.copyWith(receiver: value));
  });
}
}

// dart format on
