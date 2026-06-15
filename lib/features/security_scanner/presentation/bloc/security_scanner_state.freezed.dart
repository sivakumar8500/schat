// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'security_scanner_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SecurityScannerState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecurityScannerState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SecurityScannerState()';
}


}

/// @nodoc
class $SecurityScannerStateCopyWith<$Res>  {
$SecurityScannerStateCopyWith(SecurityScannerState _, $Res Function(SecurityScannerState) __);
}


/// Adds pattern-matching-related methods to [SecurityScannerState].
extension SecurityScannerStatePatterns on SecurityScannerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( _IntegrityResult value)?  integrityResult,TResult Function( _ScanResult value)?  scanResult,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _IntegrityResult() when integrityResult != null:
return integrityResult(_that);case _ScanResult() when scanResult != null:
return scanResult(_that);case _Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( _IntegrityResult value)  integrityResult,required TResult Function( _ScanResult value)  scanResult,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case _IntegrityResult():
return integrityResult(_that);case _ScanResult():
return scanResult(_that);case _Error():
return error(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( _IntegrityResult value)?  integrityResult,TResult? Function( _ScanResult value)?  scanResult,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _IntegrityResult() when integrityResult != null:
return integrityResult(_that);case _ScanResult() when scanResult != null:
return scanResult(_that);case _Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( bool isSafe)?  integrityResult,TResult Function( SecurityReport report)?  scanResult,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _IntegrityResult() when integrityResult != null:
return integrityResult(_that.isSafe);case _ScanResult() when scanResult != null:
return scanResult(_that.report);case _Error() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( bool isSafe)  integrityResult,required TResult Function( SecurityReport report)  scanResult,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _IntegrityResult():
return integrityResult(_that.isSafe);case _ScanResult():
return scanResult(_that.report);case _Error():
return error(_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( bool isSafe)?  integrityResult,TResult? Function( SecurityReport report)?  scanResult,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _IntegrityResult() when integrityResult != null:
return integrityResult(_that.isSafe);case _ScanResult() when scanResult != null:
return scanResult(_that.report);case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements SecurityScannerState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SecurityScannerState.initial()';
}


}




/// @nodoc


class _Loading implements SecurityScannerState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SecurityScannerState.loading()';
}


}




/// @nodoc


class _IntegrityResult implements SecurityScannerState {
  const _IntegrityResult(this.isSafe);
  

 final  bool isSafe;

/// Create a copy of SecurityScannerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IntegrityResultCopyWith<_IntegrityResult> get copyWith => __$IntegrityResultCopyWithImpl<_IntegrityResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IntegrityResult&&(identical(other.isSafe, isSafe) || other.isSafe == isSafe));
}


@override
int get hashCode => Object.hash(runtimeType,isSafe);

@override
String toString() {
  return 'SecurityScannerState.integrityResult(isSafe: $isSafe)';
}


}

/// @nodoc
abstract mixin class _$IntegrityResultCopyWith<$Res> implements $SecurityScannerStateCopyWith<$Res> {
  factory _$IntegrityResultCopyWith(_IntegrityResult value, $Res Function(_IntegrityResult) _then) = __$IntegrityResultCopyWithImpl;
@useResult
$Res call({
 bool isSafe
});




}
/// @nodoc
class __$IntegrityResultCopyWithImpl<$Res>
    implements _$IntegrityResultCopyWith<$Res> {
  __$IntegrityResultCopyWithImpl(this._self, this._then);

  final _IntegrityResult _self;
  final $Res Function(_IntegrityResult) _then;

/// Create a copy of SecurityScannerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? isSafe = null,}) {
  return _then(_IntegrityResult(
null == isSafe ? _self.isSafe : isSafe // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class _ScanResult implements SecurityScannerState {
  const _ScanResult(this.report);
  

 final  SecurityReport report;

/// Create a copy of SecurityScannerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScanResultCopyWith<_ScanResult> get copyWith => __$ScanResultCopyWithImpl<_ScanResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanResult&&(identical(other.report, report) || other.report == report));
}


@override
int get hashCode => Object.hash(runtimeType,report);

@override
String toString() {
  return 'SecurityScannerState.scanResult(report: $report)';
}


}

/// @nodoc
abstract mixin class _$ScanResultCopyWith<$Res> implements $SecurityScannerStateCopyWith<$Res> {
  factory _$ScanResultCopyWith(_ScanResult value, $Res Function(_ScanResult) _then) = __$ScanResultCopyWithImpl;
@useResult
$Res call({
 SecurityReport report
});


$SecurityReportCopyWith<$Res> get report;

}
/// @nodoc
class __$ScanResultCopyWithImpl<$Res>
    implements _$ScanResultCopyWith<$Res> {
  __$ScanResultCopyWithImpl(this._self, this._then);

  final _ScanResult _self;
  final $Res Function(_ScanResult) _then;

/// Create a copy of SecurityScannerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? report = null,}) {
  return _then(_ScanResult(
null == report ? _self.report : report // ignore: cast_nullable_to_non_nullable
as SecurityReport,
  ));
}

/// Create a copy of SecurityScannerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SecurityReportCopyWith<$Res> get report {
  
  return $SecurityReportCopyWith<$Res>(_self.report, (value) {
    return _then(_self.copyWith(report: value));
  });
}
}

/// @nodoc


class _Error implements SecurityScannerState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of SecurityScannerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'SecurityScannerState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $SecurityScannerStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of SecurityScannerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
