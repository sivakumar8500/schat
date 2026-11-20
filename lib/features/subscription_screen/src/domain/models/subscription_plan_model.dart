import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_plan_model.freezed.dart';
part 'subscription_plan_model.g.dart';

@freezed
abstract class PlanFeatureItem with _$PlanFeatureItem {
  const factory PlanFeatureItem({
    required String title,
    @Default(true) bool included,
  }) = _PlanFeatureItem;

  factory PlanFeatureItem.fromJson(Map<String, dynamic> json) => _$PlanFeatureItemFromJson(json);
}

@freezed
abstract class SubscriptionPlanModel with _$SubscriptionPlanModel {
  const factory SubscriptionPlanModel({
    required String id,
    required String name,
    required String description,
    required int price,
    @JsonKey(name: 'billing_cycle') required String billingCycle,
    @JsonKey(name: 'is_active') required bool isActive,
    @Default([]) List<PlanFeatureItem> features,
  }) = _SubscriptionPlanModel;

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) => _$SubscriptionPlanModelFromJson(json);
}

extension SubscriptionPlanModelX on SubscriptionPlanModel {
  List<PlanFeatureItem> get effectiveFeatures {
    if (features.isNotEmpty) {
      return features;
    }
    final lower = name.toLowerCase();
    if (lower.contains('customer') || lower.contains('basic')) {
      return const [
        PlanFeatureItem(title: 'Secure chat & calls', included: true),
        PlanFeatureItem(title: 'Screenshot restriction', included: true),
        PlanFeatureItem(title: 'Screen record restriction', included: true),
        PlanFeatureItem(title: 'Hide chat & chat lock', included: false),
        PlanFeatureItem(title: 'File share protection', included: false),
        PlanFeatureItem(title: 'Multi-device & team controls', included: false),
      ];
    } else if (lower.contains('standard') || lower.contains('business')) {
      return const [
        PlanFeatureItem(title: 'Secure chat & calls', included: true),
        PlanFeatureItem(title: 'Screenshot restriction', included: true),
        PlanFeatureItem(title: 'Screen record restriction', included: true),
        PlanFeatureItem(title: 'Hide chat & chat lock', included: true),
        PlanFeatureItem(title: 'File share protection', included: false),
        PlanFeatureItem(title: 'Multi-device & team controls', included: false),
      ];
    } else if (lower.contains('family')) {
      return const [
        PlanFeatureItem(title: 'Secure chat & calls', included: true),
        PlanFeatureItem(title: 'Screenshot restriction', included: true),
        PlanFeatureItem(title: 'Screen record restriction', included: true),
        PlanFeatureItem(title: 'Hide chat & chat lock', included: true),
        PlanFeatureItem(title: 'File share protection', included: true),
        PlanFeatureItem(title: 'Multi-device & team controls', included: false),
      ];
    } else {
      return const [
        PlanFeatureItem(title: 'Secure chat & calls', included: true),
        PlanFeatureItem(title: 'Screenshot restriction', included: true),
        PlanFeatureItem(title: 'Screen record restriction', included: true),
        PlanFeatureItem(title: 'Hide chat & chat lock', included: true),
        PlanFeatureItem(title: 'File share protection', included: true),
        PlanFeatureItem(title: 'Multi-device & team controls', included: true),
      ];
    }
  }
}
