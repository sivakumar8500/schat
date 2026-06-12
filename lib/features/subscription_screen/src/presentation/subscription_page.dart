import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/payment_screen/payment_screen.dart';
import 'package:schat/features/subscription_screen/src/domain/models/subscription_plan_model.dart';
import 'package:schat/features/subscription_screen/src/presentation/bloc/subscription_bloc.dart';
import 'package:schat/features/subscription_screen/src/presentation/bloc/subscription_event.dart';
import 'package:schat/features/subscription_screen/src/presentation/bloc/subscription_state.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_notifications.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SubscriptionBloc>(
      create: (context) => SubscriptionBloc()..add(const LoadPlansEvent()),
      child: Builder(
        builder: (context) {
          return BlocConsumer<SubscriptionBloc, SubscriptionState>(
            listener: (context, state) {
              if (state is SubscriptionSuccess) {
                context.showSuccessNotification('Subscription successful!');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaymentSuccessPage(),
                  ),
                );
              } else if (state is SubscriptionFailure) {
                context.showErrorNotification(state.error);
              }
            },
            builder: (context, state) {
              final isLoading = state is SubscriptionLoading || state is SubscriptionInitial;
              final List<SubscriptionPlanModel> plans = state is SubscriptionLoaded ? state.plans : [];
              final selectedPlanIndex = state is SubscriptionLoaded ? state.selectedIndex : 0;

              return Scaffold(
                backgroundColor: const Color(0xFFD7F9E0),
                body: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Close button and Title area
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CommonSpaces.h24,
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(width: double.infinity),
                                    Text(
                                      'Secure chats',
                                      style: context.h1.copyWith(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 36,
                                      ),
                                    ),
                                    Text(
                                      'Best in Privacy',
                                      style: context.h1Italic.copyWith(
                                        color: Colors.black.withOpacity(0.6),
                                        fontSize: 32,
                                      ),
                                    ),
                                    CommonSpaces.h16,
                                    Text(
                                      'Messages that disappear. Calls that can\'t be tapped. Files only you control.',
                                      textAlign: TextAlign.center,
                                      style: context.bodyMedium.copyWith(
                                        color: Colors.black.withOpacity(0.7),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      CommonSpaces.h32,

                      // Description / Features
                      if (plans.isNotEmpty && selectedPlanIndex >= 0 && selectedPlanIndex < plans.length)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: Color(0xFF008E46), size: 20),
                                    CommonSpaces.w8,
                                    Text(
                                      'Plan Details',
                                      style: context.titleMedium.copyWith(color: Colors.black),
                                    ),
                                  ],
                                ),
                                CommonSpaces.h12,
                                Text(
                                  plans[selectedPlanIndex].description,
                                  style: context.bodyMedium.copyWith(
                                    color: Colors.black87,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      CommonSpaces.h32,

                      // Plans Horizontal Scroll
                      if (isLoading && plans.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else
                        SizedBox(
                          height: 200,
                          child: PageView.builder(
                            controller: PageController(
                              viewportFraction: 0.7,
                              initialPage: selectedPlanIndex,
                            ),
                            onPageChanged: (index) {
                              context.read<SubscriptionBloc>().add(SelectPlanEvent(planIndex: index));
                            },
                            itemCount: plans.length,
                            padEnds: true,
                            itemBuilder: (context, index) {
                              final plan = plans[index];
                              final isSelected = selectedPlanIndex == index;
                              
                              return AnimatedScale(
                                duration: const Duration(milliseconds: 300),
                                scale: isSelected ? 1.0 : 0.9,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: isSelected ? 1.0 : 0.6,
                                  child: GestureDetector(
                                    onTap: () {
                                      context.read<SubscriptionBloc>().add(SelectPlanEvent(planIndex: index));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: isSelected ? [
                                          BoxShadow(
                                            color: const Color(0xFF008E46).withOpacity(0.1),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          )
                                        ] : [],
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFF008E46) : Colors.transparent,
                                          width: 2.0,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            plan.name,
                                            style: context.titleMedium.copyWith(
                                              color: const Color(0xFF008E46),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          CommonSpaces.h4,
                                          Text(
                                            '₹${plan.price}',
                                            style: context.h1.copyWith(
                                              color: Colors.black,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            plan.billingCycle.toUpperCase(),
                                            style: context.bodySmall.copyWith(
                                              color: Colors.black.withOpacity(0.6),
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      CommonSpaces.h40,

                      // Get Started Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: (selectedPlanIndex != -1 && !isLoading)
                                ? () => context.read<SubscriptionBloc>().add(const ConfirmSubscriptionEvent())
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF008E46),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Row(
                                  children: [
                                    const Spacer(flex: 3),
                                    Text(
                                      'Get started',
                                      style: context.titleMedium.copyWith(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(flex: 2),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward,
                                        color: Color(0xFF008E46),
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                          ),
                        ),
                      ),
                      CommonSpaces.h40,
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
