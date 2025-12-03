import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'screens/main_tab_screen.dart';
import 'screens/qr_detail_screen.dart';
import 'screens/nfc_detail_screen.dart';
import 'services/qr_service.dart';
import 'services/nfc_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

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

  void _handleDeepLink(String link) {
    debugPrint('Received deep link: $link');
    // Parse sss://qr/<id> (works for both QR and NFC)
    final uri = Uri.parse(link);
    if (uri.scheme == 'sss' && uri.host == 'qr') {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      if (id.isNotEmpty) {
        // Check if it's a QR code or NFC tag
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Try QR first, then NFC
            final qrData = QRService.getQRDataById(id);
            if (qrData != null) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => QRDetailScreen(qrId: id),
                ),
              );
            } else {
              // Try NFC
              final nfcData = NFCService.getNFCTagDataById(id);
              if (nfcData != null) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => NFCDetailScreen(nfcId: id),
                  ),
                );
              } else {
                // Not found in either registry, show error
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        title: const Text('Not Found'),
                      ),
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
            }
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SSS - QR & NFC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainTabScreen(),
      onGenerateRoute: (settings) {
        // Handle deep link routes (works for both QR and NFC)
        if (settings.name?.startsWith('sss://qr/') ?? false) {
          final uri = Uri.parse(settings.name!);
          final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
          if (id.isNotEmpty) {
            // Try QR first, then NFC
            final qrData = QRService.getQRDataById(id);
            if (qrData != null) {
              return MaterialPageRoute(
                builder: (context) => QRDetailScreen(qrId: id),
              );
            } else {
              final nfcData = NFCService.getNFCTagDataById(id);
              if (nfcData != null) {
                return MaterialPageRoute(
                  builder: (context) => NFCDetailScreen(nfcId: id),
                );
              }
            }
          }
        }
        return null;
      },
    );
  }
}
