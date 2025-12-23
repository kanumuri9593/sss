import 'package:flutter/material.dart';

/// Design token: Animation durations and curves for smooth interactions
///
/// Usage:
/// ```dart
/// AnimatedContainer(
///   duration: AppAnimations.normal,
///   curve: AppAnimations.defaultCurve,
/// )
/// ```
class AppAnimations {
  AppAnimations._();

  // Duration tokens (matching Material Design 3 recommendations)
  static const Duration instant = Duration(milliseconds: 0);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 700);
  static const Duration slowest = Duration(milliseconds: 1000);

  // Specific use-case durations
  static const Duration themeSwitch = normal;
  static const Duration pageTransition = normal;
  static const Duration buttonPress = fast;
  static const Duration dialogAppear = normal;
  static const Duration sheetSlide = normal;
  static const Duration fadeIn = fast;
  static const Duration fadeOut = fast;

  // Curve tokens (classic easing with modern feel)
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve emphasizedCurve = Curves.easeOutCubic;
  static const Curve subtleCurve = Curves.easeInOutQuad;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve snapCurve = Curves.easeOutExpo;
  static const Curve smoothCurve = Curves.easeInOutCubicEmphasized;

  // Specific use-case curves
  static const Curve buttonCurve = emphasizedCurve;
  static const Curve dialogCurve = smoothCurve;
  static const Curve sheetCurve = emphasizedCurve;
  static const Curve fadeCurve = defaultCurve;
}
