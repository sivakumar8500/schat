abstract class SubscriptionEvent {
  const SubscriptionEvent();
}

class LoadPlansEvent extends SubscriptionEvent {
  const LoadPlansEvent();
}

class SelectPlanEvent extends SubscriptionEvent {
  final int planIndex;
  const SelectPlanEvent({required this.planIndex});
}

class ConfirmSubscriptionEvent extends SubscriptionEvent {
  const ConfirmSubscriptionEvent();
}
