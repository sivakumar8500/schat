import 'package:flutter_bloc/flutter_bloc.dart';
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
    try {
      final plans = await _subscriptionRepository.getSubscriptionPlans();
      emit(SubscriptionLoaded(plans: plans, selectedIndex: -1));
    } catch (e) {
      emit(SubscriptionFailure(error: e.toString()));
    }
  }

  void _onSelectPlan(SelectPlanEvent event, Emitter<SubscriptionState> emit) {
    final currentState = state;
    if (currentState is SubscriptionLoaded) {
      emit(SubscriptionLoaded(plans: currentState.plans, selectedIndex: event.planIndex));
    }
  }

  void _onConfirmSubscription(ConfirmSubscriptionEvent event, Emitter<SubscriptionState> emit) {
    final currentState = state;
    if (currentState is SubscriptionLoaded && currentState.selectedIndex != -1) {
      emit(const SubscriptionSuccess());
    }
  }
}
