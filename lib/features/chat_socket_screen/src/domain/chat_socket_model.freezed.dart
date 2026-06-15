// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_socket_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatSocketModel {

 String get id;
/// Create a copy of ChatSocketModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatSocketModelCopyWith<ChatSocketModel> get copyWith => _$ChatSocketModelCopyWithImpl<ChatSocketModel>(this as ChatSocketModel, _$identity);

  /// Serializes this ChatSocketModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatSocketModel&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'ChatSocketModel(id: $id)';
}


}

/// @nodoc
abstract mixin class $ChatSocketModelCopyWith<$Res>  {
  factory $ChatSocketModelCopyWith(ChatSocketModel value, $Res Function(ChatSocketModel) _then) = _$ChatSocketModelCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class _$ChatSocketModelCopyWithImpl<$Res>
    implements $ChatSocketModelCopyWith<$Res> {
  _$ChatSocketModelCopyWithImpl(this._self, this._then);

  final ChatSocketModel _self;
  final $Res Function(ChatSocketModel) _then;

/// Create a copy of ChatSocketModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatSocketModel].
extension ChatSocketModelPatterns on ChatSocketModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatSocketModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatSocketModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatSocketModel value)  $default,){
final _that = this;
switch (_that) {
case _ChatSocketModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatSocketModel value)?  $default,){
final _that = this;
switch (_that) {
case _ChatSocketModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatSocketModel() when $default != null:
return $default(_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id)  $default,) {final _that = this;
switch (_that) {
case _ChatSocketModel():
return $default(_that.id);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id)?  $default,) {final _that = this;
switch (_that) {
case _ChatSocketModel() when $default != null:
return $default(_that.id);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatSocketModel implements ChatSocketModel {
  const _ChatSocketModel({required this.id});
  factory _ChatSocketModel.fromJson(Map<String, dynamic> json) => _$ChatSocketModelFromJson(json);

@override final  String id;

/// Create a copy of ChatSocketModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatSocketModelCopyWith<_ChatSocketModel> get copyWith => __$ChatSocketModelCopyWithImpl<_ChatSocketModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatSocketModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatSocketModel&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'ChatSocketModel(id: $id)';
}


}

/// @nodoc
abstract mixin class _$ChatSocketModelCopyWith<$Res> implements $ChatSocketModelCopyWith<$Res> {
  factory _$ChatSocketModelCopyWith(_ChatSocketModel value, $Res Function(_ChatSocketModel) _then) = __$ChatSocketModelCopyWithImpl;
@override @useResult
$Res call({
 String id
});




}
/// @nodoc
class __$ChatSocketModelCopyWithImpl<$Res>
    implements _$ChatSocketModelCopyWith<$Res> {
  __$ChatSocketModelCopyWithImpl(this._self, this._then);

  final _ChatSocketModel _self;
  final $Res Function(_ChatSocketModel) _then;

/// Create a copy of ChatSocketModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_ChatSocketModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
