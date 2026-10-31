import 'package:flutter/material.dart';
import 'package:schat/utils/common_colors.dart';

class CommonLoadingOverlay extends StatelessWidget {
  final String title;
  final String? subtitle;

  const CommonLoadingOverlay({
    super.key,
    this.title = 'Deleting...',
    this.subtitle = 'Please wait while deleting completes',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;

    return Stack(
      children: [
        Positioned.fill(
          child: ModalBarrier(
            dismissible: false,
            color: Colors.black.withValues(alpha: 0.45),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2922) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00873C)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

