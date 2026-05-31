import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/payment_screen/payment_screen.dart';
import 'package:schat/features/subscription_screen/src/presentation/bloc/subscription_bloc.dart';
import 'package:schat/features/subscription_screen/src/presentation/bloc/subscription_event.dart';
import 'package:schat/features/subscription_screen/src/presentation/bloc/subscription_state.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';


class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cardBgColor = context.colors.cardBackground;
    final fieldBgColor = context.colors.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;

    return BlocProvider<SubscriptionBloc>(
      create: (context) => SubscriptionBloc()..add(const LoadPlansEvent()),
      child: Builder(
        builder: (context) {
          return BlocConsumer<SubscriptionBloc, SubscriptionState>(
            listener: (context, state) {
              if (state is SubscriptionSuccess) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaymentSuccessPage(),
                  ),
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is SubscriptionLoading || state is SubscriptionInitial;
              final plans = state is SubscriptionLoaded ? state.plans : [];
              final selectedPlanIndex = state is SubscriptionLoaded ? state.selectedIndex : -1;

              return Scaffold(
                backgroundColor: context.colors.scaffoldBackground,
                body: Column(
                  children: [
                    // Top illustration area (60% height)
                    Expanded(
                      flex: 6,
                      child: Container(
                        color: context.colors.scaffoldBackground,
                        child: SafeArea(
                          bottom: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Image.asset(
                                'assets/images/secure_chats.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom card area (40% height)
                    Expanded(
                      flex: 4,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(40),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(40),
                          ),
                          child: SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Back button (if can pop)
                                  if (Navigator.canPop(context)) ...[
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: InkWell(
                                        onTap: () => Navigator.pop(context),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Icon(
                                            CommonIcons.arrowBack,
                                            color: context.colors.textPrimary,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                    CommonSpaces.h12,
                                  ],

                                  // Header title
                                  Text.rich(
                                    TextSpan(
                                      text: "Choose a ",
                                      children: [
                                        TextSpan(
                                          text: "Plan",
                                          style: context.h1Italic.copyWith(fontSize: 28),
                                        ),
                                      ],
                                    ),
                                    style: context.h1.copyWith(fontSize: 30),
                                  ),
                                  CommonSpaces.h16,

                                  // Plans List
                                  Expanded(
                                    child: isLoading
                                        ? const Center(child: CircularProgressIndicator())
                                        : ListView.separated(
                                            itemCount: plans.length,
                                            separatorBuilder: (context, index) => CommonSpaces.h12,
                                            itemBuilder: (context, index) {
                                              final plan = plans[index];
                                              final isSelected = selectedPlanIndex == index;
                                              final planColor = isSelected ? context.colors.primary : fieldBgColor;

                                              return GestureDetector(
                                                onTap: () {
                                                  context.read<SubscriptionBloc>().add(SelectPlanEvent(planIndex: index));
                                                },
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 200),
                                                  height: 100,
                                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                  decoration: BoxDecoration(
                                                    color: planColor,
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(
                                                      color: isSelected ? Colors.transparent : context.colors.border,
                                                      width: 2,
                                                    ),
                                                    boxShadow: isSelected
                                                        ? [
                                                            BoxShadow(
                                                              color: context.colors.primary.withValues(alpha: 0.25),
                                                              blurRadius: 10,
                                                              offset: const Offset(0, 4),
                                                            )
                                                          ]
                                                        : [],
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Text(
                                                              plan.name,
                                                              style: context.titleMedium.copyWith(
                                                                color: isSelected ? Colors.white : context.colors.textPrimary,
                                                              ),
                                                            ),
                                                            CommonSpaces.h4,
                                                            Text(
                                                              '${plan.price} / ${plan.duration}',
                                                              style: context.titleSmall.copyWith(
                                                                color: isSelected ? Colors.white : context.colors.textSecondary,
                                                              ),
                                                            ),
                                                            CommonSpaces.h4,
                                                            Text(
                                                              plan.features.join(' • '),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: context.caption.copyWith(
                                                                color: isSelected ? Colors.white.withValues(alpha: 0.8) : context.colors.textHint,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      if (isSelected)
                                                        const Icon(
                                                          CommonIcons.checkCircle,
                                                          color: Colors.white,
                                                          size: 24,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                  CommonSpaces.h16,

                                  // Continue Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: selectedPlanIndex != -1
                                          ? () {
                                              context.read<SubscriptionBloc>().add(const ConfirmSubscriptionEvent());
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: context.colors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(28),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Continue',
                                            style: context.buttonText,
                                          ),
                                          CommonSpaces.w8,
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              CommonIcons.arrowForward,
                                              color: context.colors.primary,
                                              size: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
