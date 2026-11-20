import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:schat/core/config/payment_config.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/injection.dart';
import 'package:schat/features/payment_screen/payment_screen.dart';
import 'package:schat/features/subscription_screen/src/domain/models/coupon_model.dart';
import 'package:schat/features/subscription_screen/src/domain/models/subscription_plan_model.dart';
import 'package:schat/features/subscription_screen/src/presentation/bloc/subscription_bloc.dart';
import 'package:schat/features/subscription_screen/src/presentation/bloc/subscription_event.dart';
import 'package:schat/features/subscription_screen/src/presentation/bloc/subscription_state.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/common/widgets/app_home_background.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  late Razorpay _razorpay;
  final TextEditingController _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _couponController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (!mounted) return;
    context.read<SubscriptionBloc>().add(
      RazorpayPaymentSuccessEvent(
        orderId: response.orderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    final detail = response.message != null && response.message!.isNotEmpty
        ? response.message!
        : (response.code != null ? 'Payment error code: ${response.code}' : 'Payment cancelled or failed');
    context.read<SubscriptionBloc>().add(
      RazorpayPaymentFailedEvent(error: detail),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // External wallet selected
  }

  void _openRazorpayCheckout(SubscriptionPaymentReady state) {
    final storage = getIt.isRegistered<StorageService>() ? getIt<StorageService>() : null;
    final phone = storage?.getPhoneNumber() ?? '';

    // Prefer key_id returned from server order, fallback to client config
    final keyToUse = (state.order.keyId != null && state.order.keyId!.trim().isNotEmpty)
        ? state.order.keyId!.trim()
        : PaymentConfig.razorpayKeyId;

    final Map<String, dynamic> prefill = {};
    if (phone.isNotEmpty) {
      final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
      if (clean.length >= 10) {
        prefill['contact'] = clean;
      }
    }

    final options = {
      'key': keyToUse,
      'amount': state.order.amount,
      'name': PaymentConfig.appName,
      'description': '${state.plan.name} Plan Subscription',
      'order_id': state.order.id,
      'currency': state.order.currency,
      'prefill': prefill,
      'retry': {
        'enabled': true,
        'max_count': 3,
      },
      'theme': {
        'color': '#14B9F1',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
        context.showErrorNotification('Failed to launch payment gateway: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SubscriptionBloc>(
      create: (context) => SubscriptionBloc()..add(const LoadPlansEvent()),
      child: Builder(
        builder: (context) {
          return BlocConsumer<SubscriptionBloc, SubscriptionState>(
            listener: (context, state) {
              if (state is SubscriptionPaymentReady) {
                _openRazorpayCheckout(state);
              } else if (state is SubscriptionSuccess) {
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
              final isInitialLoading = state is SubscriptionLoading || state is SubscriptionInitial;

              List<SubscriptionPlanModel> plans = [];
              int selectedPlanIndex = 0;
              CouponValidationResult? appliedCoupon;
              List<CouponModel> availableCoupons = [];
              bool isValidatingCoupon = false;
              String? couponError;
              bool isProcessingPayment = false;

              if (state is SubscriptionLoaded) {
                plans = state.plans;
                selectedPlanIndex = state.selectedIndex;
                appliedCoupon = state.appliedCoupon;
                availableCoupons = state.availableCoupons;
                isValidatingCoupon = state.isValidatingCoupon;
                couponError = state.couponError;
                isProcessingPayment = state.isProcessingPayment;
              } else if (state is SubscriptionConfirming) {
                plans = state.plans;
                selectedPlanIndex = state.selectedIndex;
                appliedCoupon = state.appliedCoupon;
                isProcessingPayment = true;
              }

              return Scaffold(
                backgroundColor: context.colors.scaffoldBackground,
                body: Stack(
                  children: [
                    // Home background wallpaper
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: AppHomeBackground(),
                      ),
                    ),

                    // Main Content
                    SafeArea(
                      child: Column(
                        children: [
                          AppBar(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            scrolledUnderElevation: 0,
                            leading: Navigator.canPop(context)
                                ? IconButton(
                                    icon: Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: context.colors.textPrimary,
                                      size: 20,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  )
                                : null,
                            centerTitle: true,
                            title: Text(
                              'UPGRADE YOUR PLAN',
                              style: context.h2.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: isInitialLoading && plans.isEmpty
                                ? const Center(child: CircularProgressIndicator())
                                : SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0,
                                      vertical: 8.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Select the plan that fits your needs',
                                          textAlign: TextAlign.center,
                                          style: context.bodyMedium.copyWith(
                                            fontSize: 14,
                                            color: context.colors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        CommonSpaces.h16,

                                        // Available Coupon Offers Bar
                                        if (availableCoupons.isNotEmpty) ...[
                                          _buildCouponsCarousel(
                                            context,
                                            availableCoupons,
                                            appliedCoupon,
                                          ),
                                          CommonSpaces.h16,
                                        ],

                                        // Coupon Input Card
                                        _buildCouponInputSection(
                                          context,
                                          appliedCoupon,
                                          isValidatingCoupon,
                                          couponError,
                                        ),
                                        CommonSpaces.h24,

                                        // Pricing Cards List
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
                                                  maxWidth: 340,
                                                ),
                                                child: _buildPricingTableCard(
                                                  context: context,
                                                  plan: plan,
                                                  index: index,
                                                  isSelected: isSelected,
                                                  isLoading: isProcessingPayment && isSelected,
                                                  appliedCoupon: isSelected ? appliedCoupon : null,
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
                        ],
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

  /// Horizontal Available Coupons List
  Widget _buildCouponsCarousel(
    BuildContext context,
    List<CouponModel> coupons,
    CouponValidationResult? appliedCoupon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_offer_rounded, size: 16, color: Color(0xFF14B9F1)),
            const SizedBox(width: 6),
            Text(
              'AVAILABLE OFFERS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: coupons.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              final isApplied = appliedCoupon?.code.toUpperCase() == coupon.code.toUpperCase();

              return InkWell(
                onTap: () {
                  if (isApplied) {
                    context.read<SubscriptionBloc>().add(const RemoveCouponEvent());
                  } else {
                    _couponController.text = coupon.code;
                    context.read<SubscriptionBloc>().add(ApplyCouponEvent(couponCode: coupon.code));
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isApplied
                        ? const Color(0xFF14B9F1).withValues(alpha: 0.14)
                        : context.colors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isApplied ? const Color(0xFF14B9F1) : context.colors.border,
                      width: isApplied ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                coupon.code,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: Color(0xFF14B9F1),
                                ),
                              ),
                              if (isApplied) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF1CB854)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            coupon.discountType == 'percentage'
                                ? '${coupon.discountValue.toInt()}% OFF${coupon.maxDiscountAmount != null ? ' up to ₹${coupon.maxDiscountAmount!.toInt()}' : ''}'
                                : 'Flat ₹${coupon.discountValue.toInt()} OFF',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isApplied ? const Color(0xFFE04848).withValues(alpha: 0.12) : const Color(0xFF14B9F1).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isApplied ? 'REMOVE' : 'APPLY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isApplied ? const Color(0xFFE04848) : const Color(0xFF14B9F1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Coupon code textfield & active applied status card
  Widget _buildCouponInputSection(
    BuildContext context,
    CouponValidationResult? appliedCoupon,
    bool isValidatingCoupon,
    String? couponError,
  ) {
    if (appliedCoupon != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1CB854).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1CB854), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF1CB854),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'COUPON APPLIED: ${appliedCoupon.code}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F823B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Saved ₹${_formatAmount(appliedCoupon.discountAmount)} with ${appliedCoupon.name}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2933),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Color(0xFFD62828), size: 20),
              tooltip: 'Remove coupon',
              onPressed: () {
                _couponController.clear();
                context.read<SubscriptionBloc>().add(const RemoveCouponEvent());
              },
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: context.colors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: couponError != null ? const Color(0xFFD62828) : context.colors.border,
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.confirmation_number_outlined, size: 20, color: Color(0xFF14B9F1)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter coupon code (e.g. SPECIAL20)',
                    hintStyle: TextStyle(
                      color: context.colors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: isValidatingCoupon
                      ? null
                      : () {
                          final code = _couponController.text.trim();
                          if (code.isNotEmpty) {
                            context.read<SubscriptionBloc>().add(ApplyCouponEvent(couponCode: code));
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B9F1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: isValidatingCoupon
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'APPLY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        if (couponError != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              couponError,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFFD62828),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPricingTableCard({
    required BuildContext context,
    required SubscriptionPlanModel plan,
    required int index,
    required bool isSelected,
    required bool isLoading,
    CouponValidationResult? appliedCoupon,
  }) {
    final style = _getCardStyle(index, plan);
    const double topTabHeight = 44.0;
    const double topTabWidth = 195.0;

    final double originalPrice = plan.price.toDouble();
    final bool hasDiscount = appliedCoupon != null && appliedCoupon.discountAmount > 0;
    final double finalPrice = hasDiscount ? appliedCoupon.finalPrice : originalPrice;
    final double discountAmount = hasDiscount ? appliedCoupon.discountAmount : 0.0;

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
              border: isSelected
                  ? Border.all(color: style.primaryAccent, width: 2.0)
                  : null,
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
                    height: 140,
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
                        // Price inside glowing cone (showing original struck-out & final discounted amount)
                        if (hasDiscount) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '₹${_formatAmount(originalPrice)}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.white,
                                  decorationThickness: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1CB854),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  appliedCoupon.discountType == 'percentage'
                                      ? '${appliedCoupon.discountValue.toInt()}% OFF'
                                      : '-₹${_formatAmount(discountAmount)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                        ],

                        Text(
                          '₹${_formatAmount(finalPrice)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
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

                        const SizedBox(height: 38),

                        // Features List with Green Check / Red Cross Icons
                        ...style.features.map((feature) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14.0),
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

                        // Action Button ("Pay ₹XX" or "Get Started")
                        SizedBox(
                          width: 180,
                          height: 42,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    final bloc = context.read<SubscriptionBloc>();
                                    if (!isSelected) {
                                      bloc.add(SelectPlanEvent(planIndex: index));
                                    } else {
                                      bloc.add(const InitiatePaymentEvent());
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? style.primaryAccent
                                  : const Color(0xFFB3C1CE),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  style.primaryAccent.withValues(alpha: 0.7),
                              elevation: isSelected ? 4 : 0,
                              shadowColor: style.primaryAccent.withValues(alpha: 0.35),
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
                                : Text(
                                    isSelected
                                        ? (finalPrice <= 0
                                            ? 'Activate Free'
                                            : 'Pay ₹${_formatAmount(finalPrice)}')
                                        : 'Select Plan',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      letterSpacing: 0.3,
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

  String _formatAmount(double amount) {
    if (amount == amount.truncateToDouble()) {
      final int intVal = amount.toInt();
      if (intVal >= 1000) {
        final str = intVal.toString();
        return '${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
      }
      return intVal.toString();
    }
    return amount.toStringAsFixed(2);
  }

  _PricingCardStyle _getCardStyle(int index, SubscriptionPlanModel plan) {
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
      // Purple (Premium / VIP)
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

    return _PricingCardStyle(
      lightAccent: palette[0],
      primaryAccent: palette[1],
      textAccent: palette[2],
      features: plan.effectiveFeatures,
    );
  }
}

class _PricingCardStyle {
  final Color lightAccent;
  final Color primaryAccent;
  final Color textAccent;
  final List<PlanFeatureItem> features;

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
