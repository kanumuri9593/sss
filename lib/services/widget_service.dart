import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'container_service.dart';
import 'item_service.dart';

/// Widget Service for Home Screen Widgets
///
/// Manages data sharing between the Flutter app and native widgets
/// on both iOS (WidgetKit) and Android (App Widgets).
class WidgetService {
  /// App group identifier for iOS (must match widget extension)
  static const String iOSAppGroupId = 'group.com.example.sss';

  /// Widget names
  static const String quickSearchWidget = 'SSSQuickSearchWidget';
  static const String recentContainersWidget = 'SSSRecentContainersWidget';
  static const String statsWidget = 'SSSStatsWidget';

  /// Initialize widget service
  static Future<void> initialize() async {
    try {
      // Set app group for iOS
      if (Platform.isIOS) {
        await HomeWidget.setAppGroupId(iOSAppGroupId);
      }
      debugPrint('[WidgetService] Initialized');
    } catch (e) {
      debugPrint('[WidgetService] Error initializing: $e');
    }
  }

  /// Update all widgets with fresh data
  static Future<void> updateAllWidgets() async {
    try {
      await Future.wait([
        updateQuickSearchData(),
        updateRecentContainersData(),
        updateStatsData(),
      ]);
      debugPrint('[WidgetService] All widgets updated');
    } catch (e) {
      debugPrint('[WidgetService] Error updating widgets: $e');
    }
  }

  /// Update quick search widget data
  static Future<void> updateQuickSearchData() async {
    try {
      final containers = ContainerService.getAllContainers();
      final items = ItemService.getAllItems();

      // Store counts for quick display
      await HomeWidget.saveWidgetData<int>('containerCount', containers.length);
      await HomeWidget.saveWidgetData<int>('itemCount', items.length);

      // Store recent search terms (if available)
      await HomeWidget.saveWidgetData<String>('lastUpdated', DateTime.now().toIso8601String());

      // Update the widget
      await HomeWidget.updateWidget(
        iOSName: quickSearchWidget,
        androidName: quickSearchWidget,
      );

      debugPrint('[WidgetService] Quick search widget updated');
    } catch (e) {
      debugPrint('[WidgetService] Error updating quick search: $e');
    }
  }

  /// Update recent containers widget data
  static Future<void> updateRecentContainersData() async {
    try {
      final containers = ContainerService.getAllContainers();
      
      // Sort by most recently updated
      containers.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      // Take top 5 recent containers
      final recentContainers = containers.take(5).toList();
      
      // Convert to JSON for storage
      final containersJson = recentContainers.map((c) => {
        'id': c.id,
        'name': c.name,
        'type': c.type.name,
        'itemCount': ContainerService.getItemsInContainer(c.id).length,
        'deepLink': c.buildDeepLink(),
      }).toList();

      await HomeWidget.saveWidgetData<String>(
        'recentContainers',
        jsonEncode(containersJson),
      );
      await HomeWidget.saveWidgetData<String>('lastUpdated', DateTime.now().toIso8601String());

      // Update the widget
      await HomeWidget.updateWidget(
        iOSName: recentContainersWidget,
        androidName: recentContainersWidget,
      );

      debugPrint('[WidgetService] Recent containers widget updated with ${recentContainers.length} containers');
    } catch (e) {
      debugPrint('[WidgetService] Error updating recent containers: $e');
    }
  }

  /// Update stats widget data
  static Future<void> updateStatsData() async {
    try {
      final containers = ContainerService.getAllContainers();
      final items = ItemService.getAllItems();
      
      // Calculate stats
      final containersByType = <String, int>{};
      for (final container in containers) {
        final type = container.type.name;
        containersByType[type] = (containersByType[type] ?? 0) + 1;
      }

      final rootContainers = containers.where((c) => c.parentContainerId == null).length;
      final nestedContainers = containers.length - rootContainers;

      // Store stats
      await HomeWidget.saveWidgetData<int>('totalContainers', containers.length);
      await HomeWidget.saveWidgetData<int>('totalItems', items.length);
      await HomeWidget.saveWidgetData<int>('rootContainers', rootContainers);
      await HomeWidget.saveWidgetData<int>('nestedContainers', nestedContainers);
      await HomeWidget.saveWidgetData<int>('boxCount', containersByType['box'] ?? 0);
      await HomeWidget.saveWidgetData<int>('bagCount', containersByType['bag'] ?? 0);
      await HomeWidget.saveWidgetData<int>('drawerCount', containersByType['drawer'] ?? 0);
      await HomeWidget.saveWidgetData<String>('lastUpdated', DateTime.now().toIso8601String());

      // Update the widget
      await HomeWidget.updateWidget(
        iOSName: statsWidget,
        androidName: statsWidget,
      );

      debugPrint('[WidgetService] Stats widget updated');
    } catch (e) {
      debugPrint('[WidgetService] Error updating stats: $e');
    }
  }

  /// Handle widget interaction (when user taps on widget)
  static Future<void> handleWidgetClick(Uri? uri) async {
    if (uri == null) return;

    debugPrint('[WidgetService] Widget clicked with URI: $uri');

    // The app's main.dart should handle the deep link navigation
    // This method is called to process the intent
  }

  /// Register widget click callback
  static void registerClickHandler(void Function(Uri?) callback) {
    HomeWidget.widgetClicked.listen(callback);
  }

  /// Check if widgets are supported
  static Future<bool> isSupported() async {
    if (Platform.isIOS || Platform.isAndroid) {
      return true;
    }
    return false;
  }

  /// Request widget pin (Android only) - adds widget to home screen
  static Future<bool> requestPin({required String widgetName}) async {
    if (!Platform.isAndroid) return false;
    
    try {
      await HomeWidget.requestPinWidget(
        name: widgetName,
        qualifiedAndroidName: 'com.example.sss.$widgetName',
      );
      return true;
    } catch (e) {
      debugPrint('[WidgetService] Error pinning widget: $e');
      return false;
    }
  }

  /// Get initial widget click URI (for app launch from widget)
  static Future<Uri?> getInitialUri() async {
    try {
      return await HomeWidget.initiallyLaunchedFromHomeWidget();
    } catch (e) {
      debugPrint('[WidgetService] Error getting initial URI: $e');
      return null;
    }
  }
}
