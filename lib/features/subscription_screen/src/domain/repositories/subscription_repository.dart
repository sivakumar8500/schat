import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/subscription_screen/src/domain/models/subscription_plan_model.dart';
import 'package:schat/features/subscription_screen/src/domain/models/enroll_subscription_request.dart';
import 'package:schat/features/subscription_screen/src/domain/models/subscription_model.dart';
import 'package:schat/features/subscription_screen/src/domain/models/coupon_model.dart';

abstract class SubscriptionRepository {
  Future<ApiResult<List<SubscriptionPlanModel>>> getSubscriptionPlans();
  Future<ApiResult<SubscriptionModel>> enrollSubscription(EnrollSubscriptionRequest request);
  Future<ApiResult<List<CouponModel>>> getCoupons();
  Future<ApiResult<CouponValidationResult>> validateCoupon(String code, String planId);
  Future<ApiResult<RazorpayOrderModel>> createRazorpayOrder({required String planId, String? couponCode});
  Future<ApiResult<SubscriptionModel>> verifyRazorpayPayment({
    required String planId,
    required String orderId,
    required String paymentId,
    required String signature,
    String? couponCode,
  });
}
