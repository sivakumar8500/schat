import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/subscription_screen/src/domain/models/subscription_plan_model.dart';
import 'package:schat/features/subscription_screen/src/domain/models/enroll_subscription_request.dart';
import 'package:schat/features/subscription_screen/src/domain/models/subscription_model.dart';

abstract class SubscriptionRepository {
  Future<ApiResult<List<SubscriptionPlanModel>>> getSubscriptionPlans();
  Future<ApiResult<SubscriptionModel>> enrollSubscription(EnrollSubscriptionRequest request);
}
