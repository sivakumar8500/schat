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

 String get id; String? get text; String? get imagePath; DateTime get timestamp; Color get backgroundColor; bool get viewed;
/// Create a copy of StatusItemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatusItemModelCopyWith<StatusItemModel> get copyWith => _$StatusItemModelCopyWithImpl<StatusItemModel>(this as StatusItemModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatusItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.backgroundColor, backgroundColor) || other.backgroundColor == backgroundColor)&&(identical(other.viewed, viewed) || other.viewed == viewed));
}


@override
int get hashCode => Object.hash(runtimeType,id,text,imagePath,timestamp,backgroundColor,viewed);

@override
String toString() {
  return 'StatusItemModel(id: $id, text: $text, imagePath: $imagePath, timestamp: $timestamp, backgroundColor: $backgroundColor, viewed: $viewed)';
}


}

/// @nodoc
abstract mixin class $StatusItemModelCopyWith<$Res>  {
  factory $StatusItemModelCopyWith(StatusItemModel value, $Res Function(StatusItemModel) _then) = _$StatusItemModelCopyWithImpl;
@useResult
$Res call({
 String id, String? text, String? imagePath, DateTime timestamp, Color backgroundColor, bool viewed
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? text = freezed,Object? imagePath = freezed,Object? timestamp = null,Object? backgroundColor = null,Object? viewed = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,imagePath: freezed == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,backgroundColor: null == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? text,  String? imagePath,  DateTime timestamp,  Color backgroundColor,  bool viewed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatusItemModel() when $default != null:
return $default(_that.id,_that.text,_that.imagePath,_that.timestamp,_that.backgroundColor,_that.viewed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? text,  String? imagePath,  DateTime timestamp,  Color backgroundColor,  bool viewed)  $default,) {final _that = this;
switch (_that) {
case _StatusItemModel():
return $default(_that.id,_that.text,_that.imagePath,_that.timestamp,_that.backgroundColor,_that.viewed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? text,  String? imagePath,  DateTime timestamp,  Color backgroundColor,  bool viewed)?  $default,) {final _that = this;
switch (_that) {
case _StatusItemModel() when $default != null:
return $default(_that.id,_that.text,_that.imagePath,_that.timestamp,_that.backgroundColor,_that.viewed);case _:
  return null;

}
}

}

/// @nodoc


class _StatusItemModel implements StatusItemModel {
  const _StatusItemModel({required this.id, this.text, this.imagePath, required this.timestamp, this.backgroundColor = Colors.black, this.viewed = false});
  

@override final  String id;
@override final  String? text;
@override final  String? imagePath;
@override final  DateTime timestamp;
@override@JsonKey() final  Color backgroundColor;
@override@JsonKey() final  bool viewed;

/// Create a copy of StatusItemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatusItemModelCopyWith<_StatusItemModel> get copyWith => __$StatusItemModelCopyWithImpl<_StatusItemModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatusItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.backgroundColor, backgroundColor) || other.backgroundColor == backgroundColor)&&(identical(other.viewed, viewed) || other.viewed == viewed));
}


@override
int get hashCode => Object.hash(runtimeType,id,text,imagePath,timestamp,backgroundColor,viewed);

@override
String toString() {
  return 'StatusItemModel(id: $id, text: $text, imagePath: $imagePath, timestamp: $timestamp, backgroundColor: $backgroundColor, viewed: $viewed)';
}


}

/// @nodoc
abstract mixin class _$StatusItemModelCopyWith<$Res> implements $StatusItemModelCopyWith<$Res> {
  factory _$StatusItemModelCopyWith(_StatusItemModel value, $Res Function(_StatusItemModel) _then) = __$StatusItemModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String? text, String? imagePath, DateTime timestamp, Color backgroundColor, bool viewed
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = freezed,Object? imagePath = freezed,Object? timestamp = null,Object? backgroundColor = null,Object? viewed = null,}) {
  return _then(_StatusItemModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,imagePath: freezed == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,backgroundColor: null == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as Color,viewed: null == viewed ? _self.viewed : viewed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$StatusContactModel {

 String get contactId; String get name; Color get profileColor; List<StatusItemModel> get statuses; bool get isMuted;
/// Create a copy of StatusContactModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatusContactModelCopyWith<StatusContactModel> get copyWith => _$StatusContactModelCopyWithImpl<StatusContactModel>(this as StatusContactModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatusContactModel&&(identical(other.contactId, contactId) || other.contactId == contactId)&&(identical(other.name, name) || other.name == name)&&(identical(other.profileColor, profileColor) || other.profileColor == profileColor)&&const DeepCollectionEquality().equals(other.statuses, statuses)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted));
}


@override
int get hashCode => Object.hash(runtimeType,contactId,name,profileColor,const DeepCollectionEquality().hash(statuses),isMuted);

@override
String toString() {
  return 'StatusContactModel(contactId: $contactId, name: $name, profileColor: $profileColor, statuses: $statuses, isMuted: $isMuted)';
}


}

/// @nodoc
abstract mixin class $StatusContactModelCopyWith<$Res>  {
  factory $StatusContactModelCopyWith(StatusContactModel value, $Res Function(StatusContactModel) _then) = _$StatusContactModelCopyWithImpl;
@useResult
$Res call({
 String contactId, String name, Color profileColor, List<StatusItemModel> statuses, bool isMuted
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
@pragma('vm:prefer-inline') @override $Res call({Object? contactId = null,Object? name = null,Object? profileColor = null,Object? statuses = null,Object? isMuted = null,}) {
  return _then(_self.copyWith(
contactId: null == contactId ? _self.contactId : contactId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,profileColor: null == profileColor ? _self.profileColor : profileColor // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String contactId,  String name,  Color profileColor,  List<StatusItemModel> statuses,  bool isMuted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatusContactModel() when $default != null:
return $default(_that.contactId,_that.name,_that.profileColor,_that.statuses,_that.isMuted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String contactId,  String name,  Color profileColor,  List<StatusItemModel> statuses,  bool isMuted)  $default,) {final _that = this;
switch (_that) {
case _StatusContactModel():
return $default(_that.contactId,_that.name,_that.profileColor,_that.statuses,_that.isMuted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String contactId,  String name,  Color profileColor,  List<StatusItemModel> statuses,  bool isMuted)?  $default,) {final _that = this;
switch (_that) {
case _StatusContactModel() when $default != null:
return $default(_that.contactId,_that.name,_that.profileColor,_that.statuses,_that.isMuted);case _:
  return null;

}
}

}

/// @nodoc


class _StatusContactModel extends StatusContactModel {
  const _StatusContactModel({required this.contactId, required this.name, required this.profileColor, required final  List<StatusItemModel> statuses, this.isMuted = false}): _statuses = statuses,super._();
  

@override final  String contactId;
@override final  String name;
@override final  Color profileColor;
 final  List<StatusItemModel> _statuses;
@override List<StatusItemModel> get statuses {
  if (_statuses is EqualUnmodifiableListView) return _statuses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_statuses);
}

@override@JsonKey() final  bool isMuted;

/// Create a copy of StatusContactModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatusContactModelCopyWith<_StatusContactModel> get copyWith => __$StatusContactModelCopyWithImpl<_StatusContactModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatusContactModel&&(identical(other.contactId, contactId) || other.contactId == contactId)&&(identical(other.name, name) || other.name == name)&&(identical(other.profileColor, profileColor) || other.profileColor == profileColor)&&const DeepCollectionEquality().equals(other._statuses, _statuses)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted));
}


@override
int get hashCode => Object.hash(runtimeType,contactId,name,profileColor,const DeepCollectionEquality().hash(_statuses),isMuted);

@override
String toString() {
  return 'StatusContactModel(contactId: $contactId, name: $name, profileColor: $profileColor, statuses: $statuses, isMuted: $isMuted)';
}


}

/// @nodoc
abstract mixin class _$StatusContactModelCopyWith<$Res> implements $StatusContactModelCopyWith<$Res> {
  factory _$StatusContactModelCopyWith(_StatusContactModel value, $Res Function(_StatusContactModel) _then) = __$StatusContactModelCopyWithImpl;
@override @useResult
$Res call({
 String contactId, String name, Color profileColor, List<StatusItemModel> statuses, bool isMuted
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
@override @pragma('vm:prefer-inline') $Res call({Object? contactId = null,Object? name = null,Object? profileColor = null,Object? statuses = null,Object? isMuted = null,}) {
  return _then(_StatusContactModel(
contactId: null == contactId ? _self.contactId : contactId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,profileColor: null == profileColor ? _self.profileColor : profileColor // ignore: cast_nullable_to_non_nullable
as Color,statuses: null == statuses ? _self._statuses : statuses // ignore: cast_nullable_to_non_nullable
as List<StatusItemModel>,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
