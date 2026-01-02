import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/container.dart';
import 'container_service.dart';
import 'item_service.dart';

/// Google Assistant / Gemini Integration Service
///
/// Provides integration with Android App Actions for:
/// - Google Assistant voice commands
/// - Gemini AI assistant integration
/// - Android search integration
class GoogleAssistantService {
  static const MethodChannel _channel = MethodChannel('com.example.sss/assistant');

  /// Built-in intents supported
  static const String intentSearch = 'actions.intent.OPEN_APP_FEATURE';
  static const String intentGetItem = 'actions.intent.GET_THING';

  /// Initialize the service
  static Future<void> initialize() async {
    if (!Platform.isAndroid) {
      debugPrint('[GoogleAssistant] Not Android, skipping initialization');
      return;
    }

    try {
      // Set up method channel handler for incoming intents
      _channel.setMethodCallHandler(_handleMethodCall);

      // Update shortcuts for App Actions
      await updateAppActions();

      debugPrint('[GoogleAssistant] Initialized');
    } catch (e) {
      debugPrint('[GoogleAssistant] Error initializing: $e');
    }
  }

  /// Handle method calls from native Android
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    debugPrint('[GoogleAssistant] Received: ${call.method} with ${call.arguments}');

    switch (call.method) {
      case 'searchContainers':
        final query = call.arguments?['query'] as String?;
        return await _handleSearch(query);

      case 'openContainer':
        final containerId = call.arguments?['containerId'] as String?;
        return await _handleOpenContainer(containerId);

      case 'getContainerInfo':
        final containerId = call.arguments?['containerId'] as String?;
        return await _handleGetContainerInfo(containerId);

      case 'getStats':
        return await _handleGetStats();

      case 'scanQR':
        return {'action': 'navigate', 'screen': 'qr_scanner'};

      case 'scanNFC':
        return {'action': 'navigate', 'screen': 'nfc_scanner'};

      default:
        return null;
    }
  }

  /// Handle search request
  static Future<Map<String, dynamic>> _handleSearch(String? query) async {
    if (query == null || query.isEmpty) {
      return {'action': 'navigate', 'screen': 'search'};
    }

    try {
      final containers = await ContainerService.searchContainers(query);
      final items = await ItemService.searchItems(query);

      return {
        'action': 'search_results',
        'query': query,
        'containerCount': containers.length,
        'itemCount': items.length,
        'containers': containers.take(5).map((c) => {
          'id': c.id,
          'name': c.name,
          'type': c.type.name,
          'deepLink': c.buildDeepLink(),
        }).toList(),
      };
    } catch (e) {
      debugPrint('[GoogleAssistant] Error searching: $e');
      return {'action': 'error', 'message': 'Search failed'};
    }
  }

  /// Handle open container request
  static Future<Map<String, dynamic>> _handleOpenContainer(String? containerId) async {
    if (containerId == null) {
      return {'action': 'error', 'message': 'Container ID not provided'};
    }

    final container = ContainerService.getContainer(containerId);
    if (container == null) {
      return {'action': 'error', 'message': 'Container not found'};
    }

    return {
      'action': 'navigate',
      'screen': 'container_detail',
      'containerId': containerId,
      'deepLink': container.buildDeepLink(),
    };
  }

  /// Handle get container info request (for voice response)
  static Future<Map<String, dynamic>> _handleGetContainerInfo(String? containerId) async {
    if (containerId == null) {
      return {'action': 'error', 'message': 'Container ID not provided'};
    }

    final container = ContainerService.getContainer(containerId);
    if (container == null) {
      return {'action': 'error', 'message': 'Container not found'};
    }

    final items = ContainerService.getItemsInContainer(containerId);
    final children = ContainerService.getChildContainers(containerId);

    return {
      'action': 'info',
      'name': container.name,
      'type': container.typeDisplayName,
      'description': container.description ?? 'No description',
      'itemCount': items.length,
      'childCount': children.length,
      'tags': container.tags,
      'speechResponse': '${container.name} is a ${container.typeDisplayName} with ${items.length} items'
          '${children.isNotEmpty ? ' and ${children.length} sub-containers' : ''}.',
    };
  }

  /// Handle get stats request
  static Future<Map<String, dynamic>> _handleGetStats() async {
    final containers = ContainerService.getAllContainers();
    final items = ItemService.getAllItems();

    final boxCount = containers.where((c) => c.type == ContainerType.box).length;
    final bagCount = containers.where((c) => c.type == ContainerType.bag).length;
    final drawerCount = containers.where((c) => c.type == ContainerType.drawer).length;

    return {
      'action': 'stats',
      'totalContainers': containers.length,
      'totalItems': items.length,
      'boxes': boxCount,
      'bags': bagCount,
      'drawers': drawerCount,
      'speechResponse': 'You have ${containers.length} containers with ${items.length} items total. '
          '$boxCount boxes, $bagCount bags, and $drawerCount drawers.',
    };
  }

  /// Update App Actions shortcuts
  static Future<void> updateAppActions() async {
    if (!Platform.isAndroid) return;

    try {
      final containers = ContainerService.getAllContainers();

      // Get recent containers for dynamic shortcuts
      final recentContainers = containers.take(5).toList();
      recentContainers.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      final shortcuts = recentContainers.map((c) => {
        'id': 'container_${c.id}',
        'shortLabel': c.name,
        'longLabel': 'Open ${c.name}',
        'iconType': c.type.name,
        'deepLink': c.buildDeepLink(),
      }).toList();

      await _channel.invokeMethod('updateShortcuts', {'shortcuts': shortcuts});
      debugPrint('[GoogleAssistant] Updated ${shortcuts.length} shortcuts');
    } catch (e) {
      debugPrint('[GoogleAssistant] Error updating shortcuts: $e');
    }
  }

  /// Report shortcut used (for ranking)
  static Future<void> reportShortcutUsed(String shortcutId) async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('reportShortcutUsed', {'shortcutId': shortcutId});
    } catch (e) {
      debugPrint('[GoogleAssistant] Error reporting shortcut: $e');
    }
  }
}
