import 'package:flutter/material.dart';

/// Available theme modes for the app
///
/// Supports 8 distinct themes including light, dark, system auto,
/// retro, high contrast, and custom color themes.
enum AppThemeMode {
  light,
  dark,
  system,
  retro,
  highContrast,
  oceanBlue,
  forestGreen,
  sunsetOrange,
  modern,
}

/// Extension methods for AppThemeMode
extension AppThemeModeExtension on AppThemeMode {
  /// Display name for the theme (shown in UI)
  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System Auto';
      case AppThemeMode.retro:
        return 'Retro';
      case AppThemeMode.highContrast:
        return 'High Contrast';
      case AppThemeMode.oceanBlue:
        return 'Ocean Blue';
      case AppThemeMode.forestGreen:
        return 'Forest Green';
      case AppThemeMode.sunsetOrange:
        return 'Sunset Orange';
      case AppThemeMode.modern:
        return 'Modern';
    }
  }

  /// Description of the theme (shown in theme selector)
  String get description {
    switch (this) {
      case AppThemeMode.light:
        return 'Modern gradient-based light theme';
      case AppThemeMode.dark:
        return 'Vibrant purple/pink dark theme';
      case AppThemeMode.system:
        return 'Follows device settings';
      case AppThemeMode.retro:
        return 'Vintage-inspired warm tones';
      case AppThemeMode.highContrast:
        return 'Enhanced accessibility';
      case AppThemeMode.oceanBlue:
        return 'Cool ocean blues';
      case AppThemeMode.forestGreen:
        return 'Fresh forest greens';
      case AppThemeMode.sunsetOrange:
        return 'Warm sunset oranges';
      case AppThemeMode.modern:
        return 'Vibrant indigo/pink modern theme';
    }
  }

  /// Icon representing the theme
  IconData get icon {
    switch (this) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
      case AppThemeMode.retro:
        return Icons.camera_outlined;
      case AppThemeMode.highContrast:
        return Icons.contrast;
      case AppThemeMode.oceanBlue:
        return Icons.water;
      case AppThemeMode.forestGreen:
        return Icons.forest;
      case AppThemeMode.sunsetOrange:
        return Icons.wb_sunny;
      case AppThemeMode.modern:
        return Icons.rocket_launch;
    }
  }

  /// Convert to string for serialization
  String toJson() => name;

  /// Parse from string
  static AppThemeMode fromJson(String value) {
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppThemeMode.system,
    );
  }
}
