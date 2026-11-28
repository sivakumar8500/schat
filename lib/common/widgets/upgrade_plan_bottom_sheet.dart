import 'package:flutter/material.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/features/subscription_screen/src/presentation/subscription_page.dart';

class UpgradePlanBottomSheet extends StatelessWidget {
  final String title;
  final String description;
  final String? featureName;

  const UpgradePlanBottomSheet({
    super.key,
    this.title = 'Upgrade Your Plan',
    this.description =
        'This feature is only available on Customer, Business, and VIP plans. Upgrade your plan to unlock full access.',
    this.featureName,
  });

  static Future<bool?> show(
    BuildContext context, {
    String? title,
    String? description,
    String? featureName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => UpgradePlanBottomSheet(
        title: title ??
            (featureName != null
                ? 'Upgrade to Access $featureName'
                : 'Upgrade Your Plan'),
        description: description ??
            'This feature is only available on Customer, Business, and VIP plans. Upgrade your plan to unlock full access.',
        featureName: featureName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.isDark;
    const primaryColor = Color(0xFF00873C);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2428) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textHint.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Glowing Crown / Premium Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00873C), Color(0xFF00B050)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),

          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Highlights Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF4F7F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                _buildBenefitRow(
                  context,
                  Icons.assignment_turned_in_rounded,
                  'Shared file access history & lineage tracking',
                ),
                const SizedBox(height: 10),
                _buildBenefitRow(
                  context,
                  Icons.cleaning_services_rounded,
                  'Clear chat & permanent clear for everyone',
                ),
                const SizedBox(height: 10),
                _buildBenefitRow(
                  context,
                  Icons.shield_rounded,
                  'Screenshot prevention & privacy safeguards',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action: Navigate to Plans
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubscriptionPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: primaryColor.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'View Plans & Upgrade',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Cancel Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Maybe Later',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(BuildContext context, IconData icon, String text) {
    const primaryColor = Color(0xFF00873C);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 13,
            color: primaryColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: context.colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
