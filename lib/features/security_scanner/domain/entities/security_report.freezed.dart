// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'security_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SecurityReport {

 bool get isSafe; String get riskLevel; String get message;
/// Create a copy of SecurityReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SecurityReportCopyWith<SecurityReport> get copyWith => _$SecurityReportCopyWithImpl<SecurityReport>(this as SecurityReport, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecurityReport&&(identical(other.isSafe, isSafe) || other.isSafe == isSafe)&&(identical(other.riskLevel, riskLevel) || other.riskLevel == riskLevel)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,isSafe,riskLevel,message);

@override
String toString() {
  return 'SecurityReport(isSafe: $isSafe, riskLevel: $riskLevel, message: $message)';
}


}

/// @nodoc
abstract mixin class $SecurityReportCopyWith<$Res>  {
  factory $SecurityReportCopyWith(SecurityReport value, $Res Function(SecurityReport) _then) = _$SecurityReportCopyWithImpl;
@useResult
$Res call({
 bool isSafe, String riskLevel, String message
});




}
/// @nodoc
class _$SecurityReportCopyWithImpl<$Res>
    implements $SecurityReportCopyWith<$Res> {
  _$SecurityReportCopyWithImpl(this._self, this._then);

  final SecurityReport _self;
  final $Res Function(SecurityReport) _then;

/// Create a copy of SecurityReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isSafe = null,Object? riskLevel = null,Object? message = null,}) {
  return _then(_self.copyWith(
isSafe: null == isSafe ? _self.isSafe : isSafe // ignore: cast_nullable_to_non_nullable
as bool,riskLevel: null == riskLevel ? _self.riskLevel : riskLevel // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SecurityReport].
extension SecurityReportPatterns on SecurityReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SecurityReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SecurityReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SecurityReport value)  $default,){
final _that = this;
switch (_that) {
case _SecurityReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SecurityReport value)?  $default,){
final _that = this;
switch (_that) {
case _SecurityReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isSafe,  String riskLevel,  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SecurityReport() when $default != null:
return $default(_that.isSafe,_that.riskLevel,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isSafe,  String riskLevel,  String message)  $default,) {final _that = this;
switch (_that) {
case _SecurityReport():
return $default(_that.isSafe,_that.riskLevel,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isSafe,  String riskLevel,  String message)?  $default,) {final _that = this;
switch (_that) {
case _SecurityReport() when $default != null:
return $default(_that.isSafe,_that.riskLevel,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _SecurityReport implements SecurityReport {
  const _SecurityReport({required this.isSafe, required this.riskLevel, required this.message});
  

@override final  bool isSafe;
@override final  String riskLevel;
@override final  String message;

/// Create a copy of SecurityReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SecurityReportCopyWith<_SecurityReport> get copyWith => __$SecurityReportCopyWithImpl<_SecurityReport>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SecurityReport&&(identical(other.isSafe, isSafe) || other.isSafe == isSafe)&&(identical(other.riskLevel, riskLevel) || other.riskLevel == riskLevel)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,isSafe,riskLevel,message);

@override
String toString() {
  return 'SecurityReport(isSafe: $isSafe, riskLevel: $riskLevel, message: $message)';
}


}

/// @nodoc
abstract mixin class _$SecurityReportCopyWith<$Res> implements $SecurityReportCopyWith<$Res> {
  factory _$SecurityReportCopyWith(_SecurityReport value, $Res Function(_SecurityReport) _then) = __$SecurityReportCopyWithImpl;
@override @useResult
$Res call({
 bool isSafe, String riskLevel, String message
});




}
/// @nodoc
class __$SecurityReportCopyWithImpl<$Res>
    implements _$SecurityReportCopyWith<$Res> {
  __$SecurityReportCopyWithImpl(this._self, this._then);

  final _SecurityReport _self;
  final $Res Function(_SecurityReport) _then;

/// Create a copy of SecurityReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isSafe = null,Object? riskLevel = null,Object? message = null,}) {
  return _then(_SecurityReport(
isSafe: null == isSafe ? _self.isSafe : isSafe // ignore: cast_nullable_to_non_nullable
as bool,riskLevel: null == riskLevel ? _self.riskLevel : riskLevel // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
