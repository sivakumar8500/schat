import 'dart:ui' as ui;
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
                backgroundColor: const Color(0xFFEDF1F5),
                appBar: AppBar(
                  backgroundColor: const Color(0xFFEDF1F5),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: Navigator.canPop(context)
                      ? IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF3E4C59),
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        )
                      : null,
                  centerTitle: true,
                  title: Text(
                    'CHOOSE A PLAN',
                    style: context.h2.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: const Color(0xFF3E4C59),
                    ),
                  ),
                ),
                body: SafeArea(
                  child: isInitialLoading && plans.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 16.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Select the plan that fits your needs',
                                textAlign: TextAlign.center,
                                style: context.bodyMedium.copyWith(
                                  fontSize: 14,
                                  color: const Color(0xFF616E7C),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              CommonSpaces.h24,
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: plans.length,
                                itemBuilder: (context, index) {
                                  final plan = plans[index];
                                  final isSelected = selectedPlanIndex == index;

                                  return Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 320,
                                      ),
                                      child: _buildPricingTableCard(
                                        context: context,
                                        plan: plan,
                                        index: index,
                                        isSelected: isSelected,
                                        isLoading: isLoading && isSelected,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              CommonSpaces.h20,
                            ],
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

  Widget _buildPricingTableCard({
    required BuildContext context,
    required SubscriptionPlanModel plan,
    required int index,
    required bool isSelected,
    required bool isLoading,
  }) {
    final style = _getCardStyle(index, plan.name);
    const double topTabHeight = 44.0;
    const double topTabWidth = 195.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Protruding Top Header Tab (BASIC / BUSINESS / PREMIUM style)
          Container(
            width: topTabWidth,
            height: topTabHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  style.lightAccent,
                  style.primaryAccent,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              boxShadow: [
                BoxShadow(
                  color: style.primaryAccent.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Text(
              plan.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
              ),
            ),
          ),

          // Main White Card Body with V-Shaped Diffused Glow Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFDFEFF),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1F2933).withValues(alpha: 0.14),
                  blurRadius: 26,
                  spreadRadius: 1,
                  offset: const Offset(-10, 14),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.8),
                  blurRadius: 6,
                  offset: const Offset(2, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  // Soft Feathered V-Cone Glow Under the Top Tab
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 125,
                    child: CustomPaint(
                      painter: _TopGlowConePainter(
                        topTabWidth: topTabWidth,
                        lightColor: style.lightAccent,
                        primaryColor: style.primaryAccent,
                      ),
                    ),
                  ),

                  // Thin White Divider Line Under Tab Edge
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: topTabWidth,
                        height: 1.2,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ),

                  // Card Content (Price + Feature Checklist + Get Started Button)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Price inside the glowing cone
                        Text(
                          '₹${_formatPrice(plan.price)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 31,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.1,
                            shadows: [
                              Shadow(
                                color: Color(0x29000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.billingCycle.toLowerCase().contains('year')
                              ? 'per year'
                              : 'per month',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),

                        const SizedBox(height: 46),

                        // Features List with Green Check / Red Cross Icons
                        ...style.features.map((feature) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: feature.included
                                        ? const Color(0xFF1CB854)
                                        : const Color(0xFFD62828),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    feature.included
                                        ? Icons.check_rounded
                                        : Icons.close_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    feature.title,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: style.textAccent,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 14),

                        // Centered Pill Button ("Get Started")
                        SizedBox(
                          width: 146,
                          height: 40,
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
                              backgroundColor: const Color(0xFFB3C1CE),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  style.primaryAccent.withValues(alpha: 0.7),
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Get Started',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

  _PricingCardStyle _getCardStyle(int index, String planName) {
    final lower = planName.toLowerCase().trim();

    // Palette matching the reference image:
    // 0: Cyan (Basic)
    // 1: Indigo-Blue (Business)
    // 2: Orchid-Purple (Premium)
    // 3: Emerald-Teal (Professional)
    // 4: Royal Amber/Coral (Enterprise)
    final List<List<Color>> palettes = [
      // Cyan (Basic)
      const [
        Color(0xFF33D1FF),
        Color(0xFF14B9F1),
        Color(0xFF28B5E1),
      ],
      // Indigo (Business)
      const [
        Color(0xFF6B81E8),
        Color(0xFF566CD6),
        Color(0xFF5C70CF),
      ],
      // Purple (Premium)
      const [
        Color(0xFFA75DD2),
        Color(0xFF9247BE),
        Color(0xFF964EC1),
      ],
      // Emerald (Professional)
      const [
        Color(0xFF24C98B),
        Color(0xFF0FA96E),
        Color(0xFF14A870),
      ],
      // Coral/Rose (Enterprise)
      const [
        Color(0xFFF46B6B),
        Color(0xFFE04848),
        Color(0xFFD94B4B),
      ],
    ];

    final palette = palettes[index % palettes.length];

    if (lower.contains('customer') || lower.contains('basic') || index == 0) {
      return _PricingCardStyle(
        lightAccent: palette[0],
        primaryAccent: palette[1],
        textAccent: palette[2],
        features: const [
          _PlanFeatureItem('Secure chat & calls', true),
          _PlanFeatureItem('Screenshot restriction', true),
          _PlanFeatureItem('Screen record restriction', true),
          _PlanFeatureItem('Hide chat & chat lock', false),
          _PlanFeatureItem('File share protection', false),
          _PlanFeatureItem('Multi-device & team controls', false),
        ],
      );
    } else if (lower.contains('standard') ||
        lower.contains('business') ||
        index == 1) {
      return _PricingCardStyle(
        lightAccent: palette[0],
        primaryAccent: palette[1],
        textAccent: palette[2],
        features: const [
          _PlanFeatureItem('Secure chat & calls', true),
          _PlanFeatureItem('Screenshot restriction', true),
          _PlanFeatureItem('Screen record restriction', true),
          _PlanFeatureItem('Hide chat & chat lock', true),
          _PlanFeatureItem('File share protection', false),
          _PlanFeatureItem('Multi-device & team controls', false),
        ],
      );
    } else if (lower.contains('family') || index == 2) {
      return _PricingCardStyle(
        lightAccent: palette[0],
        primaryAccent: palette[1],
        textAccent: palette[2],
        features: const [
          _PlanFeatureItem('Secure chat & calls', true),
          _PlanFeatureItem('Screenshot restriction', true),
          _PlanFeatureItem('Screen record restriction', true),
          _PlanFeatureItem('Hide chat & chat lock', true),
          _PlanFeatureItem('File share protection', true),
          _PlanFeatureItem('Multi-device & team controls', false),
        ],
      );
    } else {
      return _PricingCardStyle(
        lightAccent: palette[0],
        primaryAccent: palette[1],
        textAccent: palette[2],
        features: const [
          _PlanFeatureItem('Secure chat & calls', true),
          _PlanFeatureItem('Screenshot restriction', true),
          _PlanFeatureItem('Screen record restriction', true),
          _PlanFeatureItem('Hide chat & chat lock', true),
          _PlanFeatureItem('File share protection', true),
          _PlanFeatureItem('Multi-device & team controls', true),
        ],
      );
    }
  }
}

class _PlanFeatureItem {
  final String title;
  final bool included;

  const _PlanFeatureItem(this.title, this.included);
}

class _PricingCardStyle {
  final Color lightAccent;
  final Color primaryAccent;
  final Color textAccent;
  final List<_PlanFeatureItem> features;

  const _PricingCardStyle({
    required this.lightAccent,
    required this.primaryAccent,
    required this.textAccent,
    required this.features,
  });
}

class _TopGlowConePainter extends CustomPainter {
  final double topTabWidth;
  final Color lightColor;
  final Color primaryColor;

  const _TopGlowConePainter({
    required this.topTabWidth,
    required this.lightColor,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double halfTab = (topTabWidth / 2) + 8;
    final double leftX = centerX - halfTab;
    final double rightX = centerX + halfTab;
    final double tipY = size.height * 0.90;

    // Outer soft halo
    final Path outerPath = Path()
      ..moveTo(leftX - 14, -18)
      ..lineTo(rightX + 14, -18)
      ..quadraticBezierTo(
        centerX + 26,
        tipY * 0.72,
        centerX,
        tipY + 8,
      )
      ..quadraticBezierTo(
        centerX - 26,
        tipY * 0.72,
        leftX - 14,
        -18,
      )
      ..close();

    final Paint outerPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, tipY + 8),
        [
          primaryColor.withValues(alpha: 0.85),
          lightColor.withValues(alpha: 0.45),
          lightColor.withValues(alpha: 0.0),
        ],
        const [0.0, 0.65, 1.0],
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    canvas.drawPath(outerPath, outerPaint);

    // Core vibrant V-cone
    final Path innerPath = Path()
      ..moveTo(leftX, -12)
      ..lineTo(rightX, -12)
      ..quadraticBezierTo(
        centerX + 18,
        tipY * 0.68,
        centerX,
        tipY - 2,
      )
      ..quadraticBezierTo(
        centerX - 18,
        tipY * 0.68,
        leftX,
        -12,
      )
      ..close();

    final Paint innerPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, tipY),
        [
          primaryColor,
          lightColor.withValues(alpha: 0.92),
          lightColor.withValues(alpha: 0.15),
        ],
        const [0.0, 0.58, 1.0],
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11);

    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _TopGlowConePainter oldDelegate) {
    return oldDelegate.topTabWidth != topTabWidth ||
        oldDelegate.lightColor != lightColor ||
        oldDelegate.primaryColor != primaryColor;
  }
}
