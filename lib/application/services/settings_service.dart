import '../../models/app_settings.dart';
import '../../theme/app_theme_mode.dart';
import '../../data/repositories/settings_repository.dart';

/// Settings Service (Application Layer)
///
/// Orchestrates settings operations using repositories.
class SettingsApplicationService {
  final SettingsRepository _settingsRepository;

  SettingsApplicationService(this._settingsRepository);

  /// Get current settings
  Future<AppSettings> getSettings() async {
    return await _settingsRepository.getSettings();
  }

  /// Update settings
  Future<void> updateSettings(AppSettings settings) async {
    await _settingsRepository.updateSettings(settings);
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    await _settingsRepository.resetToDefaults();
  }

  /// Update theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    final current = await getSettings();
    await updateSettings(current.copyWith(themeMode: mode));
  }

  /// Update font scale
  Future<void> setFontScale(FontScaleOption scale) async {
    final current = await getSettings();
    await updateSettings(current.copyWith(fontScale: scale));
  }
}
