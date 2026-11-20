// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_plan_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlanFeatureItem _$PlanFeatureItemFromJson(Map<String, dynamic> json) =>
    _PlanFeatureItem(
      title: json['title'] as String,
      included: json['included'] as bool? ?? true,
    );

Map<String, dynamic> _$PlanFeatureItemToJson(_PlanFeatureItem instance) =>
    <String, dynamic>{'title': instance.title, 'included': instance.included};

_SubscriptionPlanModel _$SubscriptionPlanModelFromJson(
  Map<String, dynamic> json,
) => _SubscriptionPlanModel(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  price: (json['price'] as num).toInt(),
  billingCycle: json['billing_cycle'] as String,
  isActive: json['is_active'] as bool,
  features:
      (json['features'] as List<dynamic>?)
          ?.map((e) => PlanFeatureItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SubscriptionPlanModelToJson(
  _SubscriptionPlanModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'price': instance.price,
  'billing_cycle': instance.billingCycle,
  'is_active': instance.isActive,
  'features': instance.features,
};
