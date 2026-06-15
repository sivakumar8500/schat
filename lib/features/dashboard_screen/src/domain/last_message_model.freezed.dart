// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'last_message_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LastMessageModel {

 String get id;@JsonKey(name: "conversation_id") String get conversationId;@JsonKey(name: "sender_id") String get senderId; String get content;@JsonKey(name: "media_url") String? get mediaUrl;@JsonKey(name: "media_type") String? get mediaType;@JsonKey(name: "is_deleted") bool get isDeleted;@JsonKey(name: "created_at") String get createdAt;@JsonKey(name: "updated_at") String get updatedAt;
/// Create a copy of LastMessageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LastMessageModelCopyWith<LastMessageModel> get copyWith => _$LastMessageModelCopyWithImpl<LastMessageModel>(this as LastMessageModel, _$identity);

  /// Serializes this LastMessageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LastMessageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.content, content) || other.content == content)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,conversationId,senderId,content,mediaUrl,mediaType,isDeleted,createdAt,updatedAt);

@override
String toString() {
  return 'LastMessageModel(id: $id, conversationId: $conversationId, senderId: $senderId, content: $content, mediaUrl: $mediaUrl, mediaType: $mediaType, isDeleted: $isDeleted, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $LastMessageModelCopyWith<$Res>  {
  factory $LastMessageModelCopyWith(LastMessageModel value, $Res Function(LastMessageModel) _then) = _$LastMessageModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: "conversation_id") String conversationId,@JsonKey(name: "sender_id") String senderId, String content,@JsonKey(name: "media_url") String? mediaUrl,@JsonKey(name: "media_type") String? mediaType,@JsonKey(name: "is_deleted") bool isDeleted,@JsonKey(name: "created_at") String createdAt,@JsonKey(name: "updated_at") String updatedAt
});




}
/// @nodoc
class _$LastMessageModelCopyWithImpl<$Res>
    implements $LastMessageModelCopyWith<$Res> {
  _$LastMessageModelCopyWithImpl(this._self, this._then);

  final LastMessageModel _self;
  final $Res Function(LastMessageModel) _then;

/// Create a copy of LastMessageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? conversationId = null,Object? senderId = null,Object? content = null,Object? mediaUrl = freezed,Object? mediaType = freezed,Object? isDeleted = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,mediaType: freezed == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LastMessageModel].
extension LastMessageModelPatterns on LastMessageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LastMessageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LastMessageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LastMessageModel value)  $default,){
final _that = this;
switch (_that) {
case _LastMessageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LastMessageModel value)?  $default,){
final _that = this;
switch (_that) {
case _LastMessageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: "conversation_id")  String conversationId, @JsonKey(name: "sender_id")  String senderId,  String content, @JsonKey(name: "media_url")  String? mediaUrl, @JsonKey(name: "media_type")  String? mediaType, @JsonKey(name: "is_deleted")  bool isDeleted, @JsonKey(name: "created_at")  String createdAt, @JsonKey(name: "updated_at")  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LastMessageModel() when $default != null:
return $default(_that.id,_that.conversationId,_that.senderId,_that.content,_that.mediaUrl,_that.mediaType,_that.isDeleted,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: "conversation_id")  String conversationId, @JsonKey(name: "sender_id")  String senderId,  String content, @JsonKey(name: "media_url")  String? mediaUrl, @JsonKey(name: "media_type")  String? mediaType, @JsonKey(name: "is_deleted")  bool isDeleted, @JsonKey(name: "created_at")  String createdAt, @JsonKey(name: "updated_at")  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _LastMessageModel():
return $default(_that.id,_that.conversationId,_that.senderId,_that.content,_that.mediaUrl,_that.mediaType,_that.isDeleted,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: "conversation_id")  String conversationId, @JsonKey(name: "sender_id")  String senderId,  String content, @JsonKey(name: "media_url")  String? mediaUrl, @JsonKey(name: "media_type")  String? mediaType, @JsonKey(name: "is_deleted")  bool isDeleted, @JsonKey(name: "created_at")  String createdAt, @JsonKey(name: "updated_at")  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _LastMessageModel() when $default != null:
return $default(_that.id,_that.conversationId,_that.senderId,_that.content,_that.mediaUrl,_that.mediaType,_that.isDeleted,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LastMessageModel implements LastMessageModel {
  const _LastMessageModel({required this.id, @JsonKey(name: "conversation_id") required this.conversationId, @JsonKey(name: "sender_id") required this.senderId, required this.content, @JsonKey(name: "media_url") this.mediaUrl, @JsonKey(name: "media_type") this.mediaType, @JsonKey(name: "is_deleted") required this.isDeleted, @JsonKey(name: "created_at") required this.createdAt, @JsonKey(name: "updated_at") required this.updatedAt});
  factory _LastMessageModel.fromJson(Map<String, dynamic> json) => _$LastMessageModelFromJson(json);

@override final  String id;
@override@JsonKey(name: "conversation_id") final  String conversationId;
@override@JsonKey(name: "sender_id") final  String senderId;
@override final  String content;
@override@JsonKey(name: "media_url") final  String? mediaUrl;
@override@JsonKey(name: "media_type") final  String? mediaType;
@override@JsonKey(name: "is_deleted") final  bool isDeleted;
@override@JsonKey(name: "created_at") final  String createdAt;
@override@JsonKey(name: "updated_at") final  String updatedAt;

/// Create a copy of LastMessageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LastMessageModelCopyWith<_LastMessageModel> get copyWith => __$LastMessageModelCopyWithImpl<_LastMessageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LastMessageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LastMessageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.content, content) || other.content == content)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,conversationId,senderId,content,mediaUrl,mediaType,isDeleted,createdAt,updatedAt);

@override
String toString() {
  return 'LastMessageModel(id: $id, conversationId: $conversationId, senderId: $senderId, content: $content, mediaUrl: $mediaUrl, mediaType: $mediaType, isDeleted: $isDeleted, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$LastMessageModelCopyWith<$Res> implements $LastMessageModelCopyWith<$Res> {
  factory _$LastMessageModelCopyWith(_LastMessageModel value, $Res Function(_LastMessageModel) _then) = __$LastMessageModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: "conversation_id") String conversationId,@JsonKey(name: "sender_id") String senderId, String content,@JsonKey(name: "media_url") String? mediaUrl,@JsonKey(name: "media_type") String? mediaType,@JsonKey(name: "is_deleted") bool isDeleted,@JsonKey(name: "created_at") String createdAt,@JsonKey(name: "updated_at") String updatedAt
});




}
/// @nodoc
class __$LastMessageModelCopyWithImpl<$Res>
    implements _$LastMessageModelCopyWith<$Res> {
  __$LastMessageModelCopyWithImpl(this._self, this._then);

  final _LastMessageModel _self;
  final $Res Function(_LastMessageModel) _then;

/// Create a copy of LastMessageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? conversationId = null,Object? senderId = null,Object? content = null,Object? mediaUrl = freezed,Object? mediaType = freezed,Object? isDeleted = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_LastMessageModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,mediaType: freezed == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
