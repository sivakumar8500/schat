import 'package:injectable/injectable.dart';
import 'package:schat/features/subscription_screen/src/domain/models/subscription_plan_model.dart';
import 'package:schat/features/subscription_screen/src/domain/repositories/subscription_repository.dart';

@LazySingleton(as: SubscriptionRepository)
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  @override
  Future<List<SubscriptionPlanModel>> getSubscriptionPlans() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const [
      SubscriptionPlanModel(
        id: '1',
        name: 'Basic',
        price: '\$4.99',
        duration: '/ month',
        features: ['100 Messages per day', 'Standard Support', 'Ads Included'],
        colorHex: 0xFF607D8B, // context.colors.primaryGrey
      ),
      SubscriptionPlanModel(
        id: '2',
        name: 'Pro',
        price: '\$9.99',
        duration: '/ month',
        features: ['Unlimited Messages', 'Priority Support', 'No Ads', 'HD Media'],
        colorHex: 0xFF448AFF, // context.colors.primary
      ),
      SubscriptionPlanModel(
        id: '3',
        name: 'Premium',
        price: '\$19.99',
        duration: '/ month',
        features: ['Everything in Pro', 'Custom Themes', 'Cloud Backup', 'Exclusive Badges'],
        colorHex: 0xFF7C4DFF, // Colors.deepPurpleAccent
      ),
    ];
  }
}
