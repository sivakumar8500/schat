// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'call_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CallHistoryModel {

@JsonKey(name: '_id') String get id;@JsonKey(name: 'conversation_id') String? get conversationId;@JsonKey(name: 'caller_id') String? get callerId;@JsonKey(name: 'caller_name') String? get callerName;@JsonKey(name: 'caller_avatar') String? get callerAvatar;@JsonKey(name: 'receiver_id') String? get receiverId;@JsonKey(name: 'receiver_name') String? get receiverName;@JsonKey(name: 'receiver_avatar') String? get receiverAvatar;@JsonKey(name: 'call_type') String get callType;@JsonKey(name: 'status') String get status;@JsonKey(name: 'direction') String get direction;@JsonKey(name: 'created_at') String? get createdAt;@JsonKey(name: 'duration') int get duration;@JsonKey(name: 'count') int get count;
/// Create a copy of CallHistoryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallHistoryModelCopyWith<CallHistoryModel> get copyWith => _$CallHistoryModelCopyWithImpl<CallHistoryModel>(this as CallHistoryModel, _$identity);

  /// Serializes this CallHistoryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallHistoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.callerId, callerId) || other.callerId == callerId)&&(identical(other.callerName, callerName) || other.callerName == callerName)&&(identical(other.callerAvatar, callerAvatar) || other.callerAvatar == callerAvatar)&&(identical(other.receiverId, receiverId) || other.receiverId == receiverId)&&(identical(other.receiverName, receiverName) || other.receiverName == receiverName)&&(identical(other.receiverAvatar, receiverAvatar) || other.receiverAvatar == receiverAvatar)&&(identical(other.callType, callType) || other.callType == callType)&&(identical(other.status, status) || other.status == status)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,conversationId,callerId,callerName,callerAvatar,receiverId,receiverName,receiverAvatar,callType,status,direction,createdAt,duration,count);

@override
String toString() {
  return 'CallHistoryModel(id: $id, conversationId: $conversationId, callerId: $callerId, callerName: $callerName, callerAvatar: $callerAvatar, receiverId: $receiverId, receiverName: $receiverName, receiverAvatar: $receiverAvatar, callType: $callType, status: $status, direction: $direction, createdAt: $createdAt, duration: $duration, count: $count)';
}


}

