import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'screens/qr_poc_screen.dart';
import 'screens/qr_detail_screen.dart';

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
    // Parse sss://qr/<id>
    final uri = Uri.parse(link);
    if (uri.scheme == 'sss' && uri.host == 'qr') {
      final qrId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      if (qrId.isNotEmpty) {
        // Navigate to QR detail screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => QRDetailScreen(qrId: qrId),
              ),
            );
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
      title: 'SSS - QR Code Generator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const QRPOCScreen(),
      onGenerateRoute: (settings) {
        // Handle deep link routes
        if (settings.name?.startsWith('sss://qr/') ?? false) {
          final uri = Uri.parse(settings.name!);
          final qrId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
          if (qrId.isNotEmpty) {
            return MaterialPageRoute(
              builder: (context) => QRDetailScreen(qrId: qrId),
            );
          }
        }
        return null;
      },
    );
  }
}
