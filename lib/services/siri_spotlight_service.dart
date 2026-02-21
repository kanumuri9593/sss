import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_siri_suggestions/flutter_siri_suggestions.dart';
import 'package:flutter_core_spotlight/flutter_core_spotlight.dart';
import '../models/container.dart';
import '../models/item.dart';
import 'container_service.dart';
import 'item_service.dart';

/// Siri Shortcuts and Spotlight Service
///
/// Provides integration with:
/// - iOS Siri Shortcuts for voice commands
/// - iOS Spotlight Search for system-wide search
/// - Handles indexing and suggestion management
class SiriSpotlightService {
  /// Activity types for Siri
  static const String activitySearchContainers = 'com.example.sss.searchContainers';
  static const String activityViewContainer = 'com.example.sss.viewContainer';
  static const String activityAddItem = 'com.example.sss.addItem';
  static const String activityScanQR = 'com.example.sss.scanQR';
  static const String activityScanNFC = 'com.example.sss.scanNFC';

  /// Initialize the service
  static Future<void> initialize() async {
    if (!Platform.isIOS) {
      debugPrint('[SiriSpotlight] Not iOS, skipping initialization');
      return;
    }

    try {
      // Set up Siri activity handlers
      await _setupSiriShortcuts();

      // Index existing content for Spotlight
      await indexAllContent();

      debugPrint('[SiriSpotlight] Initialized');
    } catch (e) {
      debugPrint('[SiriSpotlight] Error initializing: $e');
    }
  }

  /// Set up default Siri shortcuts
  static Future<void> _setupSiriShortcuts() async {
    try {
      // Register shortcuts for main actions
      await FlutterSiriSuggestions.instance.registerActivity(
        FlutterSiriActivity(
          activitySearchContainers,
          'Search My Containers',
          isEligibleForSearch: true,
          isEligibleForPrediction: true,
          contentDescription: 'Search for containers and items in SSS',
          suggestedInvocationPhrase: 'Search my containers',
        ),
      );

      await FlutterSiriSuggestions.instance.registerActivity(
        FlutterSiriActivity(
          activityScanQR,
          'Scan QR Code',
          isEligibleForSearch: true,
          isEligibleForPrediction: true,
          contentDescription: 'Scan a QR code to find a container',
          suggestedInvocationPhrase: 'Scan storage QR',
        ),
      );

      await FlutterSiriSuggestions.instance.registerActivity(
        FlutterSiriActivity(
          activityScanNFC,
          'Scan NFC Tag',
          isEligibleForSearch: true,
          isEligibleForPrediction: true,
          contentDescription: 'Scan an NFC tag to find a container',
          suggestedInvocationPhrase: 'Scan storage tag',
        ),
      );

      debugPrint('[SiriSpotlight] Siri shortcuts registered');
    } catch (e) {
      debugPrint('[SiriSpotlight] Error setting up Siri shortcuts: $e');
    }
  }

  /// Donate a container view activity to Siri (for predictions)
  static Future<void> donateContainerView(Container container) async {
    if (!Platform.isIOS) return;

    try {
      await FlutterSiriSuggestions.instance.registerActivity(
        FlutterSiriActivity(
          '$activityViewContainer.${container.id}',
          'Open ${container.name}',
          isEligibleForSearch: true,
          isEligibleForPrediction: true,
          contentDescription: '${container.typeDisplayName}: ${container.name}',
          suggestedInvocationPhrase: 'Open ${container.name}',
          userInfo: {
            'containerId': container.id,
            'containerName': container.name,
            'containerType': container.type.name,
            'deepLink': container.buildDeepLink(),
          },
        ),
      );

      debugPrint('[SiriSpotlight] Donated container view: ${container.name}');
    } catch (e) {
      debugPrint('[SiriSpotlight] Error donating container view: $e');
    }
  }

  /// Index all containers and items for Spotlight search
  static Future<void> indexAllContent() async {
    if (!Platform.isIOS) return;

    try {
      final containers = ContainerService.getAllContainers();
      final items = ItemService.getAllItems();

      // Index containers
      for (final container in containers) {
        await _indexContainer(container);
      }

      // Index items
      for (final item in items) {
        await _indexItem(item);
      }

      debugPrint('[SiriSpotlight] Indexed ${containers.length} containers and ${items.length} items');
    } catch (e) {
      debugPrint('[SiriSpotlight] Error indexing content: $e');
    }
  }

