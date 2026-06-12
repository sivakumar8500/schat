import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_plan_model.freezed.dart';
part 'subscription_plan_model.g.dart';

@freezed
abstract class SubscriptionPlanModel with _$SubscriptionPlanModel {
  const factory SubscriptionPlanModel({
    required String id,
    required String name,
    required String description,
    required int price,
    @JsonKey(name: 'billing_cycle') required String billingCycle,
    @JsonKey(name: 'is_active') required bool isActive,
  }) = _SubscriptionPlanModel;

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) => _$SubscriptionPlanModelFromJson(json);
}
