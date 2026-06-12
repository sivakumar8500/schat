// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'enroll_subscription_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EnrollSubscriptionRequest {

@JsonKey(name: 'plan_id') String get planId;@JsonKey(name: 'promo_code') String? get promoCode;@JsonKey(name: 'payment_record_id') String? get paymentRecordId;
/// Create a copy of EnrollSubscriptionRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnrollSubscriptionRequestCopyWith<EnrollSubscriptionRequest> get copyWith => _$EnrollSubscriptionRequestCopyWithImpl<EnrollSubscriptionRequest>(this as EnrollSubscriptionRequest, _$identity);

  /// Serializes this EnrollSubscriptionRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnrollSubscriptionRequest&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.promoCode, promoCode) || other.promoCode == promoCode)&&(identical(other.paymentRecordId, paymentRecordId) || other.paymentRecordId == paymentRecordId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,planId,promoCode,paymentRecordId);

@override
String toString() {
  return 'EnrollSubscriptionRequest(planId: $planId, promoCode: $promoCode, paymentRecordId: $paymentRecordId)';
}


}

/// @nodoc
abstract mixin class $EnrollSubscriptionRequestCopyWith<$Res>  {
  factory $EnrollSubscriptionRequestCopyWith(EnrollSubscriptionRequest value, $Res Function(EnrollSubscriptionRequest) _then) = _$EnrollSubscriptionRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'plan_id') String planId,@JsonKey(name: 'promo_code') String? promoCode,@JsonKey(name: 'payment_record_id') String? paymentRecordId
});




}
/// @nodoc
class _$EnrollSubscriptionRequestCopyWithImpl<$Res>
    implements $EnrollSubscriptionRequestCopyWith<$Res> {
  _$EnrollSubscriptionRequestCopyWithImpl(this._self, this._then);

  final EnrollSubscriptionRequest _self;
  final $Res Function(EnrollSubscriptionRequest) _then;

/// Create a copy of EnrollSubscriptionRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? planId = null,Object? promoCode = freezed,Object? paymentRecordId = freezed,}) {
  return _then(_self.copyWith(
planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,promoCode: freezed == promoCode ? _self.promoCode : promoCode // ignore: cast_nullable_to_non_nullable
as String?,paymentRecordId: freezed == paymentRecordId ? _self.paymentRecordId : paymentRecordId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EnrollSubscriptionRequest].
extension EnrollSubscriptionRequestPatterns on EnrollSubscriptionRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EnrollSubscriptionRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EnrollSubscriptionRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EnrollSubscriptionRequest value)  $default,){
final _that = this;
switch (_that) {
case _EnrollSubscriptionRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EnrollSubscriptionRequest value)?  $default,){
final _that = this;
switch (_that) {
case _EnrollSubscriptionRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'plan_id')  String planId, @JsonKey(name: 'promo_code')  String? promoCode, @JsonKey(name: 'payment_record_id')  String? paymentRecordId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EnrollSubscriptionRequest() when $default != null:
return $default(_that.planId,_that.promoCode,_that.paymentRecordId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'plan_id')  String planId, @JsonKey(name: 'promo_code')  String? promoCode, @JsonKey(name: 'payment_record_id')  String? paymentRecordId)  $default,) {final _that = this;
switch (_that) {
case _EnrollSubscriptionRequest():
return $default(_that.planId,_that.promoCode,_that.paymentRecordId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'plan_id')  String planId, @JsonKey(name: 'promo_code')  String? promoCode, @JsonKey(name: 'payment_record_id')  String? paymentRecordId)?  $default,) {final _that = this;
switch (_that) {
case _EnrollSubscriptionRequest() when $default != null:
return $default(_that.planId,_that.promoCode,_that.paymentRecordId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EnrollSubscriptionRequest implements EnrollSubscriptionRequest {
  const _EnrollSubscriptionRequest({@JsonKey(name: 'plan_id') required this.planId, @JsonKey(name: 'promo_code') this.promoCode, @JsonKey(name: 'payment_record_id') this.paymentRecordId});
  factory _EnrollSubscriptionRequest.fromJson(Map<String, dynamic> json) => _$EnrollSubscriptionRequestFromJson(json);

@override@JsonKey(name: 'plan_id') final  String planId;
@override@JsonKey(name: 'promo_code') final  String? promoCode;
@override@JsonKey(name: 'payment_record_id') final  String? paymentRecordId;

/// Create a copy of EnrollSubscriptionRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnrollSubscriptionRequestCopyWith<_EnrollSubscriptionRequest> get copyWith => __$EnrollSubscriptionRequestCopyWithImpl<_EnrollSubscriptionRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EnrollSubscriptionRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnrollSubscriptionRequest&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.promoCode, promoCode) || other.promoCode == promoCode)&&(identical(other.paymentRecordId, paymentRecordId) || other.paymentRecordId == paymentRecordId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,planId,promoCode,paymentRecordId);

@override
String toString() {
  return 'EnrollSubscriptionRequest(planId: $planId, promoCode: $promoCode, paymentRecordId: $paymentRecordId)';
}


}

/// @nodoc
abstract mixin class _$EnrollSubscriptionRequestCopyWith<$Res> implements $EnrollSubscriptionRequestCopyWith<$Res> {
  factory _$EnrollSubscriptionRequestCopyWith(_EnrollSubscriptionRequest value, $Res Function(_EnrollSubscriptionRequest) _then) = __$EnrollSubscriptionRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'plan_id') String planId,@JsonKey(name: 'promo_code') String? promoCode,@JsonKey(name: 'payment_record_id') String? paymentRecordId
});




}
/// @nodoc
class __$EnrollSubscriptionRequestCopyWithImpl<$Res>
    implements _$EnrollSubscriptionRequestCopyWith<$Res> {
  __$EnrollSubscriptionRequestCopyWithImpl(this._self, this._then);

  final _EnrollSubscriptionRequest _self;
  final $Res Function(_EnrollSubscriptionRequest) _then;

/// Create a copy of EnrollSubscriptionRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? planId = null,Object? promoCode = freezed,Object? paymentRecordId = freezed,}) {
  return _then(_EnrollSubscriptionRequest(
planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,promoCode: freezed == promoCode ? _self.promoCode : promoCode // ignore: cast_nullable_to_non_nullable
as String?,paymentRecordId: freezed == paymentRecordId ? _self.paymentRecordId : paymentRecordId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
