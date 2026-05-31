// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_plan_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubscriptionPlanModel _$SubscriptionPlanModelFromJson(
  Map<String, dynamic> json,
) => _SubscriptionPlanModel(
  id: json['id'] as String,
  name: json['name'] as String,
  price: json['price'] as String,
  duration: json['duration'] as String,
  features: (json['features'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  colorHex: (json['colorHex'] as num).toInt(),
);

Map<String, dynamic> _$SubscriptionPlanModelToJson(
  _SubscriptionPlanModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'price': instance.price,
  'duration': instance.duration,
  'features': instance.features,
  'colorHex': instance.colorHex,
};
