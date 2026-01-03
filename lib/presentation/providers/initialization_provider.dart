import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/image_recognition_service.dart';
import '../../services/widget_service.dart';
import '../../services/siri_spotlight_service.dart';
import '../../services/google_assistant_service.dart';
import '../../services/preferences_service.dart';
import '../../services/permission_service.dart';
import 'data_providers.dart';
import 'dart:io';

/// Initialization Provider
final initializationProvider = FutureProvider<void>((ref) async {
  // Initialize data source (this initializes Hive and opens boxes)
  final dataSource = ref.read(localStorageDataSourceProvider);
  await dataSource.initialize();

  // Initialize PreferencesService (uses same Hive instance, syncs with data source)
  // This is needed for backward compatibility with code that still uses PreferencesService
  await PreferencesService.initialize();
  
  // Sync PreferencesService with data source settings
  final settingsFromDataSource = dataSource.getSettings();
  if (settingsFromDataSource != null) {
    // If data source has settings, ensure PreferencesService has them too
    if (!PreferencesService.isInitialized || PreferencesService.settings != settingsFromDataSource) {
      await PreferencesService.updateSettings(settingsFromDataSource);
    }
  } else if (PreferencesService.isInitialized) {
    // If PreferencesService has settings but data source doesn't, sync them
    final settingsFromPrefs = PreferencesService.settings;
    await dataSource.saveSettings(settingsFromPrefs);
  }

  // Note: Permissions are requested on-demand when features are used
  // This ensures the permission dialog appears at the right time
  // The app will appear in Settings after the first permission request

  // Initialize image recognition
  await ImageRecognitionService.initialize();

  // Initialize widget service
  await WidgetService.initialize();

  // Initialize platform-specific integrations
  if (Platform.isIOS) {
    await SiriSpotlightService.initialize();
  } else if (Platform.isAndroid) {
    await GoogleAssistantService.initialize();
  }
});
