import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/subscription_screen/src/domain/models/enroll_subscription_request.dart';
import 'package:schat/features/subscription_screen/src/domain/models/coupon_model.dart';
import 'package:schat/features/subscription_screen/src/domain/repositories/subscription_repository.dart';
import 'package:schat/injection.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository _subscriptionRepository;

  SubscriptionBloc({SubscriptionRepository? subscriptionRepository})
      : _subscriptionRepository = subscriptionRepository ?? getIt<SubscriptionRepository>(),
        super(const SubscriptionInitial()) {
    on<LoadPlansEvent>(_onLoadPlans);
    on<SelectPlanEvent>(_onSelectPlan);
    on<ApplyCouponEvent>(_onApplyCoupon);
    on<RemoveCouponEvent>(_onRemoveCoupon);
    on<InitiatePaymentEvent>(_onInitiatePayment);
    on<RazorpayPaymentSuccessEvent>(_onRazorpayPaymentSuccess);
    on<RazorpayPaymentFailedEvent>(_onRazorpayPaymentFailed);
    on<ConfirmSubscriptionEvent>(_onConfirmSubscription);
  }

  Future<void> _onLoadPlans(LoadPlansEvent event, Emitter<SubscriptionState> emit) async {
    emit(const SubscriptionLoading());
    final plansResult = await _subscriptionRepository.getSubscriptionPlans();
    final couponsResult = await _subscriptionRepository.getCoupons();

    List<CouponModel> coupons = [];
    couponsResult.when(
      success: (list) => coupons = list,
      failure: (msg, code) => coupons = [],
    );

    plansResult.when(
      success: (plans) {
        emit(SubscriptionLoaded(
          plans: plans,
          selectedIndex: 0,
          availableCoupons: coupons,
        ));
      },
      failure: (message, statusCode) {
        emit(SubscriptionFailure(error: message));
      },
    );
  }

  Future<void> _onSelectPlan(SelectPlanEvent event, Emitter<SubscriptionState> emit) async {
    final currentState = state;
    if (currentState is SubscriptionLoaded) {
      if (event.planIndex < 0 || event.planIndex >= currentState.plans.length) return;
      final newPlan = currentState.plans[event.planIndex];

      // Re-validate coupon against newly selected plan if already applied
      if (currentState.appliedCoupon != null) {
        emit(currentState.copyWith(
          selectedIndex: event.planIndex,
          isValidatingCoupon: true,
          clearCouponError: true,
        ));

        final couponResult = await _subscriptionRepository.validateCoupon(
          currentState.appliedCoupon!.code,
          newPlan.id,
        );

        couponResult.when(
          success: (val) {
            emit(currentState.copyWith(
              selectedIndex: event.planIndex,
              appliedCoupon: val,
              isValidatingCoupon: false,
              clearCouponError: true,
            ));
          },
          failure: (msg, _) {
            emit(currentState.copyWith(
              selectedIndex: event.planIndex,
              clearCoupon: true,
              isValidatingCoupon: false,
              couponError: msg,
            ));
          },
        );
      } else {
        emit(currentState.copyWith(
          selectedIndex: event.planIndex,
          clearCouponError: true,
        ));
      }
    }
  }

  Future<void> _onApplyCoupon(ApplyCouponEvent event, Emitter<SubscriptionState> emit) async {
    final currentState = state;
    if (currentState is SubscriptionLoaded) {
      final selectedPlan = currentState.selectedPlan;
      if (selectedPlan == null) return;

      final cleanCode = event.couponCode.trim();
      if (cleanCode.isEmpty) {
        emit(currentState.copyWith(couponError: 'Please enter a valid coupon code'));
        return;
      }

      emit(currentState.copyWith(
        isValidatingCoupon: true,
        clearCouponError: true,
      ));

      final result = await _subscriptionRepository.validateCoupon(
        cleanCode,
        selectedPlan.id,
      );

      result.when(
        success: (val) {
          emit(currentState.copyWith(
            appliedCoupon: val,
            isValidatingCoupon: false,
            clearCouponError: true,
          ));
        },
        failure: (msg, _) {
          emit(currentState.copyWith(
            isValidatingCoupon: false,
            couponError: msg,
          ));
        },
      );
    }
  }

  void _onRemoveCoupon(RemoveCouponEvent event, Emitter<SubscriptionState> emit) {
    final currentState = state;
    if (currentState is SubscriptionLoaded) {
      emit(currentState.copyWith(clearCoupon: true, clearCouponError: true));
    }
  }

  Future<void> _onInitiatePayment(InitiatePaymentEvent event, Emitter<SubscriptionState> emit) async {
    final currentState = state;
    if (currentState is SubscriptionLoaded) {
      final selectedPlan = currentState.selectedPlan;
      if (selectedPlan == null) return;

      final couponCode = currentState.appliedCoupon?.code;
      final finalAmount = currentState.finalPrice;

      // Handle 100% discount free plan
      if (finalAmount <= 0) {
        emit(SubscriptionConfirming(
          plans: currentState.plans,
          selectedIndex: currentState.selectedIndex,
          appliedCoupon: currentState.appliedCoupon,
        ));

        final enrollRes = await _subscriptionRepository.enrollSubscription(
          EnrollSubscriptionRequest(
            planId: selectedPlan.id,
            promoCode: couponCode ?? '',
            paymentRecordId: 'COUPON_100_FREE',
          ),
        );

        enrollRes.when(
          success: (_) => emit(const SubscriptionSuccess()),
          failure: (err, _) {
            emit(SubscriptionFailure(error: err));
            emit(currentState);
          },
        );
        return;
      }

      emit(currentState.copyWith(isProcessingPayment: true));

      final orderResult = await _subscriptionRepository.createRazorpayOrder(
        planId: selectedPlan.id,
        couponCode: couponCode,
      );

      orderResult.when(
        success: (order) {
          emit(currentState.copyWith(isProcessingPayment: false));
          emit(SubscriptionPaymentReady(
            order: order,
            plan: selectedPlan,
            finalAmount: finalAmount,
            couponCode: couponCode,
          ));
        },
        failure: (err, _) {
          emit(currentState.copyWith(isProcessingPayment: false));
          emit(SubscriptionFailure(error: err));
          emit(currentState);
        },
      );
    }
  }

  Future<void> _onRazorpayPaymentSuccess(
    RazorpayPaymentSuccessEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    String planId = '';
    String? couponCode;

    final currentState = state;
    if (currentState is SubscriptionPaymentReady) {
      planId = currentState.plan.id;
      couponCode = currentState.couponCode;
    }

    emit(const SubscriptionLoading());

    final verifyResult = await _subscriptionRepository.verifyRazorpayPayment(
      planId: planId,
      orderId: event.orderId,
      paymentId: event.paymentId,
      signature: event.signature,
      couponCode: couponCode,
    );

    verifyResult.when(
      success: (subscription) {
        emit(const SubscriptionSuccess());
      },
      failure: (message, statusCode) {
        emit(SubscriptionFailure(error: message));
        add(const LoadPlansEvent());
      },
    );
  }

  void _onRazorpayPaymentFailed(
    RazorpayPaymentFailedEvent event,
    Emitter<SubscriptionState> emit,
  ) {
    emit(SubscriptionFailure(error: event.error));
  }

  Future<void> _onConfirmSubscription(
    ConfirmSubscriptionEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    add(const InitiatePaymentEvent());
  }
}
