import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/common/widgets/mesh_background.dart';
import 'package:schat/features/payment_screen/payment_screen.dart';
import 'package:schat/features/subscription_screen/src/domain/models/subscription_plan_model.dart';
import 'package:schat/features/subscription_screen/src/presentation/bloc/subscription_bloc.dart';
import 'package:schat/features/subscription_screen/src/presentation/bloc/subscription_event.dart';
import 'package:schat/features/subscription_screen/src/presentation/bloc/subscription_state.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_notifications.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SubscriptionBloc>(
      create: (context) => SubscriptionBloc()..add(const LoadPlansEvent()),
      child: Builder(
        builder: (context) {
          final isDark = context.colors.isDark;

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
              final isLoading = state is SubscriptionLoading ||
                  state is SubscriptionInitial ||
                  state is SubscriptionConfirming;
              final isInitialLoading =
                  state is SubscriptionLoading || state is SubscriptionInitial;

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
                backgroundColor: context.colors.scaffoldBackground,
                body: MeshBackground(
                  child: SafeArea(
                    child: isInitialLoading && plans.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CommonSpaces.h10,
                                // Title Header
                                Text(
                                  'Choose a Plan',
                                  style: context.h1.copyWith(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    color: context.colors.textPrimary,
                                  ),
                                ),
                                CommonSpaces.h6,
                                Text(
                                  'Select the plan that fits your needs.',
                                  style: context.bodyMedium.copyWith(
                                    fontSize: 15,
                                    color: context.colors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                CommonSpaces.h20,

                                // List of Plan Cards
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: plans.length,
                                  itemBuilder: (context, index) {
                                    final plan = plans[index];
                                    final isPopular = index == 0 ||
                                        plan.name.toLowerCase() == 'customer';
                                    final isSelected = selectedPlanIndex == index;

                                    return _buildPlanCard(
                                      context: context,
                                      plan: plan,
                                      index: index,
                                      isPopular: isPopular,
                                      isSelected: isSelected,
                                      isLoading: isLoading && isSelected,
                                      isDark: isDark,
                                    );
                                  },
                                ),
                                CommonSpaces.h24,
                              ],
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

  Widget _buildPlanCard({
    required BuildContext context,
    required SubscriptionPlanModel plan,
    required int index,
    required bool isPopular,
    required bool isSelected,
    required bool isLoading,
    required bool isDark,
  }) {
    final meta = _getPlanMetadata(plan.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Outer Card Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF161B22)
                  : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isPopular
                    ? (isDark ? const Color(0xFF00FF87) : const Color(0xFF10B981))
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFFE5E7EB)),
                width: isPopular ? 1.8 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isPopular
                      ? (isDark
                          ? const Color(0xFF00FF87).withValues(alpha: 0.15)
                          : const Color(0xFF10B981).withValues(alpha: 0.12))
                      : Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: isPopular ? 16 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPopular) CommonSpaces.h8,
                // Top Row: Icon, Title + Subtitle, and Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF00FF87).withValues(alpha: 0.18)
                            : const Color(0xFFD1FADF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        meta.icon,
                        color: isDark
                            ? const Color(0xFF00FF87)
                            : const Color(0xFF00873C),
                        size: 24,
                      ),
                    ),
                    CommonSpaces.w12,
                    // Title & Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: context.titleLarge.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          CommonSpaces.h4,
                          Text(
                            meta.subtitle.isNotEmpty
                                ? meta.subtitle
                                : plan.description,
                            style: context.bodySmall.copyWith(
                              fontSize: 12.5,
                              color: context.colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹${_formatPrice(plan.price)}',
                          style: context.titleLarge.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        Text(
                          '/mo',
                          style: context.bodySmall.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                CommonSpaces.h16,

                // Bottom Content Row: Features List & Action Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Features List
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: meta.features.map((feature) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: isDark
                                      ? const Color(0xFF00FF87)
                                      : const Color(0xFF00873C),
                                ),
                                CommonSpaces.w8,
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: context.bodySmall.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.textPrimary
                                          .withValues(alpha: 0.85),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    CommonSpaces.w10,

                    // Get Plan Button
                    SizedBox(
                      height: 38,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                context.read<SubscriptionBloc>().add(
                                      SelectPlanEvent(planIndex: index),
                                    );
                                context.read<SubscriptionBloc>().add(
                                      const ConfirmSubscriptionEvent(),
                                    );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPopular
                              ? (isDark
                                  ? const Color(0xFF00FF87)
                                  : const Color(0xFF00873C))
                              : Colors.transparent,
                          foregroundColor: isPopular
                              ? (isDark ? Colors.black : Colors.white)
                              : (isDark
                                  ? const Color(0xFF00FF87)
                                  : const Color(0xFF00873C)),
                          elevation: 0,
                          side: isPopular
                              ? BorderSide.none
                              : BorderSide(
                                  color: isDark
                                      ? const Color(0xFF00FF87)
                                      : const Color(0xFF00873C),
                                  width: 1.5,
                                ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isPopular
                                        ? (isDark ? Colors.black : Colors.white)
                                        : (isDark
                                            ? const Color(0xFF00FF87)
                                            : const Color(0xFF00873C)),
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Get Plan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      color: isPopular
                                          ? (isDark ? Colors.black : Colors.white)
                                          : (isDark
                                              ? const Color(0xFF00FF87)
                                              : const Color(0xFF00873C)),
                                    ),
                                  ),
                                  CommonSpaces.w6,
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 15,
                                    color: isPopular
                                        ? (isDark ? Colors.black : Colors.white)
                                        : (isDark
                                            ? const Color(0xFF00FF87)
                                            : const Color(0xFF00873C)),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // POPULAR Capsule Badge
          if (isPopular)
            Positioned(
              top: -10,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF00FF87)
                      : const Color(0xFF00873C),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark
                              ? const Color(0xFF00FF87)
                              : const Color(0xFF00873C))
                          .withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'POPULAR',
                  style: TextStyle(
                    color: isDark ? Colors.black : Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 1000) {
      final str = price.toString();
      return '${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
    }
    return price.toString();
  }

  _PlanMeta _getPlanMetadata(String planName) {
    final lower = planName.toLowerCase().trim();
    if (lower.contains('customer')) {
      return _PlanMeta(
        icon: Icons.verified_user_rounded,
        subtitle: 'Basic features for personal use',
        features: [
          'Secure chat & calls',
          'Screen shot restriction',
          'Screen record restriction',
          'Chat translator',
          'Up to 5 devices',
        ],
      );
    } else if (lower.contains('standard')) {
      return _PlanMeta(
        icon: Icons.person_rounded,
        subtitle: 'For individuals who need more',
        features: [
          'All Customer features',
          'Hide chat & chat lock',
          'File share protection',
          'Audio & video call encryption',
          'Up to 10 devices',
        ],
      );
    } else if (lower.contains('family')) {
      return _PlanMeta(
        icon: Icons.groups_rounded,
        subtitle: 'Stay connected with your family',
        features: [
          'All Standard features',
          'Multiple user support (up to 5)',
          'Advanced privacy controls',
          'Priority support',
          'Up to 20 devices',
        ],
      );
    } else if (lower.contains('professional') || lower.contains('business')) {
      return _PlanMeta(
        icon: Icons.business_center_rounded,
        subtitle: 'For teams and small businesses',
        features: [
          'All Family features',
          'Team management',
          'Admin controls',
          'Audit logs & activity reports',
          'Up to 50 devices',
        ],
      );
    } else {
      return _PlanMeta(
        icon: Icons.apartment_rounded,
        subtitle: 'Advanced security for organizations',
        features: [
          'All Professional features',
          'Custom security policies',
          'Dedicated account manager',
          'Priority enterprise support',
          'Unlimited devices',
        ],
      );
    }
  }
}

class _PlanMeta {
  final IconData icon;
  final String subtitle;
  final List<String> features;

  const _PlanMeta({
    required this.icon,
    required this.subtitle,
    required this.features,
  });
}
