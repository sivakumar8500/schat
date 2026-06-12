// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enroll_subscription_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EnrollSubscriptionRequest _$EnrollSubscriptionRequestFromJson(
  Map<String, dynamic> json,
) => _EnrollSubscriptionRequest(
  planId: json['plan_id'] as String,
  promoCode: json['promo_code'] as String?,
  paymentRecordId: json['payment_record_id'] as String?,
);

Map<String, dynamic> _$EnrollSubscriptionRequestToJson(
  _EnrollSubscriptionRequest instance,
) => <String, dynamic>{
  'plan_id': instance.planId,
  'promo_code': instance.promoCode,
  'payment_record_id': instance.paymentRecordId,
};
