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

class ApplyCouponEvent extends SubscriptionEvent {
  final String couponCode;
  const ApplyCouponEvent({required this.couponCode});
}

class RemoveCouponEvent extends SubscriptionEvent {
  const RemoveCouponEvent();
}

class InitiatePaymentEvent extends SubscriptionEvent {
  const InitiatePaymentEvent();
}

class RazorpayPaymentSuccessEvent extends SubscriptionEvent {
  final String orderId;
  final String paymentId;
  final String signature;

  const RazorpayPaymentSuccessEvent({
    required this.orderId,
    required this.paymentId,
    required this.signature,
  });
}

class RazorpayPaymentFailedEvent extends SubscriptionEvent {
  final String error;
  const RazorpayPaymentFailedEvent({required this.error});
}

class ConfirmSubscriptionEvent extends SubscriptionEvent {
  final String? promoCode;
  final String? paymentRecordId;

  const ConfirmSubscriptionEvent({
    this.promoCode,
    this.paymentRecordId,
  });
}
