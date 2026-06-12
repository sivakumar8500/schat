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

  @override
  Future<ApiResult<List<SubscriptionPlanModel>>> getSubscriptionPlans() async {
    return _apiService.get<List<SubscriptionPlanModel>>(
      CommonEndpoints.getPlans,
      mapper: (json) {
        if (json is List) {
          return json.map((e) => SubscriptionPlanModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResult<SubscriptionModel>> enrollSubscription(EnrollSubscriptionRequest request) async {
    return _apiService.post<SubscriptionModel>(
      CommonEndpoints.enrollSubscription,
      data: request.toJson(),
      mapper: (json) => SubscriptionModel.fromJson(json as Map<String, dynamic>),
    );
  }
}
