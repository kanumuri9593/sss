import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_settings.dart';
import '../../theme/app_theme_mode.dart';
import '../../application/services/settings_service.dart';
import '../states/settings_state.dart';
import '../providers/service_providers.dart';

/// Settings Controller (Notifier)
///
/// Manages settings state and operations in the presentation layer.
class SettingsController extends StateNotifier<SettingsState> {
  final SettingsApplicationService _service;

  SettingsController(this._service) : super(SettingsInitial()) {
    loadSettings();
  }

  /// Load settings
  Future<void> loadSettings() async {
    state = SettingsLoading();
    try {
      final settings = await _service.getSettings();
      state = SettingsLoaded(settings);
    } catch (e) {
      state = SettingsError(e.toString());
    }
  }

  /// Update settings
  Future<bool> updateSettings(AppSettings settings) async {
    try {
      await _service.updateSettings(settings);
      state = SettingsLoaded(settings);
      return true;
    } catch (e) {
      state = SettingsError(e.toString());
      return false;
    }
  }

  /// Update theme mode
  Future<bool> updateThemeMode(AppThemeMode mode) async {
    try {
      await _service.setThemeMode(mode);
      await loadSettings();
      return true;
    } catch (e) {
      state = SettingsError(e.toString());
      return false;
    }
  }

  /// Update font scale
  Future<bool> updateFontScale(FontScaleOption scale) async {
    try {
      await _service.setFontScale(scale);
      await loadSettings();
      return true;
    } catch (e) {
      state = SettingsError(e.toString());
      return false;
    }
  }

  /// Reset to default settings
  Future<bool> resetToDefaults() async {
    try {
      await _service.resetToDefaults();
      await loadSettings();
      return true;
    } catch (e) {
      state = SettingsError(e.toString());
      return false;
    }
  }
}

/// Settings Controller Provider
final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsController(service);
});

/// Settings Provider (Async)
final settingsProvider = FutureProvider<AppSettings>((ref) async {
  final service = ref.watch(settingsServiceProvider);
  return await service.getSettings();
});
