import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_settings.dart';
import '../models/app_settings_adapter.dart';
import '../theme/app_theme_mode.dart';

/// Preferences Service for App Settings
///
/// Manages user preferences and settings using Hive for persistence.
/// Provides reactive updates via ValueNotifier for theme and settings changes.
class PreferencesService {
  static const String _settingsBoxName = 'app_settings';
  static const String _settingsKey = 'settings';

  static Box<AppSettings>? _settingsBox;
  static AppSettings? _cachedSettings;

  /// ValueNotifier for reactive settings updates
  /// Listen to this for theme/font changes that require app-wide rebuild
  static final ValueNotifier<AppSettings?> settingsNotifier = ValueNotifier(
    null,
  );

  /// Initialize preferences storage
  ///
  /// Must be called before using any preferences operations.
  static Future<void> initialize() async {
    try {
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(AppSettingsAdapter());
      }

      _settingsBox = await Hive.openBox<AppSettings>(_settingsBoxName);

      // Load or create default settings
      _cachedSettings = _settingsBox!.get(_settingsKey);
      if (_cachedSettings == null) {
        _cachedSettings = AppSettings.defaultSettings();
        await _settingsBox!.put(_settingsKey, _cachedSettings!);
      }

      // Update notifier
      settingsNotifier.value = _cachedSettings;

      debugPrint('[Preferences] Settings initialized');
    } catch (e) {
      debugPrint('[Preferences] Error initializing: $e');
      rethrow;
    }
  }

  /// Get current settings
  static AppSettings get settings {
    if (_cachedSettings == null) {
      throw StateError('PreferencesService not initialized');
    }
    return _cachedSettings!;
  }

  /// Update settings
  static Future<void> updateSettings(AppSettings newSettings) async {
    await _settingsBox!.put(_settingsKey, newSettings);
    _cachedSettings = newSettings;
    settingsNotifier.value = newSettings;
    debugPrint('[Preferences] Settings updated');
  }

  /// Check if preferences are initialized
  static bool get isInitialized => _cachedSettings != null;

  /// Reset to default settings
  static Future<void> resetToDefaults() async {
    final defaultSettings = AppSettings.defaultSettings();
    await updateSettings(defaultSettings);
    debugPrint('[Preferences] Reset to default settings');
  }

  /// Close the settings box
  static Future<void> close() async {
    await _settingsBox?.close();
    _settingsBox = null;
    _cachedSettings = null;
    settingsNotifier.value = null;
    debugPrint('[Preferences] Preferences service closed');
  }

  // ========== Theme Helpers ==========

  /// Get current theme mode
  static AppThemeMode get themeMode => settings.themeMode;

  /// Update theme mode
  static Future<void> setThemeMode(AppThemeMode mode) async {
    await updateSettings(settings.copyWith(themeMode: mode));
  }

  /// Get current font scale
  static double get fontScale => settings.fontScale.scale;

  /// Update font scale
  static Future<void> setFontScale(FontScaleOption scale) async {
    await updateSettings(settings.copyWith(fontScale: scale));
  }

  // ========== Storage Helpers ==========

  /// Get the Hive storage path
  static Future<String> getStoragePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Get image cache directory path
  static Future<String> getImageCachePath() async {
    final cacheDir = await getTemporaryDirectory();
    return '${cacheDir.path}/image_cache';
  }

  /// Get current image cache size in bytes
  static Future<int> getImageCacheSizeBytes() async {
    try {
      final cachePath = await getImageCachePath();
      final cacheDir = Directory(cachePath);

      if (!await cacheDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      debugPrint('[Preferences] Error getting cache size: $e');
      return 0;
    }
  }

  /// Format bytes to human readable string
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Clear image cache
  static Future<void> clearImageCache() async {
    try {
      final cachePath = await getImageCachePath();
      final cacheDir = Directory(cachePath);

      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
        debugPrint('[Preferences] Image cache cleared');
      }
    } catch (e) {
      debugPrint('[Preferences] Error clearing image cache: $e');
    }
  }

  /// Get default export path
  static Future<String> getDefaultExportPath() async {
    if (settings.defaultExportPath != null) {
      return settings.defaultExportPath!;
    }

    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/exports';
  }

  /// Set default export path
  static Future<void> setDefaultExportPath(String path) async {
    await updateSettings(settings.copyWith(defaultExportPath: path));
  }

  /// Get max image cache size in bytes
  static int get maxImageCacheBytes =>
      settings.imageCacheSize.sizeInMB * 1024 * 1024;

  /// Update image cache size setting
  static Future<void> setImageCacheSize(ImageCacheSize size) async {
    await updateSettings(settings.copyWith(imageCacheSize: size));
  }
}
