// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'security_scanner_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SecurityScannerEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecurityScannerEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SecurityScannerEvent()';
}


}

/// @nodoc
class $SecurityScannerEventCopyWith<$Res>  {
$SecurityScannerEventCopyWith(SecurityScannerEvent _, $Res Function(SecurityScannerEvent) __);
}


/// Adds pattern-matching-related methods to [SecurityScannerEvent].
extension SecurityScannerEventPatterns on SecurityScannerEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CheckIntegrity value)?  checkIntegrity,TResult Function( ScanUrl value)?  scanUrl,TResult Function( ScanFile value)?  scanFile,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CheckIntegrity() when checkIntegrity != null:
return checkIntegrity(_that);case ScanUrl() when scanUrl != null:
return scanUrl(_that);case ScanFile() when scanFile != null:
return scanFile(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CheckIntegrity value)  checkIntegrity,required TResult Function( ScanUrl value)  scanUrl,required TResult Function( ScanFile value)  scanFile,}){
final _that = this;
switch (_that) {
case CheckIntegrity():
return checkIntegrity(_that);case ScanUrl():
return scanUrl(_that);case ScanFile():
return scanFile(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CheckIntegrity value)?  checkIntegrity,TResult? Function( ScanUrl value)?  scanUrl,TResult? Function( ScanFile value)?  scanFile,}){
final _that = this;
switch (_that) {
case CheckIntegrity() when checkIntegrity != null:
return checkIntegrity(_that);case ScanUrl() when scanUrl != null:
return scanUrl(_that);case ScanFile() when scanFile != null:
return scanFile(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  checkIntegrity,TResult Function( String url)?  scanUrl,TResult Function( String filePath)?  scanFile,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CheckIntegrity() when checkIntegrity != null:
return checkIntegrity();case ScanUrl() when scanUrl != null:
return scanUrl(_that.url);case ScanFile() when scanFile != null:
return scanFile(_that.filePath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  checkIntegrity,required TResult Function( String url)  scanUrl,required TResult Function( String filePath)  scanFile,}) {final _that = this;
switch (_that) {
case CheckIntegrity():
return checkIntegrity();case ScanUrl():
return scanUrl(_that.url);case ScanFile():
return scanFile(_that.filePath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  checkIntegrity,TResult? Function( String url)?  scanUrl,TResult? Function( String filePath)?  scanFile,}) {final _that = this;
switch (_that) {
case CheckIntegrity() when checkIntegrity != null:
return checkIntegrity();case ScanUrl() when scanUrl != null:
return scanUrl(_that.url);case ScanFile() when scanFile != null:
return scanFile(_that.filePath);case _:
  return null;

}
}

}

/// @nodoc


class CheckIntegrity implements SecurityScannerEvent {
  const CheckIntegrity();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckIntegrity);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SecurityScannerEvent.checkIntegrity()';
}


}




/// @nodoc


class ScanUrl implements SecurityScannerEvent {
  const ScanUrl(this.url);
  

 final  String url;

/// Create a copy of SecurityScannerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanUrlCopyWith<ScanUrl> get copyWith => _$ScanUrlCopyWithImpl<ScanUrl>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanUrl&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,url);

@override
String toString() {
  return 'SecurityScannerEvent.scanUrl(url: $url)';
}


}

/// @nodoc
abstract mixin class $ScanUrlCopyWith<$Res> implements $SecurityScannerEventCopyWith<$Res> {
  factory $ScanUrlCopyWith(ScanUrl value, $Res Function(ScanUrl) _then) = _$ScanUrlCopyWithImpl;
@useResult
$Res call({
 String url
});




}
/// @nodoc
class _$ScanUrlCopyWithImpl<$Res>
    implements $ScanUrlCopyWith<$Res> {
  _$ScanUrlCopyWithImpl(this._self, this._then);

  final ScanUrl _self;
  final $Res Function(ScanUrl) _then;

/// Create a copy of SecurityScannerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? url = null,}) {
  return _then(ScanUrl(
null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ScanFile implements SecurityScannerEvent {
  const ScanFile(this.filePath);
  

 final  String filePath;

/// Create a copy of SecurityScannerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanFileCopyWith<ScanFile> get copyWith => _$ScanFileCopyWithImpl<ScanFile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanFile&&(identical(other.filePath, filePath) || other.filePath == filePath));
}


@override
int get hashCode => Object.hash(runtimeType,filePath);

@override
String toString() {
  return 'SecurityScannerEvent.scanFile(filePath: $filePath)';
}


}

/// @nodoc
abstract mixin class $ScanFileCopyWith<$Res> implements $SecurityScannerEventCopyWith<$Res> {
  factory $ScanFileCopyWith(ScanFile value, $Res Function(ScanFile) _then) = _$ScanFileCopyWithImpl;
@useResult
$Res call({
 String filePath
});




}
/// @nodoc
class _$ScanFileCopyWithImpl<$Res>
    implements $ScanFileCopyWith<$Res> {
  _$ScanFileCopyWithImpl(this._self, this._then);

  final ScanFile _self;
  final $Res Function(ScanFile) _then;

/// Create a copy of SecurityScannerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? filePath = null,}) {
  return _then(ScanFile(
null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
