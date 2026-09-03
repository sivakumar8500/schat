// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'status_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StatusItemModel {

 String get id;@JsonKey(name: 'userId') String? get userId;@JsonKey(name: 'statusType') String? get statusType;@JsonKey(name: 'textContent') String? get text;@JsonKey(name: 'mediaUrl') String? get imagePath;@JsonKey(name: 'createdAt') DateTime get timestamp;@JsonKey(name: 'expiresAt') DateTime? get expiresAt;@JsonKey(name: 'viewCount', defaultValue: 0) int? get viewCount;@JsonKey(name: 'viewers') List<StatusViewerModel> get viewers;@JsonKey(name: 'privacyType') String? get privacyType;@JsonKey(name: 'privacyUserIds') List<String>? get privacyUserIds;@JsonKey(includeFromJson: false, includeToJson: false) Color get backgroundColor;@JsonKey(includeFromJson: false, includeToJson: false) bool get viewed;
/// Create a copy of StatusItemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatusItemModelCopyWith<StatusItemModel> get copyWith => _$StatusItemModelCopyWithImpl<StatusItemModel>(this as StatusItemModel, _$identity);

  /// Serializes this StatusItemModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatusItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.statusType, statusType) || other.statusType == statusType)&&(identical(other.text, text) || other.text == text)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&const DeepCollectionEquality().equals(other.viewers, viewers)&&(identical(other.privacyType, privacyType) || other.privacyType == privacyType)&&const DeepCollectionEquality().equals(other.privacyUserIds, privacyUserIds)&&(identical(other.backgroundColor, backgroundColor) || other.backgroundColor == backgroundColor)&&(identical(other.viewed, viewed) || other.viewed == viewed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,statusType,text,imagePath,timestamp,expiresAt,viewCount,const DeepCollectionEquality().hash(viewers),privacyType,const DeepCollectionEquality().hash(privacyUserIds),backgroundColor,viewed);

@override
String toString() {
  return 'StatusItemModel(id: $id, userId: $userId, statusType: $statusType, text: $text, imagePath: $imagePath, timestamp: $timestamp, expiresAt: $expiresAt, viewCount: $viewCount, viewers: $viewers, privacyType: $privacyType, privacyUserIds: $privacyUserIds, backgroundColor: $backgroundColor, viewed: $viewed)';
}


}

