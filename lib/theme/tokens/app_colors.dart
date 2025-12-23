import 'package:flutter/material.dart';

/// Design token: Base color palette
///
/// These are the foundational colors used across all themes.
/// Most usage should prefer Theme.of(context).colorScheme for theme-aware colors.
///
/// Usage:
/// ```dart
/// Container(
///   color: AppColors.success, // For status colors
/// )
/// ```
class AppColors {
  AppColors._();

  // ========== STATUS COLORS ==========
  // Universal across all themes for semantic meaning

  static const Color success = Color(0xFF10B981); // Green
  static const Color error = Color(0xFFEF4444);   // Red
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color info = Color(0xFF3B82F6);    // Blue

  // ========== LIGHT THEME BASE COLORS ==========

  static const Color lightPrimary = Color(0xFF10B981);        // Emerald
  static const Color lightSecondary = Color(0xFF14B8A6);      // Teal
  static const Color lightAccent = Color(0xFFF59E0B);         // Amber

  static const Color lightBackground = Color(0xFFF8FAFC);     // Very light gray
  static const Color lightSurface = Color(0xFFFFFFFF);        // White
  static const Color lightOnSurface = Color(0xFF1F2937);      // Dark gray

  // ========== DARK THEME BASE COLORS ==========

  static const Color darkPrimary = Color(0xFF8B5CF6);         // Purple
  static const Color darkSecondary = Color(0xFFD946EF);       // Fuchsia
  static const Color darkAccent = Color(0xFFEC4899);          // Pink

  static const Color darkBackground = Color(0xFF0F172A);      // Very dark blue
  static const Color darkSurface = Color(0xFF1E293B);         // Dark blue-gray
  static const Color darkOnSurface = Color(0xFFF9FAFB);       // Off-white

  // ========== RETRO THEME BASE COLORS ==========

  static const Color retroPrimary = Color(0xFFDC2626);        // Red
  static const Color retroSecondary = Color(0xFFF59E0B);      // Amber
  static const Color retroAccent = Color(0xFFFCD34D);         // Yellow

  static const Color retroBackground = Color(0xFFFFFBEB);     // Warm cream
  static const Color retroSurface = Color(0xFFFEF3C7);        // Light amber
  static const Color retroOnSurface = Color(0xFF451A03);      // Dark brown

  // ========== OCEAN BLUE THEME BASE COLORS ==========

  static const Color oceanPrimary = Color(0xFF0EA5E9);        // Sky blue
  static const Color oceanSecondary = Color(0xFF2563EB);      // Blue
  static const Color oceanAccent = Color(0xFF4F46E5);         // Indigo

  // ========== FOREST GREEN THEME BASE COLORS ==========

  static const Color forestPrimary = Color(0xFF059669);       // Emerald
  static const Color forestSecondary = Color(0xFF0D9488);     // Teal
  static const Color forestAccent = Color(0xFF0891B2);        // Cyan

  // ========== SUNSET ORANGE THEME BASE COLORS ==========

  static const Color sunsetPrimary = Color(0xFFF97316);       // Orange
  static const Color sunsetSecondary = Color(0xFFF59E0B);     // Amber
  static const Color sunsetAccent = Color(0xFFEAB308);        // Yellow

  // ========== HIGH CONTRAST THEME BASE COLORS ==========

  static const Color highContrastPrimary = Colors.black;
  static const Color highContrastSecondary = Color(0xFF1F2937); // Dark gray
  static const Color highContrastAccent = Color(0xFF0EA5E9);   // Sky blue

  static const Color highContrastBackground = Colors.white;
  static const Color highContrastSurface = Color(0xFFF9FAFB); // Very light gray
  static const Color highContrastOnSurface = Colors.black;

  // ========== NEUTRAL GRAYS ==========
  // Universal grays for borders, dividers, etc.

  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // ========== OPACITY HELPERS ==========

  /// Creates a semi-transparent overlay
  static Color overlay({double opacity = 0.5}) =>
      Colors.black.withValues(alpha: opacity);

  /// Creates a white overlay
  static Color whiteOverlay({double opacity = 0.5}) =>
      Colors.white.withValues(alpha: opacity);
}
