// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MessageModel {

 String get id; String get text; String get time; bool get isMe; bool get isRead; String get type; String? get attachmentPath; String? get attachmentName;@JsonKey(includeFromJson: false, includeToJson: false) Uint8List? get attachmentBytes;
/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageModelCopyWith<MessageModel> get copyWith => _$MessageModelCopyWithImpl<MessageModel>(this as MessageModel, _$identity);

  /// Serializes this MessageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.time, time) || other.time == time)&&(identical(other.isMe, isMe) || other.isMe == isMe)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.type, type) || other.type == type)&&(identical(other.attachmentPath, attachmentPath) || other.attachmentPath == attachmentPath)&&(identical(other.attachmentName, attachmentName) || other.attachmentName == attachmentName)&&const DeepCollectionEquality().equals(other.attachmentBytes, attachmentBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,text,time,isMe,isRead,type,attachmentPath,attachmentName,const DeepCollectionEquality().hash(attachmentBytes));

@override
String toString() {
  return 'MessageModel(id: $id, text: $text, time: $time, isMe: $isMe, isRead: $isRead, type: $type, attachmentPath: $attachmentPath, attachmentName: $attachmentName, attachmentBytes: $attachmentBytes)';
}


}

/// @nodoc
abstract mixin class $MessageModelCopyWith<$Res>  {
  factory $MessageModelCopyWith(MessageModel value, $Res Function(MessageModel) _then) = _$MessageModelCopyWithImpl;
@useResult
$Res call({
 String id, String text, String time, bool isMe, bool isRead, String type, String? attachmentPath, String? attachmentName,@JsonKey(includeFromJson: false, includeToJson: false) Uint8List? attachmentBytes
});




}
/// @nodoc
class _$MessageModelCopyWithImpl<$Res>
    implements $MessageModelCopyWith<$Res> {
  _$MessageModelCopyWithImpl(this._self, this._then);

  final MessageModel _self;
  final $Res Function(MessageModel) _then;

/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? text = null,Object? time = null,Object? isMe = null,Object? isRead = null,Object? type = null,Object? attachmentPath = freezed,Object? attachmentName = freezed,Object? attachmentBytes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as String,isMe: null == isMe ? _self.isMe : isMe // ignore: cast_nullable_to_non_nullable
as bool,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,attachmentPath: freezed == attachmentPath ? _self.attachmentPath : attachmentPath // ignore: cast_nullable_to_non_nullable
as String?,attachmentName: freezed == attachmentName ? _self.attachmentName : attachmentName // ignore: cast_nullable_to_non_nullable
as String?,attachmentBytes: freezed == attachmentBytes ? _self.attachmentBytes : attachmentBytes // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageModel].
extension MessageModelPatterns on MessageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageModel value)  $default,){
final _that = this;
switch (_that) {
case _MessageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageModel value)?  $default,){
final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String text,  String time,  bool isMe,  bool isRead,  String type,  String? attachmentPath,  String? attachmentName, @JsonKey(includeFromJson: false, includeToJson: false)  Uint8List? attachmentBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
return $default(_that.id,_that.text,_that.time,_that.isMe,_that.isRead,_that.type,_that.attachmentPath,_that.attachmentName,_that.attachmentBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String text,  String time,  bool isMe,  bool isRead,  String type,  String? attachmentPath,  String? attachmentName, @JsonKey(includeFromJson: false, includeToJson: false)  Uint8List? attachmentBytes)  $default,) {final _that = this;
switch (_that) {
case _MessageModel():
return $default(_that.id,_that.text,_that.time,_that.isMe,_that.isRead,_that.type,_that.attachmentPath,_that.attachmentName,_that.attachmentBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String text,  String time,  bool isMe,  bool isRead,  String type,  String? attachmentPath,  String? attachmentName, @JsonKey(includeFromJson: false, includeToJson: false)  Uint8List? attachmentBytes)?  $default,) {final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
return $default(_that.id,_that.text,_that.time,_that.isMe,_that.isRead,_that.type,_that.attachmentPath,_that.attachmentName,_that.attachmentBytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageModel implements MessageModel {
  const _MessageModel({required this.id, required this.text, required this.time, required this.isMe, this.isRead = false, this.type = 'text', this.attachmentPath, this.attachmentName, @JsonKey(includeFromJson: false, includeToJson: false) this.attachmentBytes});
  factory _MessageModel.fromJson(Map<String, dynamic> json) => _$MessageModelFromJson(json);

@override final  String id;
@override final  String text;
@override final  String time;
@override final  bool isMe;
@override@JsonKey() final  bool isRead;
@override@JsonKey() final  String type;
@override final  String? attachmentPath;
@override final  String? attachmentName;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  Uint8List? attachmentBytes;

/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageModelCopyWith<_MessageModel> get copyWith => __$MessageModelCopyWithImpl<_MessageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.time, time) || other.time == time)&&(identical(other.isMe, isMe) || other.isMe == isMe)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.type, type) || other.type == type)&&(identical(other.attachmentPath, attachmentPath) || other.attachmentPath == attachmentPath)&&(identical(other.attachmentName, attachmentName) || other.attachmentName == attachmentName)&&const DeepCollectionEquality().equals(other.attachmentBytes, attachmentBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,text,time,isMe,isRead,type,attachmentPath,attachmentName,const DeepCollectionEquality().hash(attachmentBytes));

@override
String toString() {
  return 'MessageModel(id: $id, text: $text, time: $time, isMe: $isMe, isRead: $isRead, type: $type, attachmentPath: $attachmentPath, attachmentName: $attachmentName, attachmentBytes: $attachmentBytes)';
}


}

/// @nodoc
abstract mixin class _$MessageModelCopyWith<$Res> implements $MessageModelCopyWith<$Res> {
  factory _$MessageModelCopyWith(_MessageModel value, $Res Function(_MessageModel) _then) = __$MessageModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String text, String time, bool isMe, bool isRead, String type, String? attachmentPath, String? attachmentName,@JsonKey(includeFromJson: false, includeToJson: false) Uint8List? attachmentBytes
});




}
/// @nodoc
class __$MessageModelCopyWithImpl<$Res>
    implements _$MessageModelCopyWith<$Res> {
  __$MessageModelCopyWithImpl(this._self, this._then);

  final _MessageModel _self;
  final $Res Function(_MessageModel) _then;

/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,Object? time = null,Object? isMe = null,Object? isRead = null,Object? type = null,Object? attachmentPath = freezed,Object? attachmentName = freezed,Object? attachmentBytes = freezed,}) {
  return _then(_MessageModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as String,isMe: null == isMe ? _self.isMe : isMe // ignore: cast_nullable_to_non_nullable
as bool,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,attachmentPath: freezed == attachmentPath ? _self.attachmentPath : attachmentPath // ignore: cast_nullable_to_non_nullable
as String?,attachmentName: freezed == attachmentName ? _self.attachmentName : attachmentName // ignore: cast_nullable_to_non_nullable
as String?,attachmentBytes: freezed == attachmentBytes ? _self.attachmentBytes : attachmentBytes // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}


}

// dart format on
