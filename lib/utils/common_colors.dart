import 'package:flutter/material.dart';

extension ThemeColorsExt on BuildContext {
  ThemeColors get colors => ThemeColors(this);
}

class ThemeColors {
  final BuildContext context;
  ThemeColors(this.context);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  // Brand Colors
  Color get primary => const Color(0xFF00873C);
  Color get secondary => Colors.pink;
  
  // Backgrounds
  Color get scaffoldBackground => isDark ? Colors.black : Colors.white;
  Color get pureBlack => Colors.black;
  Color get lightBackground => isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F8FF);
  
  // Text Colors
  Color get textPrimary => isDark ? Colors.white : Colors.black87;
  Color get textSecondary => isDark ? Colors.white70 : Colors.black54;
  Color get textLight => isDark ? Colors.black87 : Colors.white;
  Color get textHint => Colors.grey;

  // Status Colors
  Color get success => Colors.green;
  Color get error => Colors.redAccent;
  Color get warning => Colors.orange;

  // Borders & Dividers
  Color get border => isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0);

  // App Theme Accents & Specific Component Colors
  Color get primaryAccent => isDark ? const Color(0xFF81C784) : primary;
  Color get cardBackground => isDark ? const Color(0xFF1E2B22) : const Color(0xFFF0FDF4);
  Color get searchBackground => isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6);
  Color get optionGallery => const Color(0xFF6C63FF);
  Color get optionVideo => const Color(0xFFE91E63);
  Color get optionText => const Color(0xFF4CAF50);
  Color get optionCamera => const Color(0xFFE91E63);
  Color get videoCallGradientStart => const Color(0xFF2C3E50);
  Color get videoCallGradientEnd => const Color(0xFF000000);
}
