// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'send_otp_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SendOtpRequest {

@JsonKey(name: 'phone_number') String get phoneNumber;
/// Create a copy of SendOtpRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SendOtpRequestCopyWith<SendOtpRequest> get copyWith => _$SendOtpRequestCopyWithImpl<SendOtpRequest>(this as SendOtpRequest, _$identity);

  /// Serializes this SendOtpRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SendOtpRequest&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phoneNumber);

@override
String toString() {
  return 'SendOtpRequest(phoneNumber: $phoneNumber)';
}


}

/// @nodoc
abstract mixin class $SendOtpRequestCopyWith<$Res>  {
  factory $SendOtpRequestCopyWith(SendOtpRequest value, $Res Function(SendOtpRequest) _then) = _$SendOtpRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'phone_number') String phoneNumber
});




}
/// @nodoc
class _$SendOtpRequestCopyWithImpl<$Res>
    implements $SendOtpRequestCopyWith<$Res> {
  _$SendOtpRequestCopyWithImpl(this._self, this._then);

  final SendOtpRequest _self;
  final $Res Function(SendOtpRequest) _then;

/// Create a copy of SendOtpRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phoneNumber = null,}) {
  return _then(_self.copyWith(
phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SendOtpRequest].
extension SendOtpRequestPatterns on SendOtpRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SendOtpRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SendOtpRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SendOtpRequest value)  $default,){
final _that = this;
switch (_that) {
case _SendOtpRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SendOtpRequest value)?  $default,){
final _that = this;
switch (_that) {
case _SendOtpRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'phone_number')  String phoneNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SendOtpRequest() when $default != null:
return $default(_that.phoneNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'phone_number')  String phoneNumber)  $default,) {final _that = this;
switch (_that) {
case _SendOtpRequest():
return $default(_that.phoneNumber);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'phone_number')  String phoneNumber)?  $default,) {final _that = this;
switch (_that) {
case _SendOtpRequest() when $default != null:
return $default(_that.phoneNumber);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SendOtpRequest implements SendOtpRequest {
  const _SendOtpRequest({@JsonKey(name: 'phone_number') required this.phoneNumber});
  factory _SendOtpRequest.fromJson(Map<String, dynamic> json) => _$SendOtpRequestFromJson(json);

@override@JsonKey(name: 'phone_number') final  String phoneNumber;

/// Create a copy of SendOtpRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SendOtpRequestCopyWith<_SendOtpRequest> get copyWith => __$SendOtpRequestCopyWithImpl<_SendOtpRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SendOtpRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SendOtpRequest&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phoneNumber);

@override
String toString() {
  return 'SendOtpRequest(phoneNumber: $phoneNumber)';
}


}

/// @nodoc
abstract mixin class _$SendOtpRequestCopyWith<$Res> implements $SendOtpRequestCopyWith<$Res> {
  factory _$SendOtpRequestCopyWith(_SendOtpRequest value, $Res Function(_SendOtpRequest) _then) = __$SendOtpRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'phone_number') String phoneNumber
});




}
/// @nodoc
class __$SendOtpRequestCopyWithImpl<$Res>
    implements _$SendOtpRequestCopyWith<$Res> {
  __$SendOtpRequestCopyWithImpl(this._self, this._then);

  final _SendOtpRequest _self;
  final $Res Function(_SendOtpRequest) _then;

/// Create a copy of SendOtpRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phoneNumber = null,}) {
  return _then(_SendOtpRequest(
phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
