import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_plan_model.freezed.dart';
part 'subscription_plan_model.g.dart';

@freezed
abstract class PlanFeatureItem with _$PlanFeatureItem {
  const factory PlanFeatureItem({
    required String title,
    @Default(true) bool included,
  }) = _PlanFeatureItem;

  factory PlanFeatureItem.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] ?? json['name'] ?? json['feature'] ?? '').toString();
    final dynamic inc = json['included'] ?? json['is_included'];
    final bool included = inc == null ? true : (inc == true || inc == 1 || inc == 'true');
    return PlanFeatureItem(title: title, included: included);
  }
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

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString();
    final name = (json['name'] ?? '').toString();
    final description = (json['description'] ?? json['desc'] ?? '').toString();
    final priceRaw = json['price'];
    final int price;
    if (priceRaw is num) {
      price = priceRaw.round();
    } else if (priceRaw != null) {
      price = (num.tryParse(priceRaw.toString()) ?? 0).round();
    } else {
      price = 0;
    }
    final billingCycle = (json['billing_cycle'] ?? json['billingCycle'] ?? 'monthly').toString();
    final isActive = json['is_active'] == null || json['is_active'] == true || json['isActive'] == true || json['is_active'] == 1;

    final List<PlanFeatureItem> featuresList = [];
    final rawFeatures = json['features'];
    if (rawFeatures is List) {
      for (final item in rawFeatures) {
        if (item is Map<String, dynamic>) {
          featuresList.add(PlanFeatureItem.fromJson(item));
        } else if (item is Map) {
          featuresList.add(PlanFeatureItem.fromJson(Map<String, dynamic>.from(item)));
        } else if (item is String && item.trim().isNotEmpty) {
          featuresList.add(PlanFeatureItem(title: item.trim(), included: true));
        }
      }
    }

    return SubscriptionPlanModel(
      id: id,
      name: name,
      description: description,
      price: price,
      billingCycle: billingCycle,
      isActive: isActive,
      features: featuresList,
    );
  }
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
