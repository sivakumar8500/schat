import 'package:schat/features/subscription_screen/src/domain/models/subscription_plan_model.dart';

abstract class SubscriptionRepository {
  Future<List<SubscriptionPlanModel>> getSubscriptionPlans();
}
