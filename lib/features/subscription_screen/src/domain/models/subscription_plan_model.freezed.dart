// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription_plan_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubscriptionPlanModel {

 String get id; String get name; String get description; int get price;@JsonKey(name: 'billing_cycle') String get billingCycle;@JsonKey(name: 'is_active') bool get isActive;
/// Create a copy of SubscriptionPlanModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionPlanModelCopyWith<SubscriptionPlanModel> get copyWith => _$SubscriptionPlanModelCopyWithImpl<SubscriptionPlanModel>(this as SubscriptionPlanModel, _$identity);

  /// Serializes this SubscriptionPlanModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscriptionPlanModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.billingCycle, billingCycle) || other.billingCycle == billingCycle)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,price,billingCycle,isActive);

@override
String toString() {
  return 'SubscriptionPlanModel(id: $id, name: $name, description: $description, price: $price, billingCycle: $billingCycle, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $SubscriptionPlanModelCopyWith<$Res>  {
  factory $SubscriptionPlanModelCopyWith(SubscriptionPlanModel value, $Res Function(SubscriptionPlanModel) _then) = _$SubscriptionPlanModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, int price,@JsonKey(name: 'billing_cycle') String billingCycle,@JsonKey(name: 'is_active') bool isActive
});




}
/// @nodoc
class _$SubscriptionPlanModelCopyWithImpl<$Res>
    implements $SubscriptionPlanModelCopyWith<$Res> {
  _$SubscriptionPlanModelCopyWithImpl(this._self, this._then);

  final SubscriptionPlanModel _self;
  final $Res Function(SubscriptionPlanModel) _then;

/// Create a copy of SubscriptionPlanModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? price = null,Object? billingCycle = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,billingCycle: null == billingCycle ? _self.billingCycle : billingCycle // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SubscriptionPlanModel].
extension SubscriptionPlanModelPatterns on SubscriptionPlanModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubscriptionPlanModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubscriptionPlanModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubscriptionPlanModel value)  $default,){
final _that = this;
switch (_that) {
case _SubscriptionPlanModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubscriptionPlanModel value)?  $default,){
final _that = this;
switch (_that) {
case _SubscriptionPlanModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  int price, @JsonKey(name: 'billing_cycle')  String billingCycle, @JsonKey(name: 'is_active')  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionPlanModel() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.price,_that.billingCycle,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  int price, @JsonKey(name: 'billing_cycle')  String billingCycle, @JsonKey(name: 'is_active')  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _SubscriptionPlanModel():
return $default(_that.id,_that.name,_that.description,_that.price,_that.billingCycle,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  int price, @JsonKey(name: 'billing_cycle')  String billingCycle, @JsonKey(name: 'is_active')  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _SubscriptionPlanModel() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.price,_that.billingCycle,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubscriptionPlanModel implements SubscriptionPlanModel {
  const _SubscriptionPlanModel({required this.id, required this.name, required this.description, required this.price, @JsonKey(name: 'billing_cycle') required this.billingCycle, @JsonKey(name: 'is_active') required this.isActive});
  factory _SubscriptionPlanModel.fromJson(Map<String, dynamic> json) => _$SubscriptionPlanModelFromJson(json);

@override final  String id;
@override final  String name;
@override final  String description;
@override final  int price;
@override@JsonKey(name: 'billing_cycle') final  String billingCycle;
@override@JsonKey(name: 'is_active') final  bool isActive;

/// Create a copy of SubscriptionPlanModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionPlanModelCopyWith<_SubscriptionPlanModel> get copyWith => __$SubscriptionPlanModelCopyWithImpl<_SubscriptionPlanModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubscriptionPlanModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionPlanModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.billingCycle, billingCycle) || other.billingCycle == billingCycle)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,price,billingCycle,isActive);

@override
String toString() {
  return 'SubscriptionPlanModel(id: $id, name: $name, description: $description, price: $price, billingCycle: $billingCycle, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionPlanModelCopyWith<$Res> implements $SubscriptionPlanModelCopyWith<$Res> {
  factory _$SubscriptionPlanModelCopyWith(_SubscriptionPlanModel value, $Res Function(_SubscriptionPlanModel) _then) = __$SubscriptionPlanModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, int price,@JsonKey(name: 'billing_cycle') String billingCycle,@JsonKey(name: 'is_active') bool isActive
});




}
/// @nodoc
class __$SubscriptionPlanModelCopyWithImpl<$Res>
    implements _$SubscriptionPlanModelCopyWith<$Res> {
  __$SubscriptionPlanModelCopyWithImpl(this._self, this._then);

  final _SubscriptionPlanModel _self;
  final $Res Function(_SubscriptionPlanModel) _then;

/// Create a copy of SubscriptionPlanModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? price = null,Object? billingCycle = null,Object? isActive = null,}) {
  return _then(_SubscriptionPlanModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,billingCycle: null == billingCycle ? _self.billingCycle : billingCycle // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
