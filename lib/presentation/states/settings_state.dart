import '../../models/app_settings.dart';

/// Settings State
///
/// Represents the state of settings in the UI.
sealed class SettingsState {}

/// Initial state
class SettingsInitial extends SettingsState {}

/// Loading state
class SettingsLoading extends SettingsState {}

/// Loaded state with settings
class SettingsLoaded extends SettingsState {
  final AppSettings settings;

  SettingsLoaded(this.settings);
}

/// Error state
class SettingsError extends SettingsState {
  final String message;

  SettingsError(this.message);
}
