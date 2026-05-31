import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_plan_model.freezed.dart';
part 'subscription_plan_model.g.dart';

@freezed
abstract class SubscriptionPlanModel with _$SubscriptionPlanModel {
  const factory SubscriptionPlanModel({
    required String id,
    required String name,
    required String price,
    required String duration,
    required List<String> features,
    required int colorHex,
  }) = _SubscriptionPlanModel;

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) => _$SubscriptionPlanModelFromJson(json);
}
