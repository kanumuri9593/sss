import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_settings.dart';
import '../models/app_settings_adapter.dart';

/// Preferences Service for App Settings
///
/// Manages user preferences and settings using Hive for persistence.
class PreferencesService {
  static const String _settingsBoxName = 'app_settings';
  static const String _settingsKey = 'settings';

  static Box<AppSettings>? _settingsBox;
  static AppSettings? _cachedSettings;

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
    debugPrint('[Preferences] Preferences service closed');
  }
}
