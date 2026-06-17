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
              final isLoading = state is SubscriptionLoading || state is SubscriptionInitial || state is SubscriptionConfirming;
              final isInitialLoading = state is SubscriptionLoading || state is SubscriptionInitial;
              
              List<SubscriptionPlanModel> plans = [];
              int selectedPlanIndex = 0;

              if (state is SubscriptionLoaded) {
                plans = state.plans;
                selectedPlanIndex = state.selectedIndex;
              } else if (state is SubscriptionConfirming) {
                plans = state.plans;
                selectedPlanIndex = state.selectedIndex;
              }

              return Scaffold(
                backgroundColor: const Color(0xFFD7F9E0),
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
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

                              const Spacer(),

                              CommonSpaces.h32,

                              // Plans Horizontal Scroll
                              if (isInitialLoading && plans.isEmpty)
                                const Center(child: CircularProgressIndicator())
                              else
                                SizedBox(
                                  height: 280,
                                  child: PageView.builder(
                                    controller: PageController(
                                      viewportFraction: 0.75,
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
                                      final isPreferred = plan.name.toLowerCase() == 'business';
                                      
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
                                            child: Stack(
                                              children: [
                                                Container(
                                                  width: double.infinity,
                                                  margin: const EdgeInsets.only(top: 12),
                                                  padding: const EdgeInsets.all(24),
                                                  decoration: BoxDecoration(
                                                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                                                    borderRadius: BorderRadius.circular(24),
                                                    boxShadow: isSelected ? [
                                                      BoxShadow(
                                                        color: const Color(0xFF008E46).withOpacity(0.15),
                                                        blurRadius: 20,
                                                        spreadRadius: 5,
                                                      )
                                                    ] : [],
                                                    border: Border.all(
                                                      color: isSelected ? const Color(0xFF008E46) : Colors.transparent,
                                                      width: 2.5,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        plan.name,
                                                        style: context.titleMedium.copyWith(
                                                          color: const Color(0xFF008E46),
                                                          fontWeight: FontWeight.w900,
                                                          fontSize: 20,
                                                        ),
                                                      ),
                                                      CommonSpaces.h8,
                                                      Text(
                                                        plan.description,
                                                        maxLines: 3,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: context.bodyMedium.copyWith(
                                                          color: Colors.black.withOpacity(0.6),
                                                          fontSize: 14,
                                                          height: 1.3,
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      Row(
                                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                                        textBaseline: TextBaseline.alphabetic,
                                                        children: [
                                                          Text(
                                                            '₹${plan.price}',
                                                            style: context.h1.copyWith(
                                                              color: Colors.black,
                                                              fontSize: 32,
                                                              fontWeight: FontWeight.w900,
                                                            ),
                                                          ),
                                                          CommonSpaces.w4,
                                                          Text(
                                                            '/${plan.billingCycle == 'monthly' ? 'mo' : plan.billingCycle}',
                                                            style: context.bodySmall.copyWith(
                                                              color: Colors.black.withOpacity(0.5),
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (isPreferred)
                                                  Positioned(
                                                    top: 0,
                                                    right: 20,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF008E46),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        'MOST POPULAR',
                                                        style: context.bodySmall.copyWith(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w900,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              CommonSpaces.h14,
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                ),
                bottomNavigationBar: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 46,
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
                          :  Text(
                          'Get started',
                          style: context.titleMedium.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
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
