import 'package:flutter/material.dart';

/// Design token: Gradient definitions for modern classic fusion themes
///
/// Vibrant, multi-color gradients inspired by modern fitness apps with
/// refined color transitions for elegant visual impact.
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     gradient: AppGradients.lightPrimary,
///   ),
/// )
/// ```
class AppGradients {
  AppGradients._();

  // ========== LIGHT THEME GRADIENTS ==========
  // Inspired by nature: green/teal/cyan for fresh, energetic feel

  static const Gradient lightPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF10B981), // Emerald green
      Color(0xFF14B8A6), // Teal
      Color(0xFF06B6D4), // Cyan
    ],
  );

  static const Gradient lightSecondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B82F6), // Blue
      Color(0xFF8B5CF6), // Purple
    ],
  );

  static const Gradient lightAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF59E0B), // Amber
      Color(0xFFF97316), // Orange
    ],
  );

  // ========== DARK THEME GRADIENTS ==========
  // Vibrant purple/pink/magenta for energetic dark mode

  static const Gradient darkPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8B5CF6), // Purple
      Color(0xFFD946EF), // Fuchsia
      Color(0xFFEC4899), // Pink
    ],
  );

  static const Gradient darkSecondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF06B6D4), // Cyan
      Color(0xFF3B82F6), // Blue
    ],
  );

  static const Gradient darkAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFBBF24), // Yellow
      Color(0xFFF59E0B), // Amber
    ],
  );

  // ========== RETRO THEME GRADIENTS ==========
  // Warm sunset tones for vintage-inspired aesthetic

  static const Gradient retroPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFDC2626), // Red
      Color(0xFFF59E0B), // Amber
      Color(0xFFFCD34D), // Yellow
    ],
  );

  static const Gradient retroSecondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF97316), // Orange
      Color(0xFFEF4444), // Red
    ],
  );

  static const Gradient retroAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFCD34D), // Yellow
      Color(0xFFFBBF24), // Amber yellow
    ],
  );

  // ========== OCEAN BLUE THEME GRADIENTS ==========
  // Cool ocean blues for calm, professional aesthetic

  static const Gradient oceanPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0EA5E9), // Sky blue
      Color(0xFF2563EB), // Blue
      Color(0xFF4F46E5), // Indigo
    ],
  );

  static const Gradient oceanSecondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF06B6D4), // Cyan
      Color(0xFF0EA5E9), // Sky blue
    ],
  );

  static const Gradient oceanAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8B5CF6), // Purple
      Color(0xFF6366F1), // Indigo
    ],
  );

  // ========== FOREST GREEN THEME GRADIENTS ==========
  // Fresh forest greens for natural, organic feel

  static const Gradient forestPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF059669), // Emerald
      Color(0xFF0D9488), // Teal
      Color(0xFF0891B2), // Cyan
    ],
  );

  static const Gradient forestSecondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF10B981), // Emerald green
      Color(0xFF14B8A6), // Teal
    ],
  );

  static const Gradient forestAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF84CC16), // Lime
      Color(0xFF22C55E), // Green
    ],
  );

  // ========== SUNSET ORANGE THEME GRADIENTS ==========
  // Warm sunset oranges for energetic, warm aesthetic

  static const Gradient sunsetPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF97316), // Orange
      Color(0xFFF59E0B), // Amber
      Color(0xFFEAB308), // Yellow
    ],
  );

  static const Gradient sunsetSecondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEF4444), // Red
      Color(0xFFF97316), // Orange
    ],
  );

  static const Gradient sunsetAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFBBF24), // Yellow
      Color(0xFFFCD34D), // Light yellow
    ],
  );

  // ========== HIGH CONTRAST THEME ==========
  // Solid colors for accessibility (no gradients)

  static const Gradient highContrastPrimary = LinearGradient(
    colors: [Colors.black, Colors.black],
  );

  static const Gradient highContrastSecondary = LinearGradient(
    colors: [Color(0xFF1F2937), Color(0xFF1F2937)],
  );

  static const Gradient highContrastAccent = LinearGradient(
    colors: [Color(0xFF0EA5E9), Color(0xFF0EA5E9)],
  );

  // ========== UTILITY GRADIENTS ==========

  /// Creates a subtle background gradient for surfaces
  static LinearGradient backgroundGradient(Color baseColor, double opacity) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        baseColor.withValues(alpha: opacity * 0.1),
        baseColor.withValues(alpha: opacity * 0.05),
        Colors.transparent,
      ],
    );
  }

  /// Creates a gradient overlay for cards (subtle tint)
  static LinearGradient cardOverlay(List<Color> colors) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors.map((c) => c.withValues(alpha: 0.15)).toList(),
    );
  }

  /// Creates a shimmer gradient for loading states
  static LinearGradient get shimmer => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.1),
      Colors.white.withValues(alpha: 0.3),
      Colors.white.withValues(alpha: 0.1),
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  /// Creates a glass morphism gradient overlay
  static LinearGradient get glassMorphism => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.2),
      Colors.white.withValues(alpha: 0.1),
    ],
  );
}
