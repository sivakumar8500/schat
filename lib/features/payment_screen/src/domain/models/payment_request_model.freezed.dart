// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaymentRequestModel {

 String get planId; String get cardholderName; String get cardNumber; String get expiry; String get cvv;
/// Create a copy of PaymentRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentRequestModelCopyWith<PaymentRequestModel> get copyWith => _$PaymentRequestModelCopyWithImpl<PaymentRequestModel>(this as PaymentRequestModel, _$identity);

  /// Serializes this PaymentRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentRequestModel&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.cardholderName, cardholderName) || other.cardholderName == cardholderName)&&(identical(other.cardNumber, cardNumber) || other.cardNumber == cardNumber)&&(identical(other.expiry, expiry) || other.expiry == expiry)&&(identical(other.cvv, cvv) || other.cvv == cvv));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,planId,cardholderName,cardNumber,expiry,cvv);

@override
String toString() {
  return 'PaymentRequestModel(planId: $planId, cardholderName: $cardholderName, cardNumber: $cardNumber, expiry: $expiry, cvv: $cvv)';
}


}

/// @nodoc
abstract mixin class $PaymentRequestModelCopyWith<$Res>  {
  factory $PaymentRequestModelCopyWith(PaymentRequestModel value, $Res Function(PaymentRequestModel) _then) = _$PaymentRequestModelCopyWithImpl;
@useResult
$Res call({
 String planId, String cardholderName, String cardNumber, String expiry, String cvv
});




}
/// @nodoc
class _$PaymentRequestModelCopyWithImpl<$Res>
    implements $PaymentRequestModelCopyWith<$Res> {
  _$PaymentRequestModelCopyWithImpl(this._self, this._then);

  final PaymentRequestModel _self;
  final $Res Function(PaymentRequestModel) _then;

/// Create a copy of PaymentRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? planId = null,Object? cardholderName = null,Object? cardNumber = null,Object? expiry = null,Object? cvv = null,}) {
  return _then(_self.copyWith(
planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,cardholderName: null == cardholderName ? _self.cardholderName : cardholderName // ignore: cast_nullable_to_non_nullable
as String,cardNumber: null == cardNumber ? _self.cardNumber : cardNumber // ignore: cast_nullable_to_non_nullable
as String,expiry: null == expiry ? _self.expiry : expiry // ignore: cast_nullable_to_non_nullable
as String,cvv: null == cvv ? _self.cvv : cvv // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentRequestModel].
extension PaymentRequestModelPatterns on PaymentRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _PaymentRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String planId,  String cardholderName,  String cardNumber,  String expiry,  String cvv)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentRequestModel() when $default != null:
return $default(_that.planId,_that.cardholderName,_that.cardNumber,_that.expiry,_that.cvv);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String planId,  String cardholderName,  String cardNumber,  String expiry,  String cvv)  $default,) {final _that = this;
switch (_that) {
case _PaymentRequestModel():
return $default(_that.planId,_that.cardholderName,_that.cardNumber,_that.expiry,_that.cvv);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String planId,  String cardholderName,  String cardNumber,  String expiry,  String cvv)?  $default,) {final _that = this;
switch (_that) {
case _PaymentRequestModel() when $default != null:
return $default(_that.planId,_that.cardholderName,_that.cardNumber,_that.expiry,_that.cvv);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentRequestModel implements PaymentRequestModel {
  const _PaymentRequestModel({required this.planId, required this.cardholderName, required this.cardNumber, required this.expiry, required this.cvv});
  factory _PaymentRequestModel.fromJson(Map<String, dynamic> json) => _$PaymentRequestModelFromJson(json);

@override final  String planId;
@override final  String cardholderName;
@override final  String cardNumber;
@override final  String expiry;
@override final  String cvv;

/// Create a copy of PaymentRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentRequestModelCopyWith<_PaymentRequestModel> get copyWith => __$PaymentRequestModelCopyWithImpl<_PaymentRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentRequestModel&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.cardholderName, cardholderName) || other.cardholderName == cardholderName)&&(identical(other.cardNumber, cardNumber) || other.cardNumber == cardNumber)&&(identical(other.expiry, expiry) || other.expiry == expiry)&&(identical(other.cvv, cvv) || other.cvv == cvv));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,planId,cardholderName,cardNumber,expiry,cvv);

@override
String toString() {
  return 'PaymentRequestModel(planId: $planId, cardholderName: $cardholderName, cardNumber: $cardNumber, expiry: $expiry, cvv: $cvv)';
}


}

/// @nodoc
abstract mixin class _$PaymentRequestModelCopyWith<$Res> implements $PaymentRequestModelCopyWith<$Res> {
  factory _$PaymentRequestModelCopyWith(_PaymentRequestModel value, $Res Function(_PaymentRequestModel) _then) = __$PaymentRequestModelCopyWithImpl;
@override @useResult
$Res call({
 String planId, String cardholderName, String cardNumber, String expiry, String cvv
});




}
/// @nodoc
class __$PaymentRequestModelCopyWithImpl<$Res>
    implements _$PaymentRequestModelCopyWith<$Res> {
  __$PaymentRequestModelCopyWithImpl(this._self, this._then);

  final _PaymentRequestModel _self;
  final $Res Function(_PaymentRequestModel) _then;

/// Create a copy of PaymentRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? planId = null,Object? cardholderName = null,Object? cardNumber = null,Object? expiry = null,Object? cvv = null,}) {
  return _then(_PaymentRequestModel(
planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,cardholderName: null == cardholderName ? _self.cardholderName : cardholderName // ignore: cast_nullable_to_non_nullable
as String,cardNumber: null == cardNumber ? _self.cardNumber : cardNumber // ignore: cast_nullable_to_non_nullable
as String,expiry: null == expiry ? _self.expiry : expiry // ignore: cast_nullable_to_non_nullable
as String,cvv: null == cvv ? _self.cvv : cvv // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
