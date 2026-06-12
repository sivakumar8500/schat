// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubscriptionModel _$SubscriptionModelFromJson(Map<String, dynamic> json) =>
    _SubscriptionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      planId: json['plan_id'] as String,
      status: json['status'] as String,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
    );

Map<String, dynamic> _$SubscriptionModelToJson(_SubscriptionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'plan_id': instance.planId,
      'status': instance.status,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
    };
