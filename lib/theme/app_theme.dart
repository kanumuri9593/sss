import 'package:flutter/material.dart';
import 'app_theme_extension.dart';
import 'app_theme_mode.dart';
import 'tokens/app_spacing.dart';
import 'tokens/app_radius.dart';
import 'tokens/app_shadows.dart';
import 'tokens/app_gradients.dart';
import 'tokens/app_typography.dart';
import 'tokens/app_colors.dart';

/// App Theme Configuration
///
/// Modern classic fusion design system with gradient-heavy aesthetics.
/// Supports 8 theme variants with complete design token integration.
class AppTheme {
  // ========== LEGACY COLORS (for backwards compatibility) ==========
  // Primary Colors - Deep Blue (Professional & Trustworthy)
  static const Color primaryBlue = Color(0xFF2563EB); // Main brand color
  static const Color primaryBlueDark = Color(0xFF1E40AF); // Darker variant
  static const Color primaryBlueLight = Color(0xFF3B82F6); // Lighter variant

  // Secondary Colors - Teal (Modern & Fresh)
  static const Color secondaryTeal = Color(0xFF14B8A6); // Secondary brand color
  static const Color secondaryTealDark = Color(0xFF0D9488); // Darker variant
  static const Color secondaryTealLight = Color(0xFF5EEAD4); // Lighter variant

  // Accent Colors - Amber/Gold (Highlights & Star)
  static const Color accentAmber = Color(0xFFF59E0B); // For highlights
  static const Color accentAmberLight = Color(0xFFFCD34D); // Lighter variant
  static const Color accentGold = Color(0xFFD97706); // For star icon

  // Neutral Colors
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  /// Icon Color Scheme (legacy)
  static const Map<String, Color> iconColors = {
    'houseGradientStart': primaryBlue,
    'houseGradientEnd': secondaryTeal,
    'starColor': accentAmber,
    'starColorAlt': accentGold,
  };

  // ========== THEME BUILDER ==========

  /// Build theme based on selected mode
  static ThemeData buildTheme({
    required AppThemeMode themeMode,
    Brightness? systemBrightness,
  }) {
    // Handle system auto theme
    if (themeMode == AppThemeMode.system) {
      final brightness = systemBrightness ?? Brightness.light;
      return brightness == Brightness.dark ? _buildDarkTheme() : _buildLightTheme();
    }

    // Build specific theme
    switch (themeMode) {
      case AppThemeMode.light:
        return _buildLightTheme();
      case AppThemeMode.dark:
        return _buildDarkTheme();
      case AppThemeMode.retro:
        return _buildRetroTheme();
      case AppThemeMode.highContrast:
        return _buildHighContrastTheme();
      case AppThemeMode.oceanBlue:
        return _buildOceanBlueTheme();
      case AppThemeMode.forestGreen:
        return _buildForestGreenTheme();
      case AppThemeMode.sunsetOrange:
        return _buildSunsetOrangeTheme();
      case AppThemeMode.sunsetOrange:
        return _buildSunsetOrangeTheme();
      case AppThemeMode.modern:
        return _buildModernTheme();
      default:
        return _buildModernTheme(); // Default to modern now
    }
  }

  // ========== LIGHT THEME ==========

  static ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.light(
      primary: AppColors.lightPrimary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD1FAE5),
      onPrimaryContainer: const Color(0xFF065F46),

