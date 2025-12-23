import 'package:flutter/material.dart';

/// Design token: Typography system for modern classic fusion aesthetic
///
/// Combines classic serif-inspired headings with modern sans-serif body text
/// for refined elegance meets contemporary design.
///
/// Usage:
/// ```dart
/// Text(
///   'Hello',
///   style: AppTypography.heading1(context),
/// )
/// ```
class AppTypography {
  AppTypography._();

  // Font families
  // Note: Using system fonts for maximum compatibility
  // On iOS: SF Pro Display/Text
  // On Android: Roboto
  // For classic serif headings, we'll use platform-appropriate serif fonts
  static const String displayFontFamily = 'serif'; // System serif
  static const String bodyFontFamily = ''; // System default (SF Pro/Roboto)

  // Font weights (classic approach with modern hierarchy)
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // Letter spacing (refined, classic spacing)
  static const double tightSpacing = -0.5;
  static const double normalSpacing = 0.0;
  static const double wideSpacing = 0.5;
  static const double extraWideSpacing = 1.0;
  static const double displaySpacing = -0.25;

  // Line heights (classic readability ratios)
  static const double tight = 1.2;
  static const double normal = 1.5;
  static const double relaxed = 1.75;

  // Create complete Material 3 TextTheme with modern classic fusion
  static TextTheme createTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      // Display styles - Large headlines, serif for elegance
      displayLarge: TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 57,
        fontWeight: light,
        letterSpacing: displaySpacing,
        height: tight,
        color: colorScheme.onSurface,
      ),
      displayMedium: TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 45,
        fontWeight: light,
        letterSpacing: normalSpacing,
        height: tight,
        color: colorScheme.onSurface,
      ),
      displaySmall: TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 36,
        fontWeight: regular,
        letterSpacing: normalSpacing,
        height: tight,
        color: colorScheme.onSurface,
      ),

      // Headline styles - Serif for classic elegance
      headlineLarge: TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 32,
        fontWeight: regular,
        letterSpacing: normalSpacing,
        height: normal,
        color: colorScheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 28,
        fontWeight: regular,
        letterSpacing: normalSpacing,
        height: normal,
        color: colorScheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 24,
        fontWeight: medium,
        letterSpacing: normalSpacing,
        height: normal,
        color: colorScheme.onSurface,
      ),

      // Title styles - Sans-serif for modern clarity
      titleLarge: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 22,
        fontWeight: semiBold,
        letterSpacing: normalSpacing,
        height: normal,
        color: colorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 16,
        fontWeight: semiBold,
        letterSpacing: wideSpacing,
        height: normal,
        color: colorScheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 14,
        fontWeight: semiBold,
        letterSpacing: wideSpacing,
        height: normal,
        color: colorScheme.onSurface,
      ),

      // Body styles - Sans-serif for readability
      bodyLarge: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 16,
        fontWeight: regular,
        letterSpacing: normalSpacing,
        height: normal,
        color: colorScheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 14,
        fontWeight: regular,
        letterSpacing: normalSpacing,
        height: normal,
        color: colorScheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 12,
        fontWeight: regular,
        letterSpacing: normalSpacing,
        height: normal,
        color: colorScheme.onSurfaceVariant,
      ),

      // Label styles - Sans-serif, uppercase for emphasis
      labelLarge: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 14,
        fontWeight: semiBold,
        letterSpacing: wideSpacing,
        height: tight,
        color: colorScheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 12,
        fontWeight: semiBold,
        letterSpacing: wideSpacing,
        height: tight,
        color: colorScheme.onSurface,
      ),
      labelSmall: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 11,
        fontWeight: medium,
        letterSpacing: wideSpacing,
        height: tight,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  // Convenience methods for quick access
  static TextStyle? displayLarge(BuildContext context) =>
      Theme.of(context).textTheme.displayLarge;
  static TextStyle? displayMedium(BuildContext context) =>
      Theme.of(context).textTheme.displayMedium;
  static TextStyle? displaySmall(BuildContext context) =>
      Theme.of(context).textTheme.displaySmall;

  static TextStyle? headlineLarge(BuildContext context) =>
      Theme.of(context).textTheme.headlineLarge;
  static TextStyle? headlineMedium(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium;
  static TextStyle? headlineSmall(BuildContext context) =>
      Theme.of(context).textTheme.headlineSmall;

  static TextStyle? titleLarge(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge;
  static TextStyle? titleMedium(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium;
  static TextStyle? titleSmall(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall;

  static TextStyle? bodyLarge(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge;
  static TextStyle? bodyMedium(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium;
  static TextStyle? bodySmall(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall;

  static TextStyle? labelLarge(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge;
  static TextStyle? labelMedium(BuildContext context) =>
      Theme.of(context).textTheme.labelMedium;
  static TextStyle? labelSmall(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall;
}
