import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../screens/container_list_screen.dart';
import '../screens/container_detail_screen.dart';
import '../screens/container_create_screen.dart';
import '../screens/item_create_screen.dart';
import '../screens/search_screen.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/qr_detail_screen.dart';
import '../screens/nfc_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/faq_screen.dart';
import '../screens/faq_topic_screen.dart';
import '../services/qr_service.dart';
import '../services/nfc_service.dart';
import '../services/siri_spotlight_service.dart';
import '../presentation/providers/service_providers.dart';
import '../presentation/providers/initialization_provider.dart';

/// App Router Configuration
///
/// Handles all navigation routes, deep linking, and error handling
final routerProvider = Provider<GoRouter>((ref) {
  // Access container service for route builders
  final containerService = ref.read(containerServiceProvider);
  final initialization = ref.watch(initializationProvider);
  
  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/',
    redirect: (context, state) {
      // Wait for initialization before allowing navigation
      if (initialization.isLoading) {
        return '/loading';
      }
      
      if (initialization.hasError) {
        return '/error';
      }
      
      return null;
    },
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
    routes: [
      // Loading screen
      GoRoute(
        path: '/loading',
        builder: (context, state) => const LoadingScreen(),
      ),
      
      // Error screen
      GoRoute(
        path: '/error',
        builder: (context, state) {
          final error = state.extra;
          return ErrorScreen(error: error);
        },
      ),
      
      // Home/Container List
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const ContainerListScreen(),
      ),
      
      // Container routes
      GoRoute(
        path: '/containers',
        name: 'containers',
        builder: (context, state) => const ContainerListScreen(),
      ),
      
      GoRoute(
        path: '/containers/create',
        name: 'container-create',
        builder: (context, state) {
          final containerId = state.uri.queryParameters['edit'];
          if (containerId != null) {
            // Load container for editing
            final container = containerService.getContainer(containerId);
            return ContainerCreateScreen(container: container);
          }
          return const ContainerCreateScreen(container: null);
        },
      ),
      
      GoRoute(
        path: '/containers/:id',
        name: 'container-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ContainerDetailScreen(containerId: id);
        },
      ),
      
      // Item routes
      GoRoute(
        path: '/containers/:containerId/items/create',
        name: 'item-create',
        builder: (context, state) {
          final containerId = state.pathParameters['containerId']!;
          return ItemCreateScreen(
            containerId: containerId,
            item: null,
          );
        },
      ),
      
      // Search
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'] ?? 
                       state.uri.queryParameters['query'];
          return SearchScreen(initialQuery: query);
        },
      ),
      
      // QR Scanner
      GoRoute(
        path: '/scan',
        name: 'scan',
        builder: (context, state) => const QRScannerScreen(),
      ),
      
      // QR Detail
      GoRoute(
        path: '/qr/:id',
        name: 'qr-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return QRDetailScreen(qrId: id);
        },
      ),
      
      // NFC Detail
      GoRoute(
        path: '/nfc/:id',
        name: 'nfc-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return NFCDetailScreen(nfcId: id);
        },
      ),
      
      // Profile/Settings
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // FAQ
      GoRoute(
        path: '/faq',
        name: 'faq',
        builder: (context, state) => const FAQScreen(),
      ),

      GoRoute(
        path: '/faq/:topic',
        name: 'faq-topic',
        builder: (context, state) {
          final topic = state.pathParameters['topic']!;
          return FAQTopicScreen(topicId: topic);
        },
      ),
    ],
  );
});

/// Loading Screen
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Initializing...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// Error Screen
class ErrorScreen extends StatelessWidget {
  final Object? error;
  
  const ErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (error != null)
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Deep Link Handler
class DeepLinkHandler {
  static void handleDeepLink(WidgetRef ref, String link) {
    debugPrint('[DeepLink] Handling: $link');
    final router = ref.read(routerProvider);
    final uri = Uri.parse(link);

    if (uri.scheme == 'sss') {
      try {
        if (uri.host == 'container') {
          final containerId = uri.pathSegments.isNotEmpty
              ? uri.pathSegments.first
              : '';
          if (containerId.isNotEmpty) {
            final containerService = ref.read(containerServiceProvider);
            final container = containerService.getContainer(containerId);
            if (container != null) {
              // Donate to Siri for predictions
              if (Platform.isIOS) {
                SiriSpotlightService.donateContainerView(container);
              }
              router.push('/containers/$containerId');
              return;
            }
          }
        } else if (uri.host == 'qr') {
          final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
          if (id.isNotEmpty) {
            final containerService = ref.read(containerServiceProvider);
            // Check if linked to container
            final container = containerService.getContainerByQRCode(id);
            if (container != null) {
              router.push('/containers/${container.id}');
              return;
            }

            // Try QR first
            final qrData = QRService.getQRDataById(id);
            if (qrData != null) {
              router.push('/qr/$id');
              return;
            }

            // Try NFC
            final nfcData = NFCService.getNFCTagDataById(id);
            if (nfcData != null) {
              final nfcContainer = containerService.getContainerByNFCTag(id);
              if (nfcContainer != null) {
                router.push('/containers/${nfcContainer.id}');
                return;
              }
              router.push('/nfc/$id');
              return;
            }
          }
        } else if (uri.host == 'search') {
          final query = uri.queryParameters['q'] ?? uri.queryParameters['query'];
          router.push('/search${query != null ? '?q=$query' : ''}');
          return;
        } else if (uri.host == 'scan') {
          router.push('/scan');
          return;
        } else if (uri.host == 'faq') {
          final topic = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
          if (topic.isNotEmpty) {
            router.push('/faq/$topic');
          } else {
            router.push('/faq');
          }
          return;
        } else if (uri.host == 'containers' || uri.host == 'stats') {
          router.go('/');
          return;
        }

        // Not found - show error
        router.push('/error');
      } catch (e) {
        debugPrint('[DeepLink] Error handling deep link: $e');
        router.push('/error');
      }
    }
  }
}
