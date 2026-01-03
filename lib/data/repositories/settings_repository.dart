import '../../models/app_settings.dart';
import '../datasources/local_storage_data_source.dart';

/// Settings Repository
///
/// Provides a clean API for app settings operations.
abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> updateSettings(AppSettings settings);
  Future<void> resetToDefaults();
}

/// Implementation of SettingsRepository using Hive
class SettingsRepositoryImpl implements SettingsRepository {
  final LocalStorageDataSource _dataSource;
  AppSettings? _cachedSettings;

  SettingsRepositoryImpl(this._dataSource);

  @override
  Future<AppSettings> getSettings() async {
    if (_cachedSettings != null) {
      return _cachedSettings!;
    }

    final settings = _dataSource.getSettings();
    if (settings != null) {
      _cachedSettings = settings;
      return settings;
    }

    // Return default settings if none exist
    final defaultSettings = AppSettings.defaultSettings();
    await updateSettings(defaultSettings);
    return defaultSettings;
  }

  @override
  Future<void> updateSettings(AppSettings settings) async {
    _cachedSettings = settings;
    await _dataSource.saveSettings(settings);
  }

  @override
  Future<void> resetToDefaults() async {
    final defaultSettings = AppSettings.defaultSettings();
    await updateSettings(defaultSettings);
  }
}
