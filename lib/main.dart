import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:uni_links/uni_links.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_mode.dart';
import 'models/app_settings.dart';
import 'screens/container_list_screen.dart';
import 'screens/qr_detail_screen.dart';
import 'screens/nfc_detail_screen.dart';
import 'screens/container_detail_screen.dart';
import 'screens/search_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'services/qr_service.dart';
import 'services/nfc_service.dart';
import 'services/storage_service.dart';
import 'services/container_service.dart';
import 'services/image_recognition_service.dart';
import 'services/preferences_service.dart';
import 'services/widget_service.dart';
import 'services/siri_spotlight_service.dart';
import 'services/google_assistant_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage
  try {
    await StorageService.initialize();
    debugPrint('[main] Storage initialized');
  } catch (e) {
    debugPrint('[main] Error initializing storage: $e');
  }

  // Initialize image recognition
  await ImageRecognitionService.initialize();

  // Initialize widget service for home screen widgets
  await WidgetService.initialize();

  // Initialize platform-specific integrations
  if (Platform.isIOS) {
    // Initialize Siri and Spotlight for iOS
    await SiriSpotlightService.initialize();
  } else if (Platform.isAndroid) {
    // Initialize Google Assistant integration for Android
    await GoogleAssistantService.initialize();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // StreamSubscription? _linkSubscription;
  AppSettings? _settings;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // _initDeepLinks();
    _initSettings();
    _initWidgetClickHandler();
    _checkInitialWidgetLaunch();
  }

  void _initSettings() {
    // Get initial settings
    if (PreferencesService.isInitialized) {
      _settings = PreferencesService.settings;
    }

    // Listen for settings changes
    PreferencesService.settingsNotifier.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {
        _settings = PreferencesService.settingsNotifier.value;
      });
    }
  }

  /// Initialize widget click handler for home screen widget interactions
  void _initWidgetClickHandler() {
    WidgetService.registerClickHandler((uri) {
      if (uri != null) {
        _handleDeepLink(uri.toString());
      }
    });
  }

  /// Check if app was launched from a home screen widget
  Future<void> _checkInitialWidgetLaunch() async {
    final uri = await WidgetService.getInitialUri();
    if (uri != null) {
      // Small delay to ensure app is fully initialized
      await Future.delayed(const Duration(milliseconds: 500));
      _handleDeepLink(uri.toString());
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

  /*
  void _initDeepLinks() {
    // Handle initial link (app opened via deep link)
    getInitialLink().then((String? initialLink) {
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    });

    // Listen for deep links while app is running
    _linkSubscription = linkStream.listen(
      (String? link) {
        if (link != null) {
          _handleDeepLink(link);
        }
      },
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );
  }
  */

  void _handleDeepLink(String link) {
    debugPrint('Received deep link: $link');
    final uri = Uri.parse(link);

    if (uri.scheme == 'sss') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final navigator = _navigatorKey.currentState ?? Navigator.of(context);
          
          if (uri.host == 'container') {
            // Handle container deep link: sss://container/<id>
            final containerId = uri.pathSegments.isNotEmpty
                ? uri.pathSegments.first
                : '';
            if (containerId.isNotEmpty) {
              final container = ContainerService.getContainer(containerId);
              if (container != null) {
                // Donate to Siri for predictions
                if (Platform.isIOS) {
                  SiriSpotlightService.donateContainerView(container);
                }
                navigator.push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ContainerDetailScreen(containerId: containerId),
                  ),
                );
                return;
              }
            }
          } else if (uri.host == 'qr') {
            // Handle QR/NFC deep link: sss://qr/<id>
            final id = uri.pathSegments.isNotEmpty
                ? uri.pathSegments.first
                : '';
            if (id.isNotEmpty) {
              // Check if it's linked to a container
              final container = ContainerService.getContainerByQRCode(id);
              if (container != null) {
                navigator.push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ContainerDetailScreen(containerId: container.id),
                  ),
                );
                return;
              }

              // Check if it's a QR code or NFC tag
              final qrData = QRService.getQRDataById(id);
              if (qrData != null) {
                navigator.push(
                  MaterialPageRoute(
                    builder: (context) => QRDetailScreen(qrId: id),
                  ),
                );
                return;
              }

              // Try NFC
              final nfcData = NFCService.getNFCTagDataById(id);
              if (nfcData != null) {
                // Check if NFC is linked to a container
                final nfcContainer = ContainerService.getContainerByNFCTag(id);
                if (nfcContainer != null) {
                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ContainerDetailScreen(containerId: nfcContainer.id),
                    ),
                  );
                  return;
                }

                navigator.push(
                  MaterialPageRoute(
                    builder: (context) => NFCDetailScreen(nfcId: id),
                  ),
                );
                return;
              }
            }
          } else if (uri.host == 'search') {
            // Handle search deep link: sss://search or sss://search?q=<query>
            final query = uri.queryParameters['q'] ?? uri.queryParameters['query'];
            navigator.push(
              MaterialPageRoute(
                builder: (context) => SearchScreen(initialQuery: query),
              ),
            );
            return;
          } else if (uri.host == 'scan') {
            // Handle scan deep links: sss://scan/qr or sss://scan/nfc
            navigator.push(
              MaterialPageRoute(
                builder: (context) => const QRScannerScreen(),
              ),
            );
            return;
          } else if (uri.host == 'containers' || uri.host == 'stats') {
            // Just show the main screen
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const ContainerListScreen(),
              ),
              (route) => false,
            );
            return;
          }

          // Not found, show error
          navigator.push(
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Not Found')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text('Item not found'),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // _linkSubscription?.cancel();
    PreferencesService.settingsNotifier.removeListener(_onSettingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get current theme settings
    final themeMode = _settings?.themeMode ?? AppThemeMode.modern;
    final fontScale = _settings?.fontScale.scale ?? 1.0;
    final useDynamicType = _settings?.useDynamicType ?? true;

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

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'SSS - Search & Scan',
        theme: theme,
        darkTheme: AppTheme.buildTheme(
          themeMode: AppThemeMode.dark,
          systemBrightness: Brightness.dark,
        ),
        themeMode: _getThemeMode(themeMode),
        home: const ContainerListScreen(),
        onGenerateRoute: (settings) {
          // Handle deep link routes
          if (settings.name?.startsWith('sss://') ?? false) {
            final uri = Uri.parse(settings.name!);

            if (uri.host == 'container') {
              final containerId = uri.pathSegments.isNotEmpty
                  ? uri.pathSegments.first
                  : '';
              if (containerId.isNotEmpty) {
                return MaterialPageRoute(
                  builder: (context) =>
                      ContainerDetailScreen(containerId: containerId),
                );
              }
            } else if (uri.host == 'qr') {
              final id = uri.pathSegments.isNotEmpty
                  ? uri.pathSegments.first
                  : '';
              if (id.isNotEmpty) {
                // Check if linked to container
                final container = ContainerService.getContainerByQRCode(id);
                if (container != null) {
                  return MaterialPageRoute(
                    builder: (context) =>
                        ContainerDetailScreen(containerId: container.id),
                  );
                }

                // Try QR first, then NFC
                final qrData = QRService.getQRDataById(id);
                if (qrData != null) {
                  return MaterialPageRoute(
                    builder: (context) => QRDetailScreen(qrId: id),
                  );
                } else {
                  final nfcData = NFCService.getNFCTagDataById(id);
                  if (nfcData != null) {
                    final nfcContainer = ContainerService.getContainerByNFCTag(
                      id,
                    );
                    if (nfcContainer != null) {
                      return MaterialPageRoute(
                        builder: (context) =>
                            ContainerDetailScreen(containerId: nfcContainer.id),
                      );
                    }
                    return MaterialPageRoute(
                      builder: (context) => NFCDetailScreen(nfcId: id),
                    );
                  }
                }
              }
            } else if (uri.host == 'search') {
              return MaterialPageRoute(
                builder: (context) => SearchScreen(
                  initialQuery: uri.queryParameters['q'],
                ),
              );
            } else if (uri.host == 'scan') {
              return MaterialPageRoute(
                builder: (context) => const QRScannerScreen(),
              );
            }
          }
          return null;
        },
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
      case AppThemeMode.modern:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
