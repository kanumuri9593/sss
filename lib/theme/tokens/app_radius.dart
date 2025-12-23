import 'package:flutter/material.dart';

/// Design token: Border radius system for modern classic aesthetic
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     borderRadius: AppRadius.roundedLG,
///   ),
/// )
/// ```
class AppRadius {
  AppRadius._();

  // Radius values (modern rounded corners with classic undertones)
  static const double xs = 4.0;      // Subtle
  static const double sm = 8.0;      // Small chips, badges
  static const double md = 12.0;     // Buttons, inputs
  static const double lg = 16.0;     // Cards, containers
  static const double xl = 20.0;     // Large containers
  static const double xxl = 24.0;    // Prominent elements
  static const double circular = 999.0; // Fully rounded (pills, avatars)

  // BorderRadius helpers
  static BorderRadius get roundedXS => BorderRadius.circular(xs);
  static BorderRadius get roundedSM => BorderRadius.circular(sm);
  static BorderRadius get roundedMD => BorderRadius.circular(md);
  static BorderRadius get roundedLG => BorderRadius.circular(lg);
  static BorderRadius get roundedXL => BorderRadius.circular(xl);
  static BorderRadius get roundedXXL => BorderRadius.circular(xxl);
  static BorderRadius get roundedFull => BorderRadius.circular(circular);

  // Radius helpers (for use with single corners)
  static Radius get radiusXS => Radius.circular(xs);
  static Radius get radiusSM => Radius.circular(sm);
  static Radius get radiusMD => Radius.circular(md);
  static Radius get radiusLG => Radius.circular(lg);
  static Radius get radiusXL => Radius.circular(xl);
  static Radius get radiusXXL => Radius.circular(xxl);
  static Radius get radiusFull => Radius.circular(circular);

  // Specific use-case patterns
  static BorderRadius get buttonRadius => roundedMD;
  static BorderRadius get cardRadius => roundedLG;
  static BorderRadius get inputRadius => roundedMD;
  static BorderRadius get chipRadius => roundedSM;
  static BorderRadius get dialogRadius => roundedXL;
  static BorderRadius get sheetRadius => const BorderRadius.vertical(
    top: Radius.circular(xl),
  );

  // Custom helpers for top-only or bottom-only rounding
  static BorderRadius topOnly(double radius) => BorderRadius.vertical(
    top: Radius.circular(radius),
  );

  static BorderRadius bottomOnly(double radius) => BorderRadius.vertical(
    bottom: Radius.circular(radius),
  );

  static BorderRadius leftOnly(double radius) => BorderRadius.horizontal(
    left: Radius.circular(radius),
  );

  static BorderRadius rightOnly(double radius) => BorderRadius.horizontal(
    right: Radius.circular(radius),
  );
}