/// @nodoc
abstract mixin class $StatusItemModelCopyWith<$Res>  {
  factory $StatusItemModelCopyWith(StatusItemModel value, $Res Function(StatusItemModel) _then) = _$StatusItemModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'userId') String? userId,@JsonKey(name: 'statusType') String? statusType,@JsonKey(name: 'textContent') String? text,@JsonKey(name: 'mediaUrl') String? imagePath,@JsonKey(name: 'createdAt') DateTime timestamp,@JsonKey(name: 'expiresAt') DateTime? expiresAt,@JsonKey(name: 'viewCount', defaultValue: 0) int? viewCount,@JsonKey(name: 'viewers') List<StatusViewerModel> viewers,@JsonKey(name: 'privacyType') String? privacyType,@JsonKey(name: 'privacyUserIds') List<String>? privacyUserIds,@JsonKey(includeFromJson: false, includeToJson: false) Color backgroundColor,@JsonKey(includeFromJson: false, includeToJson: false) bool viewed
});




}
/// @nodoc
class _$StatusItemModelCopyWithImpl<$Res>
    implements $StatusItemModelCopyWith<$Res> {
  _$StatusItemModelCopyWithImpl(this._self, this._then);

  final StatusItemModel _self;
  final $Res Function(StatusItemModel) _then;

/// Create a copy of StatusItemModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = freezed,Object? statusType = freezed,Object? text = freezed,Object? imagePath = freezed,Object? timestamp = null,Object? expiresAt = freezed,Object? viewCount = freezed,Object? viewers = null,Object? privacyType = freezed,Object? privacyUserIds = freezed,Object? backgroundColor = null,Object? viewed = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,statusType: freezed == statusType ? _self.statusType : statusType // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,imagePath: freezed == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,viewCount: freezed == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int?,viewers: null == viewers ? _self.viewers : viewers // ignore: cast_nullable_to_non_nullable
as List<StatusViewerModel>,privacyType: freezed == privacyType ? _self.privacyType : privacyType // ignore: cast_nullable_to_non_nullable
as String?,privacyUserIds: freezed == privacyUserIds ? _self.privacyUserIds : privacyUserIds // ignore: cast_nullable_to_non_nullable
as List<String>?,backgroundColor: null == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as Color,viewed: null == viewed ? _self.viewed : viewed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [StatusItemModel].
extension StatusItemModelPatterns on StatusItemModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatusItemModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatusItemModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatusItemModel value)  $default,){
final _that = this;
switch (_that) {
case _StatusItemModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatusItemModel value)?  $default,){
final _that = this;
switch (_that) {
case _StatusItemModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'userId')  String? userId, @JsonKey(name: 'statusType')  String? statusType, @JsonKey(name: 'textContent')  String? text, @JsonKey(name: 'mediaUrl')  String? imagePath, @JsonKey(name: 'createdAt')  DateTime timestamp, @JsonKey(name: 'expiresAt')  DateTime? expiresAt, @JsonKey(name: 'viewCount', defaultValue: 0)  int? viewCount, @JsonKey(name: 'viewers')  List<StatusViewerModel> viewers, @JsonKey(name: 'privacyType')  String? privacyType, @JsonKey(name: 'privacyUserIds')  List<String>? privacyUserIds, @JsonKey(includeFromJson: false, includeToJson: false)  Color backgroundColor, @JsonKey(includeFromJson: false, includeToJson: false)  bool viewed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatusItemModel() when $default != null:
return $default(_that.id,_that.userId,_that.statusType,_that.text,_that.imagePath,_that.timestamp,_that.expiresAt,_that.viewCount,_that.viewers,_that.privacyType,_that.privacyUserIds,_that.backgroundColor,_that.viewed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'userId')  String? userId, @JsonKey(name: 'statusType')  String? statusType, @JsonKey(name: 'textContent')  String? text, @JsonKey(name: 'mediaUrl')  String? imagePath, @JsonKey(name: 'createdAt')  DateTime timestamp, @JsonKey(name: 'expiresAt')  DateTime? expiresAt, @JsonKey(name: 'viewCount', defaultValue: 0)  int? viewCount, @JsonKey(name: 'viewers')  List<StatusViewerModel> viewers, @JsonKey(name: 'privacyType')  String? privacyType, @JsonKey(name: 'privacyUserIds')  List<String>? privacyUserIds, @JsonKey(includeFromJson: false, includeToJson: false)  Color backgroundColor, @JsonKey(includeFromJson: false, includeToJson: false)  bool viewed)  $default,) {final _that = this;
switch (_that) {
case _StatusItemModel():
return $default(_that.id,_that.userId,_that.statusType,_that.text,_that.imagePath,_that.timestamp,_that.expiresAt,_that.viewCount,_that.viewers,_that.privacyType,_that.privacyUserIds,_that.backgroundColor,_that.viewed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'userId')  String? userId, @JsonKey(name: 'statusType')  String? statusType, @JsonKey(name: 'textContent')  String? text, @JsonKey(name: 'mediaUrl')  String? imagePath, @JsonKey(name: 'createdAt')  DateTime timestamp, @JsonKey(name: 'expiresAt')  DateTime? expiresAt, @JsonKey(name: 'viewCount', defaultValue: 0)  int? viewCount, @JsonKey(name: 'viewers')  List<StatusViewerModel> viewers, @JsonKey(name: 'privacyType')  String? privacyType, @JsonKey(name: 'privacyUserIds')  List<String>? privacyUserIds, @JsonKey(includeFromJson: false, includeToJson: false)  Color backgroundColor, @JsonKey(includeFromJson: false, includeToJson: false)  bool viewed)?  $default,) {final _that = this;
switch (_that) {
case _StatusItemModel() when $default != null:
return $default(_that.id,_that.userId,_that.statusType,_that.text,_that.imagePath,_that.timestamp,_that.expiresAt,_that.viewCount,_that.viewers,_that.privacyType,_that.privacyUserIds,_that.backgroundColor,_that.viewed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatusItemModel implements StatusItemModel {
  const _StatusItemModel({required this.id, @JsonKey(name: 'userId') this.userId, @JsonKey(name: 'statusType') this.statusType, @JsonKey(name: 'textContent') this.text, @JsonKey(name: 'mediaUrl') this.imagePath, @JsonKey(name: 'createdAt') required this.timestamp, @JsonKey(name: 'expiresAt') this.expiresAt, @JsonKey(name: 'viewCount', defaultValue: 0) this.viewCount, @JsonKey(name: 'viewers') final  List<StatusViewerModel> viewers = const [], @JsonKey(name: 'privacyType') this.privacyType, @JsonKey(name: 'privacyUserIds') final  List<String>? privacyUserIds, @JsonKey(includeFromJson: false, includeToJson: false) this.backgroundColor = Colors.black, @JsonKey(includeFromJson: false, includeToJson: false) this.viewed = false}): _viewers = viewers,_privacyUserIds = privacyUserIds;
  factory _StatusItemModel.fromJson(Map<String, dynamic> json) => _$StatusItemModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'userId') final  String? userId;
@override@JsonKey(name: 'statusType') final  String? statusType;
@override@JsonKey(name: 'textContent') final  String? text;
@override@JsonKey(name: 'mediaUrl') final  String? imagePath;
@override@JsonKey(name: 'createdAt') final  DateTime timestamp;
@override@JsonKey(name: 'expiresAt') final  DateTime? expiresAt;
@override@JsonKey(name: 'viewCount', defaultValue: 0) final  int? viewCount;
 final  List<StatusViewerModel> _viewers;
@override@JsonKey(name: 'viewers') List<StatusViewerModel> get viewers {
  if (_viewers is EqualUnmodifiableListView) return _viewers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_viewers);
}

@override@JsonKey(name: 'privacyType') final  String? privacyType;
 final  List<String>? _privacyUserIds;
@override@JsonKey(name: 'privacyUserIds') List<String>? get privacyUserIds {
  final value = _privacyUserIds;
  if (value == null) return null;
  if (_privacyUserIds is EqualUnmodifiableListView) return _privacyUserIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(includeFromJson: false, includeToJson: false) final  Color backgroundColor;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  bool viewed;

/// Create a copy of StatusItemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatusItemModelCopyWith<_StatusItemModel> get copyWith => __$StatusItemModelCopyWithImpl<_StatusItemModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatusItemModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatusItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.statusType, statusType) || other.statusType == statusType)&&(identical(other.text, text) || other.text == text)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&const DeepCollectionEquality().equals(other._viewers, _viewers)&&(identical(other.privacyType, privacyType) || other.privacyType == privacyType)&&const DeepCollectionEquality().equals(other._privacyUserIds, _privacyUserIds)&&(identical(other.backgroundColor, backgroundColor) || other.backgroundColor == backgroundColor)&&(identical(other.viewed, viewed) || other.viewed == viewed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,statusType,text,imagePath,timestamp,expiresAt,viewCount,const DeepCollectionEquality().hash(_viewers),privacyType,const DeepCollectionEquality().hash(_privacyUserIds),backgroundColor,viewed);

@override
String toString() {
  return 'StatusItemModel(id: $id, userId: $userId, statusType: $statusType, text: $text, imagePath: $imagePath, timestamp: $timestamp, expiresAt: $expiresAt, viewCount: $viewCount, viewers: $viewers, privacyType: $privacyType, privacyUserIds: $privacyUserIds, backgroundColor: $backgroundColor, viewed: $viewed)';
}


}

/// @nodoc
abstract mixin class _$StatusItemModelCopyWith<$Res> implements $StatusItemModelCopyWith<$Res> {
  factory _$StatusItemModelCopyWith(_StatusItemModel value, $Res Function(_StatusItemModel) _then) = __$StatusItemModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'userId') String? userId,@JsonKey(name: 'statusType') String? statusType,@JsonKey(name: 'textContent') String? text,@JsonKey(name: 'mediaUrl') String? imagePath,@JsonKey(name: 'createdAt') DateTime timestamp,@JsonKey(name: 'expiresAt') DateTime? expiresAt,@JsonKey(name: 'viewCount', defaultValue: 0) int? viewCount,@JsonKey(name: 'viewers') List<StatusViewerModel> viewers,@JsonKey(name: 'privacyType') String? privacyType,@JsonKey(name: 'privacyUserIds') List<String>? privacyUserIds,@JsonKey(includeFromJson: false, includeToJson: false) Color backgroundColor,@JsonKey(includeFromJson: false, includeToJson: false) bool viewed
});




}
/// @nodoc
class __$StatusItemModelCopyWithImpl<$Res>
    implements _$StatusItemModelCopyWith<$Res> {
  __$StatusItemModelCopyWithImpl(this._self, this._then);

  final _StatusItemModel _self;
  final $Res Function(_StatusItemModel) _then;

/// Create a copy of StatusItemModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = freezed,Object? statusType = freezed,Object? text = freezed,Object? imagePath = freezed,Object? timestamp = null,Object? expiresAt = freezed,Object? viewCount = freezed,Object? viewers = null,Object? privacyType = freezed,Object? privacyUserIds = freezed,Object? backgroundColor = null,Object? viewed = null,}) {
  return _then(_StatusItemModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,statusType: freezed == statusType ? _self.statusType : statusType // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,imagePath: freezed == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,viewCount: freezed == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int?,viewers: null == viewers ? _self._viewers : viewers // ignore: cast_nullable_to_non_nullable
as List<StatusViewerModel>,privacyType: freezed == privacyType ? _self.privacyType : privacyType // ignore: cast_nullable_to_non_nullable
as String?,privacyUserIds: freezed == privacyUserIds ? _self._privacyUserIds : privacyUserIds // ignore: cast_nullable_to_non_nullable
as List<String>?,backgroundColor: null == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as Color,viewed: null == viewed ? _self.viewed : viewed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$StatusViewerModel {

 String get viewerId; String? get username; String? get displayName;@JsonKey(name: 'viewedAt') int? get viewedAt;
/// Create a copy of StatusViewerModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatusViewerModelCopyWith<StatusViewerModel> get copyWith => _$StatusViewerModelCopyWithImpl<StatusViewerModel>(this as StatusViewerModel, _$identity);

  /// Serializes this StatusViewerModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatusViewerModel&&(identical(other.viewerId, viewerId) || other.viewerId == viewerId)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.viewedAt, viewedAt) || other.viewedAt == viewedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,viewerId,username,displayName,viewedAt);

@override
String toString() {
  return 'StatusViewerModel(viewerId: $viewerId, username: $username, displayName: $displayName, viewedAt: $viewedAt)';
}


}

/// @nodoc
abstract mixin class $StatusViewerModelCopyWith<$Res>  {
  factory $StatusViewerModelCopyWith(StatusViewerModel value, $Res Function(StatusViewerModel) _then) = _$StatusViewerModelCopyWithImpl;
@useResult
$Res call({
 String viewerId, String? username, String? displayName,@JsonKey(name: 'viewedAt') int? viewedAt
});




}
/// @nodoc
class _$StatusViewerModelCopyWithImpl<$Res>
    implements $StatusViewerModelCopyWith<$Res> {
  _$StatusViewerModelCopyWithImpl(this._self, this._then);

  final StatusViewerModel _self;
  final $Res Function(StatusViewerModel) _then;

/// Create a copy of StatusViewerModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? viewerId = null,Object? username = freezed,Object? displayName = freezed,Object? viewedAt = freezed,}) {
  return _then(_self.copyWith(
viewerId: null == viewerId ? _self.viewerId : viewerId // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,viewedAt: freezed == viewedAt ? _self.viewedAt : viewedAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [StatusViewerModel].
extension StatusViewerModelPatterns on StatusViewerModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatusViewerModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatusViewerModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatusViewerModel value)  $default,){
final _that = this;
switch (_that) {
case _StatusViewerModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatusViewerModel value)?  $default,){
final _that = this;
switch (_that) {
case _StatusViewerModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String viewerId,  String? username,  String? displayName, @JsonKey(name: 'viewedAt')  int? viewedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatusViewerModel() when $default != null:
return $default(_that.viewerId,_that.username,_that.displayName,_that.viewedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String viewerId,  String? username,  String? displayName, @JsonKey(name: 'viewedAt')  int? viewedAt)  $default,) {final _that = this;
switch (_that) {
case _StatusViewerModel():
return $default(_that.viewerId,_that.username,_that.displayName,_that.viewedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String viewerId,  String? username,  String? displayName, @JsonKey(name: 'viewedAt')  int? viewedAt)?  $default,) {final _that = this;
switch (_that) {
case _StatusViewerModel() when $default != null:
return $default(_that.viewerId,_that.username,_that.displayName,_that.viewedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatusViewerModel implements StatusViewerModel {
  const _StatusViewerModel({required this.viewerId, this.username, this.displayName, @JsonKey(name: 'viewedAt') this.viewedAt});
  factory _StatusViewerModel.fromJson(Map<String, dynamic> json) => _$StatusViewerModelFromJson(json);

@override final  String viewerId;
@override final  String? username;
@override final  String? displayName;
@override@JsonKey(name: 'viewedAt') final  int? viewedAt;

/// Create a copy of StatusViewerModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatusViewerModelCopyWith<_StatusViewerModel> get copyWith => __$StatusViewerModelCopyWithImpl<_StatusViewerModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatusViewerModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatusViewerModel&&(identical(other.viewerId, viewerId) || other.viewerId == viewerId)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.viewedAt, viewedAt) || other.viewedAt == viewedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,viewerId,username,displayName,viewedAt);

@override
String toString() {
  return 'StatusViewerModel(viewerId: $viewerId, username: $username, displayName: $displayName, viewedAt: $viewedAt)';
}


}

/// @nodoc
abstract mixin class _$StatusViewerModelCopyWith<$Res> implements $StatusViewerModelCopyWith<$Res> {
  factory _$StatusViewerModelCopyWith(_StatusViewerModel value, $Res Function(_StatusViewerModel) _then) = __$StatusViewerModelCopyWithImpl;
@override @useResult
$Res call({
 String viewerId, String? username, String? displayName,@JsonKey(name: 'viewedAt') int? viewedAt
});




}
/// @nodoc
class __$StatusViewerModelCopyWithImpl<$Res>
    implements _$StatusViewerModelCopyWith<$Res> {
  __$StatusViewerModelCopyWithImpl(this._self, this._then);

  final _StatusViewerModel _self;
  final $Res Function(_StatusViewerModel) _then;

/// Create a copy of StatusViewerModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? viewerId = null,Object? username = freezed,Object? displayName = freezed,Object? viewedAt = freezed,}) {
  return _then(_StatusViewerModel(
viewerId: null == viewerId ? _self.viewerId : viewerId // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,viewedAt: freezed == viewedAt ? _self.viewedAt : viewedAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$StatusContactModel {

@JsonKey(name: 'userId') String get contactId;@JsonKey(name: 'displayName', defaultValue: 'User') String get name;@JsonKey(name: 'username') String? get username;@JsonKey(name: 'profilePictureUrl') String? get profilePictureUrl;@JsonKey(includeFromJson: false, includeToJson: false) Color get profileColor; List<StatusItemModel> get statuses;@JsonKey(includeFromJson: false, includeToJson: false) bool get isMuted;
/// Create a copy of StatusContactModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatusContactModelCopyWith<StatusContactModel> get copyWith => _$StatusContactModelCopyWithImpl<StatusContactModel>(this as StatusContactModel, _$identity);

  /// Serializes this StatusContactModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatusContactModel&&(identical(other.contactId, contactId) || other.contactId == contactId)&&(identical(other.name, name) || other.name == name)&&(identical(other.username, username) || other.username == username)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl)&&(identical(other.profileColor, profileColor) || other.profileColor == profileColor)&&const DeepCollectionEquality().equals(other.statuses, statuses)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,contactId,name,username,profilePictureUrl,profileColor,const DeepCollectionEquality().hash(statuses),isMuted);

@override
String toString() {
  return 'StatusContactModel(contactId: $contactId, name: $name, username: $username, profilePictureUrl: $profilePictureUrl, profileColor: $profileColor, statuses: $statuses, isMuted: $isMuted)';
}


}

/// @nodoc
abstract mixin class $StatusContactModelCopyWith<$Res>  {
  factory $StatusContactModelCopyWith(StatusContactModel value, $Res Function(StatusContactModel) _then) = _$StatusContactModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'userId') String contactId,@JsonKey(name: 'displayName', defaultValue: 'User') String name,@JsonKey(name: 'username') String? username,@JsonKey(name: 'profilePictureUrl') String? profilePictureUrl,@JsonKey(includeFromJson: false, includeToJson: false) Color profileColor, List<StatusItemModel> statuses,@JsonKey(includeFromJson: false, includeToJson: false) bool isMuted
});




}
/// @nodoc
class _$StatusContactModelCopyWithImpl<$Res>
    implements $StatusContactModelCopyWith<$Res> {
  _$StatusContactModelCopyWithImpl(this._self, this._then);

  final StatusContactModel _self;
  final $Res Function(StatusContactModel) _then;

/// Create a copy of StatusContactModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? contactId = null,Object? name = null,Object? username = freezed,Object? profilePictureUrl = freezed,Object? profileColor = null,Object? statuses = null,Object? isMuted = null,}) {
  return _then(_self.copyWith(
contactId: null == contactId ? _self.contactId : contactId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,profileColor: null == profileColor ? _self.profileColor : profileColor // ignore: cast_nullable_to_non_nullable
as Color,statuses: null == statuses ? _self.statuses : statuses // ignore: cast_nullable_to_non_nullable
as List<StatusItemModel>,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [StatusContactModel].
extension StatusContactModelPatterns on StatusContactModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatusContactModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatusContactModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatusContactModel value)  $default,){
final _that = this;
switch (_that) {
case _StatusContactModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatusContactModel value)?  $default,){
final _that = this;
switch (_that) {
case _StatusContactModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'userId')  String contactId, @JsonKey(name: 'displayName', defaultValue: 'User')  String name, @JsonKey(name: 'username')  String? username, @JsonKey(name: 'profilePictureUrl')  String? profilePictureUrl, @JsonKey(includeFromJson: false, includeToJson: false)  Color profileColor,  List<StatusItemModel> statuses, @JsonKey(includeFromJson: false, includeToJson: false)  bool isMuted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatusContactModel() when $default != null:
return $default(_that.contactId,_that.name,_that.username,_that.profilePictureUrl,_that.profileColor,_that.statuses,_that.isMuted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'userId')  String contactId, @JsonKey(name: 'displayName', defaultValue: 'User')  String name, @JsonKey(name: 'username')  String? username, @JsonKey(name: 'profilePictureUrl')  String? profilePictureUrl, @JsonKey(includeFromJson: false, includeToJson: false)  Color profileColor,  List<StatusItemModel> statuses, @JsonKey(includeFromJson: false, includeToJson: false)  bool isMuted)  $default,) {final _that = this;
switch (_that) {
case _StatusContactModel():
return $default(_that.contactId,_that.name,_that.username,_that.profilePictureUrl,_that.profileColor,_that.statuses,_that.isMuted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'userId')  String contactId, @JsonKey(name: 'displayName', defaultValue: 'User')  String name, @JsonKey(name: 'username')  String? username, @JsonKey(name: 'profilePictureUrl')  String? profilePictureUrl, @JsonKey(includeFromJson: false, includeToJson: false)  Color profileColor,  List<StatusItemModel> statuses, @JsonKey(includeFromJson: false, includeToJson: false)  bool isMuted)?  $default,) {final _that = this;
switch (_that) {
case _StatusContactModel() when $default != null:
return $default(_that.contactId,_that.name,_that.username,_that.profilePictureUrl,_that.profileColor,_that.statuses,_that.isMuted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatusContactModel extends StatusContactModel {
  const _StatusContactModel({@JsonKey(name: 'userId') required this.contactId, @JsonKey(name: 'displayName', defaultValue: 'User') required this.name, @JsonKey(name: 'username') this.username, @JsonKey(name: 'profilePictureUrl') this.profilePictureUrl, @JsonKey(includeFromJson: false, includeToJson: false) this.profileColor = Colors.blue, final  List<StatusItemModel> statuses = const [], @JsonKey(includeFromJson: false, includeToJson: false) this.isMuted = false}): _statuses = statuses,super._();
  factory _StatusContactModel.fromJson(Map<String, dynamic> json) => _$StatusContactModelFromJson(json);

@override@JsonKey(name: 'userId') final  String contactId;
@override@JsonKey(name: 'displayName', defaultValue: 'User') final  String name;
@override@JsonKey(name: 'username') final  String? username;
@override@JsonKey(name: 'profilePictureUrl') final  String? profilePictureUrl;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  Color profileColor;
 final  List<StatusItemModel> _statuses;
@override@JsonKey() List<StatusItemModel> get statuses {
  if (_statuses is EqualUnmodifiableListView) return _statuses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_statuses);
}

@override@JsonKey(includeFromJson: false, includeToJson: false) final  bool isMuted;

/// Create a copy of StatusContactModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatusContactModelCopyWith<_StatusContactModel> get copyWith => __$StatusContactModelCopyWithImpl<_StatusContactModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatusContactModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatusContactModel&&(identical(other.contactId, contactId) || other.contactId == contactId)&&(identical(other.name, name) || other.name == name)&&(identical(other.username, username) || other.username == username)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl)&&(identical(other.profileColor, profileColor) || other.profileColor == profileColor)&&const DeepCollectionEquality().equals(other._statuses, _statuses)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,contactId,name,username,profilePictureUrl,profileColor,const DeepCollectionEquality().hash(_statuses),isMuted);

@override
String toString() {
  return 'StatusContactModel(contactId: $contactId, name: $name, username: $username, profilePictureUrl: $profilePictureUrl, profileColor: $profileColor, statuses: $statuses, isMuted: $isMuted)';
}


}

/// @nodoc
abstract mixin class _$StatusContactModelCopyWith<$Res> implements $StatusContactModelCopyWith<$Res> {
  factory _$StatusContactModelCopyWith(_StatusContactModel value, $Res Function(_StatusContactModel) _then) = __$StatusContactModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'userId') String contactId,@JsonKey(name: 'displayName', defaultValue: 'User') String name,@JsonKey(name: 'username') String? username,@JsonKey(name: 'profilePictureUrl') String? profilePictureUrl,@JsonKey(includeFromJson: false, includeToJson: false) Color profileColor, List<StatusItemModel> statuses,@JsonKey(includeFromJson: false, includeToJson: false) bool isMuted
});




}
/// @nodoc
class __$StatusContactModelCopyWithImpl<$Res>
    implements _$StatusContactModelCopyWith<$Res> {
  __$StatusContactModelCopyWithImpl(this._self, this._then);

  final _StatusContactModel _self;
  final $Res Function(_StatusContactModel) _then;

/// Create a copy of StatusContactModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? contactId = null,Object? name = null,Object? username = freezed,Object? profilePictureUrl = freezed,Object? profileColor = null,Object? statuses = null,Object? isMuted = null,}) {
  return _then(_StatusContactModel(
contactId: null == contactId ? _self.contactId : contactId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,profileColor: null == profileColor ? _self.profileColor : profileColor // ignore: cast_nullable_to_non_nullable
as Color,statuses: null == statuses ? _self._statuses : statuses // ignore: cast_nullable_to_non_nullable
as List<StatusItemModel>,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
