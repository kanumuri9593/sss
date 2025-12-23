import 'package:flutter/material.dart';

/// Theme extension for storing gradient and shadow properties
///
/// This extension allows us to store custom gradient definitions
/// and shadows that aren't part of the standard Material ThemeData.
///
/// Usage:
/// ```dart
/// final themeExt = AppThemeExtension.of(context);
/// Container(
///   decoration: BoxDecoration(
///     gradient: themeExt.primaryGradient,
///   ),
/// )
/// ```
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  /// Primary gradient (used for main UI elements)
  final Gradient primaryGradient;

  /// Secondary gradient (used for accents and secondary elements)
  final Gradient secondaryGradient;

  /// Accent gradient (used for highlights and CTAs)
  final Gradient accentGradient;

  /// Background gradient (subtle overlay on surfaces)
  final Gradient backgroundGradient;

  /// Surface gradient (overlay for cards and containers)
  final Gradient surfaceGradient;

  /// Shadow for cards
  final List<BoxShadow> cardShadow;

  /// Shadow for elevated elements
  final List<BoxShadow> elevatedShadow;

  const AppThemeExtension({
    required this.primaryGradient,
    required this.secondaryGradient,
    required this.accentGradient,
    required this.backgroundGradient,
    required this.surfaceGradient,
    required this.cardShadow,
    required this.elevatedShadow,
  });

  @override
  AppThemeExtension copyWith({
    Gradient? primaryGradient,
    Gradient? secondaryGradient,
    Gradient? accentGradient,
    Gradient? backgroundGradient,
    Gradient? surfaceGradient,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? elevatedShadow,
  }) {
    return AppThemeExtension(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      secondaryGradient: secondaryGradient ?? this.secondaryGradient,
      accentGradient: accentGradient ?? this.accentGradient,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      surfaceGradient: surfaceGradient ?? this.surfaceGradient,
      cardShadow: cardShadow ?? this.cardShadow,
      elevatedShadow: elevatedShadow ?? this.elevatedShadow,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) {
      return this;
    }
    // Gradients don't interpolate well, so we'll just switch at t > 0.5
    return t < 0.5 ? this : other;
  }

  /// Helper method to access theme extension from context
  static AppThemeExtension of(BuildContext context) {
    final extension = Theme.of(context).extension<AppThemeExtension>();
    if (extension == null) {
      throw FlutterError(
        'AppThemeExtension not found in theme. '
        'Make sure AppTheme is properly configured.',
      );
    }
    return extension;
  }

  /// Helper method to safely access theme extension (returns null if not found)
  static AppThemeExtension? maybeOf(BuildContext context) {
    return Theme.of(context).extension<AppThemeExtension>();
  }
}
