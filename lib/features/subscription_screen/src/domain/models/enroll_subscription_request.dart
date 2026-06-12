import 'package:freezed_annotation/freezed_annotation.dart';

part 'enroll_subscription_request.freezed.dart';
part 'enroll_subscription_request.g.dart';

@freezed
abstract class EnrollSubscriptionRequest with _$EnrollSubscriptionRequest {
  const factory EnrollSubscriptionRequest({
    @JsonKey(name: 'plan_id') required String planId,
    @JsonKey(name: 'promo_code') String? promoCode,
    @JsonKey(name: 'payment_record_id') String? paymentRecordId,
  }) = _EnrollSubscriptionRequest;

  factory EnrollSubscriptionRequest.fromJson(Map<String, dynamic> json) => _$EnrollSubscriptionRequestFromJson(json);
}