/// @nodoc
abstract mixin class $CallHistoryModelCopyWith<$Res>  {
  factory $CallHistoryModelCopyWith(CallHistoryModel value, $Res Function(CallHistoryModel) _then) = _$CallHistoryModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '_id') String id,@JsonKey(name: 'conversation_id') String? conversationId,@JsonKey(name: 'caller_id') String? callerId,@JsonKey(name: 'caller_name') String? callerName,@JsonKey(name: 'caller_avatar') String? callerAvatar,@JsonKey(name: 'receiver_id') String? receiverId,@JsonKey(name: 'receiver_name') String? receiverName,@JsonKey(name: 'receiver_avatar') String? receiverAvatar,@JsonKey(name: 'call_type') String callType,@JsonKey(name: 'status') String status,@JsonKey(name: 'direction') String direction,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'duration') int duration,@JsonKey(name: 'count') int count
});




}
/// @nodoc
class _$CallHistoryModelCopyWithImpl<$Res>
    implements $CallHistoryModelCopyWith<$Res> {
  _$CallHistoryModelCopyWithImpl(this._self, this._then);

  final CallHistoryModel _self;
  final $Res Function(CallHistoryModel) _then;

/// Create a copy of CallHistoryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? conversationId = freezed,Object? callerId = freezed,Object? callerName = freezed,Object? callerAvatar = freezed,Object? receiverId = freezed,Object? receiverName = freezed,Object? receiverAvatar = freezed,Object? callType = null,Object? status = null,Object? direction = null,Object? createdAt = freezed,Object? duration = null,Object? count = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversationId: freezed == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String?,callerId: freezed == callerId ? _self.callerId : callerId // ignore: cast_nullable_to_non_nullable
as String?,callerName: freezed == callerName ? _self.callerName : callerName // ignore: cast_nullable_to_non_nullable
as String?,callerAvatar: freezed == callerAvatar ? _self.callerAvatar : callerAvatar // ignore: cast_nullable_to_non_nullable
as String?,receiverId: freezed == receiverId ? _self.receiverId : receiverId // ignore: cast_nullable_to_non_nullable
as String?,receiverName: freezed == receiverName ? _self.receiverName : receiverName // ignore: cast_nullable_to_non_nullable
as String?,receiverAvatar: freezed == receiverAvatar ? _self.receiverAvatar : receiverAvatar // ignore: cast_nullable_to_non_nullable
as String?,callType: null == callType ? _self.callType : callType // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CallHistoryModel].
extension CallHistoryModelPatterns on CallHistoryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CallHistoryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CallHistoryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CallHistoryModel value)  $default,){
final _that = this;
switch (_that) {
case _CallHistoryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CallHistoryModel value)?  $default,){
final _that = this;
switch (_that) {
case _CallHistoryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id, @JsonKey(name: 'conversation_id')  String? conversationId, @JsonKey(name: 'caller_id')  String? callerId, @JsonKey(name: 'caller_name')  String? callerName, @JsonKey(name: 'caller_avatar')  String? callerAvatar, @JsonKey(name: 'receiver_id')  String? receiverId, @JsonKey(name: 'receiver_name')  String? receiverName, @JsonKey(name: 'receiver_avatar')  String? receiverAvatar, @JsonKey(name: 'call_type')  String callType, @JsonKey(name: 'status')  String status, @JsonKey(name: 'direction')  String direction, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'duration')  int duration, @JsonKey(name: 'count')  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CallHistoryModel() when $default != null:
return $default(_that.id,_that.conversationId,_that.callerId,_that.callerName,_that.callerAvatar,_that.receiverId,_that.receiverName,_that.receiverAvatar,_that.callType,_that.status,_that.direction,_that.createdAt,_that.duration,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id, @JsonKey(name: 'conversation_id')  String? conversationId, @JsonKey(name: 'caller_id')  String? callerId, @JsonKey(name: 'caller_name')  String? callerName, @JsonKey(name: 'caller_avatar')  String? callerAvatar, @JsonKey(name: 'receiver_id')  String? receiverId, @JsonKey(name: 'receiver_name')  String? receiverName, @JsonKey(name: 'receiver_avatar')  String? receiverAvatar, @JsonKey(name: 'call_type')  String callType, @JsonKey(name: 'status')  String status, @JsonKey(name: 'direction')  String direction, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'duration')  int duration, @JsonKey(name: 'count')  int count)  $default,) {final _that = this;
switch (_that) {
case _CallHistoryModel():
return $default(_that.id,_that.conversationId,_that.callerId,_that.callerName,_that.callerAvatar,_that.receiverId,_that.receiverName,_that.receiverAvatar,_that.callType,_that.status,_that.direction,_that.createdAt,_that.duration,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '_id')  String id, @JsonKey(name: 'conversation_id')  String? conversationId, @JsonKey(name: 'caller_id')  String? callerId, @JsonKey(name: 'caller_name')  String? callerName, @JsonKey(name: 'caller_avatar')  String? callerAvatar, @JsonKey(name: 'receiver_id')  String? receiverId, @JsonKey(name: 'receiver_name')  String? receiverName, @JsonKey(name: 'receiver_avatar')  String? receiverAvatar, @JsonKey(name: 'call_type')  String callType, @JsonKey(name: 'status')  String status, @JsonKey(name: 'direction')  String direction, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'duration')  int duration, @JsonKey(name: 'count')  int count)?  $default,) {final _that = this;
switch (_that) {
case _CallHistoryModel() when $default != null:
return $default(_that.id,_that.conversationId,_that.callerId,_that.callerName,_that.callerAvatar,_that.receiverId,_that.receiverName,_that.receiverAvatar,_that.callType,_that.status,_that.direction,_that.createdAt,_that.duration,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CallHistoryModel extends CallHistoryModel {
  const _CallHistoryModel({@JsonKey(name: '_id') this.id = '', @JsonKey(name: 'conversation_id') this.conversationId, @JsonKey(name: 'caller_id') this.callerId, @JsonKey(name: 'caller_name') this.callerName, @JsonKey(name: 'caller_avatar') this.callerAvatar, @JsonKey(name: 'receiver_id') this.receiverId, @JsonKey(name: 'receiver_name') this.receiverName, @JsonKey(name: 'receiver_avatar') this.receiverAvatar, @JsonKey(name: 'call_type') this.callType = 'audio', @JsonKey(name: 'status') this.status = 'completed', @JsonKey(name: 'direction') this.direction = 'incoming', @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'duration') this.duration = 0, @JsonKey(name: 'count') this.count = 1}): super._();
  factory _CallHistoryModel.fromJson(Map<String, dynamic> json) => _$CallHistoryModelFromJson(json);

@override@JsonKey(name: '_id') final  String id;
@override@JsonKey(name: 'conversation_id') final  String? conversationId;
@override@JsonKey(name: 'caller_id') final  String? callerId;
@override@JsonKey(name: 'caller_name') final  String? callerName;
@override@JsonKey(name: 'caller_avatar') final  String? callerAvatar;
@override@JsonKey(name: 'receiver_id') final  String? receiverId;
@override@JsonKey(name: 'receiver_name') final  String? receiverName;
@override@JsonKey(name: 'receiver_avatar') final  String? receiverAvatar;
@override@JsonKey(name: 'call_type') final  String callType;
@override@JsonKey(name: 'status') final  String status;
@override@JsonKey(name: 'direction') final  String direction;
@override@JsonKey(name: 'created_at') final  String? createdAt;
@override@JsonKey(name: 'duration') final  int duration;
@override@JsonKey(name: 'count') final  int count;

/// Create a copy of CallHistoryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CallHistoryModelCopyWith<_CallHistoryModel> get copyWith => __$CallHistoryModelCopyWithImpl<_CallHistoryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CallHistoryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CallHistoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.callerId, callerId) || other.callerId == callerId)&&(identical(other.callerName, callerName) || other.callerName == callerName)&&(identical(other.callerAvatar, callerAvatar) || other.callerAvatar == callerAvatar)&&(identical(other.receiverId, receiverId) || other.receiverId == receiverId)&&(identical(other.receiverName, receiverName) || other.receiverName == receiverName)&&(identical(other.receiverAvatar, receiverAvatar) || other.receiverAvatar == receiverAvatar)&&(identical(other.callType, callType) || other.callType == callType)&&(identical(other.status, status) || other.status == status)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,conversationId,callerId,callerName,callerAvatar,receiverId,receiverName,receiverAvatar,callType,status,direction,createdAt,duration,count);

@override
String toString() {
  return 'CallHistoryModel(id: $id, conversationId: $conversationId, callerId: $callerId, callerName: $callerName, callerAvatar: $callerAvatar, receiverId: $receiverId, receiverName: $receiverName, receiverAvatar: $receiverAvatar, callType: $callType, status: $status, direction: $direction, createdAt: $createdAt, duration: $duration, count: $count)';
}


}

/// @nodoc
abstract mixin class _$CallHistoryModelCopyWith<$Res> implements $CallHistoryModelCopyWith<$Res> {
  factory _$CallHistoryModelCopyWith(_CallHistoryModel value, $Res Function(_CallHistoryModel) _then) = __$CallHistoryModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '_id') String id,@JsonKey(name: 'conversation_id') String? conversationId,@JsonKey(name: 'caller_id') String? callerId,@JsonKey(name: 'caller_name') String? callerName,@JsonKey(name: 'caller_avatar') String? callerAvatar,@JsonKey(name: 'receiver_id') String? receiverId,@JsonKey(name: 'receiver_name') String? receiverName,@JsonKey(name: 'receiver_avatar') String? receiverAvatar,@JsonKey(name: 'call_type') String callType,@JsonKey(name: 'status') String status,@JsonKey(name: 'direction') String direction,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'duration') int duration,@JsonKey(name: 'count') int count
});




}
/// @nodoc
class __$CallHistoryModelCopyWithImpl<$Res>
    implements _$CallHistoryModelCopyWith<$Res> {
  __$CallHistoryModelCopyWithImpl(this._self, this._then);

  final _CallHistoryModel _self;
  final $Res Function(_CallHistoryModel) _then;

/// Create a copy of CallHistoryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? conversationId = freezed,Object? callerId = freezed,Object? callerName = freezed,Object? callerAvatar = freezed,Object? receiverId = freezed,Object? receiverName = freezed,Object? receiverAvatar = freezed,Object? callType = null,Object? status = null,Object? direction = null,Object? createdAt = freezed,Object? duration = null,Object? count = null,}) {
  return _then(_CallHistoryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversationId: freezed == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String?,callerId: freezed == callerId ? _self.callerId : callerId // ignore: cast_nullable_to_non_nullable
as String?,callerName: freezed == callerName ? _self.callerName : callerName // ignore: cast_nullable_to_non_nullable
as String?,callerAvatar: freezed == callerAvatar ? _self.callerAvatar : callerAvatar // ignore: cast_nullable_to_non_nullable
as String?,receiverId: freezed == receiverId ? _self.receiverId : receiverId // ignore: cast_nullable_to_non_nullable
as String?,receiverName: freezed == receiverName ? _self.receiverName : receiverName // ignore: cast_nullable_to_non_nullable
as String?,receiverAvatar: freezed == receiverAvatar ? _self.receiverAvatar : receiverAvatar // ignore: cast_nullable_to_non_nullable
as String?,callType: null == callType ? _self.callType : callType // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
