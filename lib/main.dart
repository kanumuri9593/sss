import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_mode.dart';
import 'models/app_settings.dart';
import 'presentation/controllers/settings_controller.dart';
import 'presentation/states/settings_state.dart';
import 'services/widget_service.dart';
import 'services/siri_spotlight_service.dart';
import 'services/google_assistant_service.dart';
import 'navigation/app_router.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Global error handler for Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('[App] Flutter error: ${details.exception}');
    };

    // Global error handler for async errors not caught by Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('[App] Uncaught error: $error');
      debugPrint('[App] Stack: $stack');
      return true;
    };

    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('[App] Zone error: $error');
    debugPrint('[App] Zone stack: $stack');
  });
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initWidgetClickHandler();
    _checkInitialWidgetLaunch();
  }

  /// Initialize widget click handler for home screen widget interactions
  void _initWidgetClickHandler() {
    WidgetService.registerClickHandler((uri) {
      if (uri != null) {
        DeepLinkHandler.handleDeepLink(ref, uri.toString());
      }
    });
  }

  /// Check if app was launched from a home screen widget
  Future<void> _checkInitialWidgetLaunch() async {
    final uri = await WidgetService.getInitialUri();
    if (uri != null) {
      // Small delay to ensure app is fully initialized
      await Future.delayed(const Duration(milliseconds: 500));
      DeepLinkHandler.handleDeepLink(ref, uri.toString());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Update widgets when app goes to background or resumes
    if (state == AppLifecycleState.paused || state == AppLifecycleState.resumed) {
      _updateNativeIntegrations();
    }
  }

  /// Update all native integrations (widgets, Spotlight, shortcuts)
  Future<void> _updateNativeIntegrations() async {
    try {
      // Update home screen widgets
      await WidgetService.updateAllWidgets();

      // Update platform-specific integrations
      if (Platform.isIOS) {
        await SiriSpotlightService.indexAllContent();
      } else if (Platform.isAndroid) {
        await GoogleAssistantService.updateAppActions();
      }

      debugPrint('[main] Native integrations updated');
    } catch (e) {
      debugPrint('[main] Error updating native integrations: $e');
    }
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch router
    final router = ref.watch(routerProvider);
    
    // Watch settings controller for reactive theme updates
    final settingsState = ref.watch(settingsControllerProvider);
    final settings = settingsState is SettingsLoaded 
        ? settingsState.settings 
        : AppSettings.defaultSettings();
    final themeMode = settings.themeMode;
    final fontScale = settings.fontScale.scale;
    final useDynamicType = settings.useDynamicType;

    // Build the appropriate theme
    final brightness = MediaQuery.platformBrightnessOf(context);
    final theme = AppTheme.buildTheme(
      themeMode: themeMode,
      systemBrightness: brightness,
    );

    // Apply font scaling if not using dynamic type
    final textScaler = useDynamicType
        ? MediaQuery.textScalerOf(context)
        : TextScaler.linear(fontScale);

    // Determine which theme to use based on the selected theme mode
    final flutterThemeMode = _getThemeMode(themeMode);
    final isCustomLightTheme = themeMode == AppThemeMode.retro ||
                               themeMode == AppThemeMode.highContrast ||
                               themeMode == AppThemeMode.oceanBlue ||
                               themeMode == AppThemeMode.forestGreen ||
                               themeMode == AppThemeMode.sunsetOrange;
    final isCustomDarkTheme = themeMode == AppThemeMode.modern;
    
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: MaterialApp.router(
        title: 'SSS - Search & Scan',
        theme: isCustomLightTheme
            ? theme // Use custom light theme
            : AppTheme.buildTheme(
                themeMode: AppThemeMode.light,
                systemBrightness: Brightness.light,
              ),
        darkTheme: isCustomDarkTheme
            ? theme // Use custom dark theme (modern)
            : AppTheme.buildTheme(
                themeMode: AppThemeMode.dark,
                systemBrightness: Brightness.dark,
              ),
        themeMode: flutterThemeMode,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  /// Convert AppThemeMode to Flutter's ThemeMode
  ThemeMode _getThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
      case AppThemeMode.retro:
      case AppThemeMode.highContrast:
      case AppThemeMode.oceanBlue:
      case AppThemeMode.forestGreen:
      case AppThemeMode.sunsetOrange:
        return ThemeMode.light;
      case AppThemeMode.dark:
      case AppThemeMode.modern: // Modern theme uses dark colors
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
