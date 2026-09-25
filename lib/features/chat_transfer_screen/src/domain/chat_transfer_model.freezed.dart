// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_transfer_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatTransferModel {

 String get id;
/// Create a copy of ChatTransferModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatTransferModelCopyWith<ChatTransferModel> get copyWith => _$ChatTransferModelCopyWithImpl<ChatTransferModel>(this as ChatTransferModel, _$identity);

  /// Serializes this ChatTransferModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatTransferModel&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'ChatTransferModel(id: $id)';
}


}

/// @nodoc
abstract mixin class $ChatTransferModelCopyWith<$Res>  {
  factory $ChatTransferModelCopyWith(ChatTransferModel value, $Res Function(ChatTransferModel) _then) = _$ChatTransferModelCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class _$ChatTransferModelCopyWithImpl<$Res>
    implements $ChatTransferModelCopyWith<$Res> {
  _$ChatTransferModelCopyWithImpl(this._self, this._then);

  final ChatTransferModel _self;
  final $Res Function(ChatTransferModel) _then;

/// Create a copy of ChatTransferModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatTransferModel].
extension ChatTransferModelPatterns on ChatTransferModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatTransferModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatTransferModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatTransferModel value)  $default,){
final _that = this;
switch (_that) {
case _ChatTransferModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatTransferModel value)?  $default,){
final _that = this;
switch (_that) {
case _ChatTransferModel() when $default != null:
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
case _ChatTransferModel() when $default != null:
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
case _ChatTransferModel():
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
case _ChatTransferModel() when $default != null:
return $default(_that.id);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatTransferModel implements ChatTransferModel {
  const _ChatTransferModel({required this.id});
  factory _ChatTransferModel.fromJson(Map<String, dynamic> json) => _$ChatTransferModelFromJson(json);

@override final  String id;

/// Create a copy of ChatTransferModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatTransferModelCopyWith<_ChatTransferModel> get copyWith => __$ChatTransferModelCopyWithImpl<_ChatTransferModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatTransferModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatTransferModel&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'ChatTransferModel(id: $id)';
}


}

/// @nodoc
abstract mixin class _$ChatTransferModelCopyWith<$Res> implements $ChatTransferModelCopyWith<$Res> {
  factory _$ChatTransferModelCopyWith(_ChatTransferModel value, $Res Function(_ChatTransferModel) _then) = __$ChatTransferModelCopyWithImpl;
@override @useResult
$Res call({
 String id
});




}
/// @nodoc
class __$ChatTransferModelCopyWithImpl<$Res>
    implements _$ChatTransferModelCopyWith<$Res> {
  __$ChatTransferModelCopyWithImpl(this._self, this._then);

  final _ChatTransferModel _self;
  final $Res Function(_ChatTransferModel) _then;

/// Create a copy of ChatTransferModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_ChatTransferModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
