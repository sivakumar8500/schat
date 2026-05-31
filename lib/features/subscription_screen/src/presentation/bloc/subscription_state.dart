import 'package:schat/features/subscription_screen/src/domain/models/subscription_plan_model.dart';

abstract class SubscriptionState {
  const SubscriptionState();
}

class SubscriptionInitial extends SubscriptionState {
  const SubscriptionInitial();
}

class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading();
}

class SubscriptionLoaded extends SubscriptionState {
  final List<SubscriptionPlanModel> plans;
  final int selectedIndex;

  const SubscriptionLoaded({required this.plans, required this.selectedIndex});
}

class SubscriptionSuccess extends SubscriptionState {
  const SubscriptionSuccess();
}

class SubscriptionFailure extends SubscriptionState {
  final String error;

  const SubscriptionFailure({required this.error});
}
