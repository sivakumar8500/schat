import 'package:schat/features/subscription_screen/src/domain/models/subscription_plan_model.dart';
import 'package:schat/features/subscription_screen/src/domain/models/coupon_model.dart';

abstract class SubscriptionState {
  const SubscriptionState();
}

class SubscriptionInitial extends SubscriptionState {
  const SubscriptionInitial();
}

class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading();
}

class SubscriptionConfirming extends SubscriptionState {
  final List<SubscriptionPlanModel> plans;
  final int selectedIndex;
  final CouponValidationResult? appliedCoupon;

  const SubscriptionConfirming({
    required this.plans,
    required this.selectedIndex,
    this.appliedCoupon,
  });
}

class SubscriptionLoaded extends SubscriptionState {
  final List<SubscriptionPlanModel> plans;
  final int selectedIndex;
  final List<CouponModel> availableCoupons;
  final CouponValidationResult? appliedCoupon;
  final bool isValidatingCoupon;
  final String? couponError;
  final bool isProcessingPayment;

  const SubscriptionLoaded({
    required this.plans,
    required this.selectedIndex,
    this.availableCoupons = const [],
    this.appliedCoupon,
    this.isValidatingCoupon = false,
    this.couponError,
    this.isProcessingPayment = false,
  });

  SubscriptionPlanModel? get selectedPlan =>
      (selectedIndex >= 0 && selectedIndex < plans.length) ? plans[selectedIndex] : null;

  double get originalPrice => selectedPlan?.price.toDouble() ?? 0.0;

  double get discountAmount => appliedCoupon?.discountAmount ?? 0.0;

  double get finalPrice => appliedCoupon != null ? appliedCoupon!.finalPrice : originalPrice;

  SubscriptionLoaded copyWith({
    List<SubscriptionPlanModel>? plans,
    int? selectedIndex,
    List<CouponModel>? availableCoupons,
    CouponValidationResult? appliedCoupon,
    bool clearCoupon = false,
    bool? isValidatingCoupon,
    String? couponError,
    bool clearCouponError = false,
    bool? isProcessingPayment,
  }) {
    return SubscriptionLoaded(
      plans: plans ?? this.plans,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      availableCoupons: availableCoupons ?? this.availableCoupons,
      appliedCoupon: clearCoupon ? null : (appliedCoupon ?? this.appliedCoupon),
      isValidatingCoupon: isValidatingCoupon ?? this.isValidatingCoupon,
      couponError: clearCouponError ? null : (couponError ?? this.couponError),
      isProcessingPayment: isProcessingPayment ?? this.isProcessingPayment,
    );
  }
}

class SubscriptionPaymentReady extends SubscriptionState {
  final RazorpayOrderModel order;
  final SubscriptionPlanModel plan;
  final double finalAmount;
  final String? couponCode;

  const SubscriptionPaymentReady({
    required this.order,
    required this.plan,
    required this.finalAmount,
    this.couponCode,
  });
}

class SubscriptionSuccess extends SubscriptionState {
  const SubscriptionSuccess();
}

class SubscriptionFailure extends SubscriptionState {
  final String error;

  const SubscriptionFailure({required this.error});
}
