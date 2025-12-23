import 'package:flutter/material.dart';

/// Design token: Shadow/elevation system for depth and hierarchy
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     boxShadow: AppShadows.md,
///   ),
/// )
/// ```
class AppShadows {
  AppShadows._();

  // Soft, elegant shadows for modern classic aesthetic
  static List<BoxShadow> get none => const [];

  static List<BoxShadow> get xs => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get sm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get md => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get lg => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get xl => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> get xxl => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 32,
      offset: const Offset(0, 16),
    ),
  ];

  // Colored shadows for gradient cards (creates glow effect)
  static List<BoxShadow> gradientShadow(Color color, {double opacity = 0.3}) => [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Inner shadows (for pressed states, inset effects)
  static List<BoxShadow> get innerShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
      spreadRadius: -2,
    ),
  ];

  // Specific use-case patterns
  static List<BoxShadow> get cardShadow => md;
  static List<BoxShadow> get buttonShadow => sm;
  static List<BoxShadow> get dialogShadow => xl;
  static List<BoxShadow> get appBarShadow => xs;
  static List<BoxShadow> get fabShadow => lg;
}
