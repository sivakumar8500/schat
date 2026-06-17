import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/subscription_screen/src/domain/models/enroll_subscription_request.dart';
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
    on<ConfirmSubscriptionEvent>(_onConfirmSubscription);
  }

  Future<void> _onLoadPlans(LoadPlansEvent event, Emitter<SubscriptionState> emit) async {
    emit(const SubscriptionLoading());
    final result = await _subscriptionRepository.getSubscriptionPlans();
    
    result.when(
      success: (plans) {
        emit(SubscriptionLoaded(plans: plans, selectedIndex: 0));
      },
      failure: (message, statusCode) {
        emit(SubscriptionFailure(error: message));
      },
    );
  }

  void _onSelectPlan(SelectPlanEvent event, Emitter<SubscriptionState> emit) {
    final currentState = state;
    if (currentState is SubscriptionLoaded) {
      emit(SubscriptionLoaded(plans: currentState.plans, selectedIndex: event.planIndex));
    }
  }

  Future<void> _onConfirmSubscription(ConfirmSubscriptionEvent event, Emitter<SubscriptionState> emit) async {
    final currentState = state;
    if (currentState is SubscriptionLoaded && currentState.selectedIndex != -1) {
      final selectedPlan = currentState.plans[currentState.selectedIndex];
      
      emit(SubscriptionConfirming(
        plans: currentState.plans,
        selectedIndex: currentState.selectedIndex,
      ));

      final request = EnrollSubscriptionRequest(
        planId: selectedPlan.id,
        promoCode: event.promoCode ?? '',
        paymentRecordId: event.paymentRecordId ?? '',
      );

      final result = await _subscriptionRepository.enrollSubscription(request);
      
      result.when(
        success: (subscription) {
          emit(const SubscriptionSuccess());
        },
        failure: (message, statusCode) {
          // Re-emit loaded state with failure message
          emit(SubscriptionFailure(error: message));
          emit(SubscriptionLoaded(
            plans: currentState.plans,
            selectedIndex: currentState.selectedIndex,
          ));
        },
      );
    }
  }
}