      secondary: AppColors.lightSecondary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFCCFBF1),
      onSecondaryContainer: const Color(0xFF0F766E),

      tertiary: AppColors.lightAccent,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFFEF3C7),
      onTertiaryContainer: const Color(0xFF92400E),

      error: AppColors.error,
      onError: Colors.white,
      errorContainer: const Color(0xFFFFEBEE),
      onErrorContainer: const Color(0xFFB71C1C),

      surface: Colors.white,
      onSurface: const Color(0xFF1F2937),
      surfaceContainerHighest: AppColors.gray100,
      onSurfaceVariant: AppColors.gray600,

      outline: AppColors.gray300,
      outlineVariant: AppColors.gray200,

      shadow: Colors.black26,
      scrim: Colors.black54,
    );

    final themeExtension = AppThemeExtension(
      primaryGradient: AppGradients.lightPrimary,
      secondaryGradient: AppGradients.lightSecondary,
      accentGradient: AppGradients.lightAccent,
      backgroundGradient: AppGradients.backgroundGradient(
        AppColors.lightPrimary,
        0.5,
      ),
      surfaceGradient: AppGradients.cardOverlay([
        AppColors.lightPrimary,
        AppColors.lightSecondary,
      ]),
      cardShadow: AppShadows.gradientShadow(AppColors.lightPrimary),
      elevatedShadow: AppShadows.lg,
    );

    return _buildBaseTheme(colorScheme, themeExtension, AppColors.lightBackground);
  }

  // ========== DARK THEME ==========

  static ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.darkPrimary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF6D28D9),
      onPrimaryContainer: const Color(0xFFEDE9FE),

      secondary: AppColors.darkSecondary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFA21CAF),
      onSecondaryContainer: const Color(0xFFFAE8FF),

      tertiary: AppColors.darkAccent,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFBE185D),
      onTertiaryContainer: const Color(0xFFFCE7F3),

      error: const Color(0xFFF87171),
      onError: Colors.white,
      errorContainer: const Color(0xFF7F1D1D),
      onErrorContainer: const Color(0xFFFFEBEE),

      surface: const Color(0xFF1F2937),
      onSurface: AppColors.gray50,
      surfaceContainerHighest: AppColors.gray700,
      onSurfaceVariant: AppColors.gray300,

      outline: AppColors.gray600,
      outlineVariant: AppColors.gray700,

      shadow: Colors.black87,
    );

    final themeExtension = AppThemeExtension(
      primaryGradient: AppGradients.darkPrimary,
      secondaryGradient: AppGradients.darkSecondary,
      accentGradient: AppGradients.darkAccent,
      backgroundGradient: AppGradients.backgroundGradient(
        AppColors.darkPrimary,
        0.3,
      ),
      surfaceGradient: AppGradients.cardOverlay([
        AppColors.darkPrimary,
        AppColors.darkSecondary,
      ]),
      cardShadow: AppShadows.gradientShadow(AppColors.darkPrimary),
      elevatedShadow: AppShadows.xl,
    );

    return _buildBaseTheme(colorScheme, themeExtension, AppColors.darkBackground);
  }

  // ========== RETRO THEME ==========

  static ThemeData _buildRetroTheme() {
    final colorScheme = ColorScheme.light(
      primary: AppColors.retroPrimary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFFEE2E2),
      onPrimaryContainer: const Color(0xFF7F1D1D),

      secondary: AppColors.retroSecondary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFFEF3C7),
      onSecondaryContainer: const Color(0xFF78350F),

      tertiary: AppColors.retroAccent,
      onTertiary: const Color(0xFF78350F),
      tertiaryContainer: const Color(0xFFFEF9C3),
      onTertiaryContainer: const Color(0xFF713F12),

      error: AppColors.error,
      onError: Colors.white,

      surface: AppColors.retroBackground,
      onSurface: AppColors.retroOnSurface,
      surfaceContainerHighest: AppColors.retroSurface,
      onSurfaceVariant: const Color(0xFF78350F),

      outline: const Color(0xFFD97706),
      shadow: Colors.black26,
    );

    final themeExtension = AppThemeExtension(
      primaryGradient: AppGradients.retroPrimary,
      secondaryGradient: AppGradients.retroSecondary,
      accentGradient: AppGradients.retroAccent,
      backgroundGradient: AppGradients.backgroundGradient(
        AppColors.retroSecondary,
        0.4,
      ),
      surfaceGradient: AppGradients.cardOverlay([
        AppColors.retroPrimary,
        AppColors.retroSecondary,
      ]),
      cardShadow: AppShadows.gradientShadow(AppColors.retroSecondary),
      elevatedShadow: AppShadows.md,
    );

    return _buildBaseTheme(colorScheme, themeExtension, AppColors.retroBackground);
  }

  // ========== HIGH CONTRAST THEME ==========

  static ThemeData _buildHighContrastTheme() {
    final colorScheme = ColorScheme.light(
      primary: AppColors.highContrastPrimary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.gray200,
      onPrimaryContainer: Colors.black,

      secondary: AppColors.gray800,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.gray100,
      onSecondaryContainer: Colors.black,

      tertiary: AppColors.highContrastAccent,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFE0F2FE),
      onTertiaryContainer: Colors.black,

      error: AppColors.error,
      onError: Colors.white,

      surface: AppColors.highContrastBackground,
      onSurface: AppColors.highContrastOnSurface,
      surfaceContainerHighest: AppColors.highContrastSurface,
      onSurfaceVariant: AppColors.gray700,

      outline: Colors.black,
      shadow: Colors.black38,
    );

    final themeExtension = AppThemeExtension(
      primaryGradient: AppGradients.highContrastPrimary,
      secondaryGradient: AppGradients.highContrastSecondary,
      accentGradient: AppGradients.highContrastAccent,
      backgroundGradient: const LinearGradient(colors: [Colors.white, Colors.white]),
      surfaceGradient: const LinearGradient(colors: [Colors.white, Colors.white]),
      cardShadow: AppShadows.lg,
      elevatedShadow: AppShadows.xl,
    );

    return _buildBaseTheme(colorScheme, themeExtension, AppColors.highContrastBackground);
  }

  // ========== OCEAN BLUE THEME ==========

  static ThemeData _buildOceanBlueTheme() {
    final colorScheme = ColorScheme.light(
      primary: AppColors.oceanPrimary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE0F2FE),
      onPrimaryContainer: const Color(0xFF075985),

      secondary: AppColors.oceanSecondary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFDBEAFE),
      onSecondaryContainer: const Color(0xFF1E3A8A),

      tertiary: AppColors.oceanAccent,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFE0E7FF),
      onTertiaryContainer: const Color(0xFF312E81),

      error: AppColors.error,
      onError: Colors.white,

      surface: Colors.white,
      onSurface: const Color(0xFF0C4A6E),
      surfaceContainerHighest: const Color(0xFFF0F9FF),
      onSurfaceVariant: const Color(0xFF075985),

      outline: const Color(0xFFBAE6FD),
      shadow: Colors.black26,
    );

    final themeExtension = AppThemeExtension(
      primaryGradient: AppGradients.oceanPrimary,
      secondaryGradient: AppGradients.oceanSecondary,
      accentGradient: AppGradients.oceanAccent,
      backgroundGradient: AppGradients.backgroundGradient(
        AppColors.oceanPrimary,
        0.4,
      ),
      surfaceGradient: AppGradients.cardOverlay([
        AppColors.oceanPrimary,
        AppColors.oceanSecondary,
      ]),
      cardShadow: AppShadows.gradientShadow(AppColors.oceanPrimary),
      elevatedShadow: AppShadows.lg,
    );

    return _buildBaseTheme(colorScheme, themeExtension, const Color(0xFFF0F9FF));
  }

  // ========== FOREST GREEN THEME ==========

  static ThemeData _buildForestGreenTheme() {
    final colorScheme = ColorScheme.light(
      primary: AppColors.forestPrimary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD1FAE5),
      onPrimaryContainer: const Color(0xFF064E3B),

      secondary: AppColors.forestSecondary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFCCFBF1),
      onSecondaryContainer: const Color(0xFF134E4A),

      tertiary: AppColors.forestAccent,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFCFFAFE),
      onTertiaryContainer: const Color(0xFF164E63),

      error: AppColors.error,
      onError: Colors.white,

      surface: Colors.white,
      onSurface: const Color(0xFF064E3B),
      surfaceContainerHighest: const Color(0xFFECFDF5),
      onSurfaceVariant: const Color(0xFF047857),

      outline: const Color(0xFFA7F3D0),
      shadow: Colors.black26,
    );

    final themeExtension = AppThemeExtension(
      primaryGradient: AppGradients.forestPrimary,
      secondaryGradient: AppGradients.forestSecondary,
      accentGradient: AppGradients.forestAccent,
      backgroundGradient: AppGradients.backgroundGradient(
        AppColors.forestPrimary,
        0.4,
      ),
      surfaceGradient: AppGradients.cardOverlay([
        AppColors.forestPrimary,
        AppColors.forestSecondary,
      ]),
      cardShadow: AppShadows.gradientShadow(AppColors.forestPrimary),
      elevatedShadow: AppShadows.lg,
    );

    return _buildBaseTheme(colorScheme, themeExtension, const Color(0xFFECFDF5));
  }

  // ========== SUNSET ORANGE THEME ==========

  static ThemeData _buildSunsetOrangeTheme() {
    final colorScheme = ColorScheme.light(
      primary: AppColors.sunsetPrimary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFFFEDD5),
      onPrimaryContainer: const Color(0xFF7C2D12),

      secondary: AppColors.sunsetSecondary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFFEF3C7),
      onSecondaryContainer: const Color(0xFF78350F),

      tertiary: AppColors.sunsetAccent,
      onTertiary: const Color(0xFF713F12),
      tertiaryContainer: const Color(0xFFFEF9C3),
      onTertiaryContainer: const Color(0xFF713F12),

      error: AppColors.error,
      onError: Colors.white,

      surface: Colors.white,
      onSurface: const Color(0xFF7C2D12),
      surfaceContainerHighest: const Color(0xFFFFF7ED),
      onSurfaceVariant: const Color(0xFFC2410C),

      outline: const Color(0xFFFED7AA),
      shadow: Colors.black26,
    );

    final themeExtension = AppThemeExtension(
      primaryGradient: AppGradients.sunsetPrimary,
      secondaryGradient: AppGradients.sunsetSecondary,
      accentGradient: AppGradients.sunsetAccent,
      backgroundGradient: AppGradients.backgroundGradient(
        AppColors.sunsetPrimary,
        0.4,
      ),
      surfaceGradient: AppGradients.cardOverlay([
        AppColors.sunsetPrimary,
        AppColors.sunsetSecondary,
      ]),
      cardShadow: AppShadows.gradientShadow(AppColors.sunsetPrimary),
      elevatedShadow: AppShadows.lg,
    );

    return _buildBaseTheme(colorScheme, themeExtension, const Color(0xFFFFF7ED));
  }

  // ========== MODERN THEME (NEW) ==========

  static ThemeData _buildModernTheme() {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.modernPrimary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF4338CA), // Indigo 700
      onPrimaryContainer: const Color(0xFFE0E7FF), // Indigo 100

      secondary: AppColors.modernSecondary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFBE185D), // Pink 700
      onSecondaryContainer: const Color(0xFFFCE7F3), // Pink 100

      tertiary: AppColors.modernAccent,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFF7C3AED), // Violet 600
      onTertiaryContainer: const Color(0xFFEDE9FE), // Violet 100

      error: AppColors.error,
      onError: Colors.white,

      surface: AppColors.modernSurface,
      onSurface: AppColors.modernOnSurface,
      surfaceContainerHighest: const Color(0xFF334155), // Slate 700
      onSurfaceVariant: const Color(0xFF94A3B8), // Slate 400

      outline: const Color(0xFF475569), // Slate 600
      shadow: Colors.black.withValues(alpha: 0.5),
    );

    final themeExtension = AppThemeExtension(
      primaryGradient: AppGradients.modernPrimary,
      secondaryGradient: AppGradients.modernSecondary,
      accentGradient: AppGradients.modernAccent,
      backgroundGradient: AppGradients.backgroundGradient(
        AppColors.modernPrimary,
        0.15,
      ),
      surfaceGradient: AppGradients.glassMorphism,
      cardShadow: AppShadows.xl,
      elevatedShadow: AppShadows.xl,
    );

    return _buildBaseTheme(colorScheme, themeExtension, AppColors.modernBackground);
  }

  // ========== BASE THEME BUILDER ==========

  static ThemeData _buildBaseTheme(
    ColorScheme colorScheme,
    AppThemeExtension themeExtension,
    Color scaffoldBackground,
  ) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: [themeExtension],
      scaffoldBackgroundColor: scaffoldBackground,

      // Typography
      textTheme: AppTypography.createTextTheme(colorScheme),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.surfaceTint,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: AppTypography.semiBold,
          letterSpacing: AppTypography.wideSpacing,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 24,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
        ),
        color: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          padding: AppSpacing.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadius,
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: AppTypography.semiBold,
            letterSpacing: AppTypography.wideSpacing,
          ),
        ),
      ),

      // Filled Button Theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: AppSpacing.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadius,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: AppSpacing.buttonPadding,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadius,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: AppSpacing.inputPadding,
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: AppTypography.semiBold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: AppTypography.medium,
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(color: colorScheme.onSurface),
        secondaryLabelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.chipRadius,
        ),
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundedLG,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: AppTypography.semiBold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: AppTypography.medium,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  // ========== LEGACY GETTERS (for backwards compatibility) ==========

  /// Light Theme (legacy getter)
  static ThemeData get lightTheme => _buildLightTheme();

  /// Dark Theme (legacy getter)
  static ThemeData get darkTheme => _buildDarkTheme();
}
