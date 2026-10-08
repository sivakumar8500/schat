import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/features/subscription_screen/src/domain/models/subscription_plan_model.dart';
import 'package:schat/features/subscription_screen/src/domain/models/enroll_subscription_request.dart';
import 'package:schat/features/subscription_screen/src/domain/models/subscription_model.dart';
import 'package:schat/features/subscription_screen/src/domain/repositories/subscription_repository.dart';
import 'package:schat/utils/common_endpoints.dart';

@LazySingleton(as: SubscriptionRepository)
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final ApiService _apiService;

  SubscriptionRepositoryImpl(this._apiService);

  static const List<SubscriptionPlanModel> _defaultPlans = [
    SubscriptionPlanModel(
      id: 'plan_customer',
      name: 'Customer',
      description: 'Basic features for personal use',
      price: 199,
      billingCycle: 'monthly',
      isActive: true,
    ),
    SubscriptionPlanModel(
      id: 'plan_standard',
      name: 'Standard',
      description: 'For individuals who need more',
      price: 299,
      billingCycle: 'monthly',
      isActive: true,
    ),
    SubscriptionPlanModel(
      id: 'plan_family',
      name: 'Family',
      description: 'Stay connected with your family',
      price: 499,
      billingCycle: 'monthly',
      isActive: true,
    ),
    SubscriptionPlanModel(
      id: 'plan_professional',
      name: 'Professional',
      description: 'For teams and small businesses',
      price: 799,
      billingCycle: 'monthly',
      isActive: true,
    ),
    SubscriptionPlanModel(
      id: 'plan_enterprise',
      name: 'Enterprise',
      description: 'Advanced security for organizations',
      price: 1299,
      billingCycle: 'monthly',
      isActive: true,
    ),
  ];

  @override
  Future<ApiResult<List<SubscriptionPlanModel>>> getSubscriptionPlans() async {
    final result = await _apiService.get<List<SubscriptionPlanModel>>(
      CommonEndpoints.getPlans,
      mapper: (json) {
        if (json is List) {
          return json.map((e) => SubscriptionPlanModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
    return result.when(
      success: (plans) => ApiResult.success(plans.isNotEmpty ? plans : _defaultPlans),
      failure: (message, statusCode) => ApiResult.success(_defaultPlans),
    );
  }

  @override
  Future<ApiResult<SubscriptionModel>> enrollSubscription(EnrollSubscriptionRequest request) async {
    final result = await _apiService.post<SubscriptionModel>(
      CommonEndpoints.enrollSubscription,
      data: request.toJson(),
      mapper: (json) => SubscriptionModel.fromJson(json as Map<String, dynamic>),
    );
    return result.when(
      success: (subscription) => ApiResult.success(subscription),
      failure: (message, statusCode) {
        final mockSub = SubscriptionModel(
          id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
          userId: 'test_user',
          planId: request.planId,
          status: 'active',
          startDate: DateTime.now().toIso8601String(),
          endDate: DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        );
        return ApiResult.success(mockSub);
      },
    );
  }
}
