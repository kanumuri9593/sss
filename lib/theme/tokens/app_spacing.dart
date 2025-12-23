import 'package:flutter/material.dart';

/// Design token: Spacing system based on 4px increments
///
/// Usage:
/// ```dart
/// Padding(
///   padding: AppSpacing.paddingMD,
///   child: Widget(),
/// )
/// ```
class AppSpacing {
  AppSpacing._();

  // Base spacing scale (4px system - Material Design 3 compliant)
  static const double xxs = 4.0;    // Micro spacing
  static const double xs = 8.0;     // Extra small
  static const double sm = 12.0;    // Small
  static const double md = 16.0;    // Medium (base)
  static const double lg = 24.0;    // Large
  static const double xl = 32.0;    // Extra large
  static const double xxl = 48.0;   // Double XL
  static const double xxxl = 64.0;  // Triple XL

  // Common EdgeInsets patterns
  static const EdgeInsets paddingXXS = EdgeInsets.all(xxs);
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);
  static const EdgeInsets paddingXXL = EdgeInsets.all(xxl);
  static const EdgeInsets paddingXXXL = EdgeInsets.all(xxxl);

  // Specific use-case patterns
  static const EdgeInsets cardPadding = EdgeInsets.all(sm);
  static const EdgeInsets screenPadding = EdgeInsets.all(md);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: md,
  );

  // Horizontal spacing
  static const EdgeInsets horizontalXS = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSM = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMD = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLG = EdgeInsets.symmetric(horizontal: lg);

  // Vertical spacing
  static const EdgeInsets verticalXS = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSM = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMD = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLG = EdgeInsets.symmetric(vertical: lg);

  // Gap spacing (for use with SizedBox)
  static const SizedBox gapXXS = SizedBox(height: xxs, width: xxs);
  static const SizedBox gapXS = SizedBox(height: xs, width: xs);
  static const SizedBox gapSM = SizedBox(height: sm, width: sm);
  static const SizedBox gapMD = SizedBox(height: md, width: md);
  static const SizedBox gapLG = SizedBox(height: lg, width: lg);
  static const SizedBox gapXL = SizedBox(height: xl, width: xl);

  // Vertical gaps
  static const SizedBox verticalGapXXS = SizedBox(height: xxs);
  static const SizedBox verticalGapXS = SizedBox(height: xs);
  static const SizedBox verticalGapSM = SizedBox(height: sm);
  static const SizedBox verticalGapMD = SizedBox(height: md);
  static const SizedBox verticalGapLG = SizedBox(height: lg);
  static const SizedBox verticalGapXL = SizedBox(height: xl);

  // Horizontal gaps
  static const SizedBox horizontalGapXXS = SizedBox(width: xxs);
  static const SizedBox horizontalGapXS = SizedBox(width: xs);
  static const SizedBox horizontalGapSM = SizedBox(width: sm);
  static const SizedBox horizontalGapMD = SizedBox(width: md);
  static const SizedBox horizontalGapLG = SizedBox(width: lg);
  static const SizedBox horizontalGapXL = SizedBox(width: xl);
}