  /// Index a single container for Spotlight
  static Future<void> _indexContainer(Container container) async {
    try {
      final itemCount = ContainerService.getItemsInContainer(container.id).length;
      final childCount = ContainerService.getChildContainers(container.id).length;

      await FlutterCoreSpotlight.instance.indexSearchableItems([
        FlutterSpotlightItem(
          uniqueIdentifier: 'container-${container.id}',
          domainIdentifier: 'com.example.sss.containers',
          attributeTitle: '${container.typeIcon} ${container.name}',
          attributeDescription: container.description ?? 
            '${container.typeDisplayName} with $itemCount items${childCount > 0 ? ' and $childCount sub-containers' : ''}',
        ),
      ]);
    } catch (e) {
      debugPrint('[SiriSpotlight] Error indexing container: $e');
    }
  }

  /// Index a single item for Spotlight
  static Future<void> _indexItem(Item item) async {
    try {
      final container = ContainerService.getContainer(item.containerId);
      final containerName = container?.name ?? 'Unknown';

      await FlutterCoreSpotlight.instance.indexSearchableItems([
        FlutterSpotlightItem(
          uniqueIdentifier: 'item-${item.id}',
          domainIdentifier: 'com.example.sss.items',
          attributeTitle: item.name,
          attributeDescription: item.description ?? 'Item in $containerName',
        ),
      ]);
    } catch (e) {
      debugPrint('[SiriSpotlight] Error indexing item: $e');
    }
  }

  /// Update index for a container
  static Future<void> updateContainerIndex(Container container) async {
    if (!Platform.isIOS) return;

    await _indexContainer(container);
    await donateContainerView(container);
  }

  /// Update index for an item
  static Future<void> updateItemIndex(Item item) async {
    if (!Platform.isIOS) return;

    await _indexItem(item);
  }

  /// Remove a container from Spotlight index
  static Future<void> removeContainerFromIndex(String containerId) async {
    if (!Platform.isIOS) return;

    try {
      await FlutterCoreSpotlight.instance.deleteSearchableItems(['container-$containerId']);
      debugPrint('[SiriSpotlight] Removed container from index: $containerId');
    } catch (e) {
      debugPrint('[SiriSpotlight] Error removing container: $e');
    }
  }

  /// Remove an item from Spotlight index
  static Future<void> removeItemFromIndex(String itemId) async {
    if (!Platform.isIOS) return;

    try {
      await FlutterCoreSpotlight.instance.deleteSearchableItems(['item-$itemId']);
      debugPrint('[SiriSpotlight] Removed item from index: $itemId');
    } catch (e) {
      debugPrint('[SiriSpotlight] Error removing item: $e');
    }
  }

  /// Clear all Spotlight index
  static Future<void> clearAllIndex() async {
    if (!Platform.isIOS) return;

    try {
      // Re-index with empty lists to effectively clear
      // The package doesn't have a deleteAll method, so we delete known items
      final containers = ContainerService.getAllContainers();
      final items = ItemService.getAllItems();
      
      final containerIds = containers.map((c) => 'container-${c.id}').toList();
      final itemIds = items.map((i) => 'item-${i.id}').toList();
      
      if (containerIds.isNotEmpty) {
        await FlutterCoreSpotlight.instance.deleteSearchableItems(containerIds);
      }
      if (itemIds.isNotEmpty) {
        await FlutterCoreSpotlight.instance.deleteSearchableItems(itemIds);
      }
      
      debugPrint('[SiriSpotlight] Cleared all index');
    } catch (e) {
      debugPrint('[SiriSpotlight] Error clearing index: $e');
    }
  }

  /// Handle Siri activity (when user invokes shortcut)
  static void handleSiriActivity(String activityType, Map<String, dynamic>? userInfo) {
    debugPrint('[SiriSpotlight] Siri activity: $activityType');

    if (activityType == activitySearchContainers) {
      // Navigate to search screen
      // This would be handled by the app's navigation
    } else if (activityType == activityScanQR) {
      // Navigate to QR scanner
    } else if (activityType == activityScanNFC) {
      // Navigate to NFC scanner
    } else if (activityType.startsWith(activityViewContainer)) {
      // Navigate to specific container
      final containerId = userInfo?['containerId'];
      if (containerId != null) {
        // Navigate using deep link
        final deepLink = userInfo?['deepLink'] ?? 'sss://container/$containerId';
        debugPrint('[SiriSpotlight] Opening container: $deepLink');
      }
    }
  }
}
