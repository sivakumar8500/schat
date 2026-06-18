import 'package:flutter/material.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fonts.dart';

class CommonFontStyles {
  CommonFontStyles._();

  static TextStyle h1(BuildContext context) => TextStyle(
        fontSize: 38,
        fontWeight: FontWeight.w900,
        fontFamily: CommonFonts.primaryFont,
        color: context.colors.textPrimary,
        height: 1.1,
        letterSpacing: -0.5,
      );

  static TextStyle h1Italic(BuildContext context) => TextStyle(
        fontSize: 32,
        fontStyle: FontStyle.italic,
        fontFamily: CommonFonts.accentFont,
        color: context.colors.primaryAccent,
      );

  static TextStyle h2(BuildContext context) => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        fontFamily: CommonFonts.primaryFont,
        color: context.colors.textPrimary,
      );

  static TextStyle h3(BuildContext context) => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        fontFamily: CommonFonts.primaryFont,
        color: context.colors.textPrimary,
      );

  static TextStyle titleLarge(BuildContext context) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: CommonFonts.primaryFont,
        color: context.colors.textPrimary,
      );

  static TextStyle titleMedium(BuildContext context) => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: CommonFonts.primaryFont,
        color: context.colors.textPrimary,
      );

  static TextStyle titleSmall(BuildContext context) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        fontFamily: CommonFonts.primaryFont,
        color: context.colors.textPrimary,
      );

  static TextStyle bodyLarge(BuildContext context) => TextStyle(
        fontSize: 14,
        fontFamily: CommonFonts.primaryFont,
        color: context.colors.textPrimary,
      );

  static TextStyle bodyMedium(BuildContext context) => TextStyle(
        fontSize: 12,
        fontFamily: CommonFonts.primaryFont,
        color: context.colors.textSecondary,
        height: 1.4,
      );

  static TextStyle bodySmall(BuildContext context) => TextStyle(
        fontSize: 10,
        fontFamily: CommonFonts.primaryFont,
        color: context.colors.textSecondary,
      );

  static TextStyle buttonText(BuildContext context) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        fontFamily: CommonFonts.primaryFont,
        color: Colors.white,
      );

  static TextStyle caption(BuildContext context) => TextStyle(
        fontSize: 10,
        fontFamily: CommonFonts.primaryFont,
        color: context.colors.textSecondary,
      );
}

extension CommonFontStylesExt on BuildContext {
  TextStyle get h1 => CommonFontStyles.h1(this);
  TextStyle get h1Italic => CommonFontStyles.h1Italic(this);
  TextStyle get h2 => CommonFontStyles.h2(this);
  TextStyle get h3 => CommonFontStyles.h3(this);
  TextStyle get titleLarge => CommonFontStyles.titleLarge(this);
  TextStyle get titleMedium => CommonFontStyles.titleMedium(this);
  TextStyle get titleSmall => CommonFontStyles.titleSmall(this);
  TextStyle get bodyLarge => CommonFontStyles.bodyLarge(this);
  TextStyle get bodyMedium => CommonFontStyles.bodyMedium(this);
  TextStyle get bodySmall => CommonFontStyles.bodySmall(this);
  TextStyle get buttonText => CommonFontStyles.buttonText(this);
  TextStyle get caption => CommonFontStyles.caption(this);
}
