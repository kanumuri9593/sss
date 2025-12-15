import 'package:flutter/foundation.dart';
import '../models/item.dart';
import 'storage_service.dart';

/// Item Service for managing items
///
/// Provides CRUD operations, search functionality, and item movement.
class ItemService {
  /// Create a new item
  static Future<Item> createItem(Item item) async {
    try {
      final box = StorageService.itemsBox;
      await box.put(item.id, item);
      debugPrint('[ItemService] Created item: ${item.id}');
      return item;
    } catch (e) {
      debugPrint('[ItemService] Error creating item: $e');
      rethrow;
    }
  }

  /// Get an item by ID
  static Item? getItem(String id) {
    try {
      final box = StorageService.itemsBox;
      return box.get(id);
    } catch (e) {
      debugPrint('[ItemService] Error getting item: $e');
      return null;
    }
  }

  /// Get all items
  static List<Item> getAllItems() {
    try {
      final box = StorageService.itemsBox;
      return box.values.toList();
    } catch (e) {
      debugPrint('[ItemService] Error getting all items: $e');
      return [];
    }
  }

  /// Get items by container ID
  static List<Item> getItemsByContainer(String containerId) {
    try {
      final box = StorageService.itemsBox;
      return box.values
          .where((item) => item.containerId == containerId)
          .toList();
    } catch (e) {
      debugPrint('[ItemService] Error getting items by container: $e');
      return [];
    }
  }

  /// Update an item
  static Future<Item?> updateItem(Item item) async {
    try {
      final box = StorageService.itemsBox;
      if (!box.containsKey(item.id)) {
        debugPrint('[ItemService] Item not found: ${item.id}');
        return null;
      }
      final updated = item.copyWith(
        updatedAt: DateTime.now().toIso8601String(),
      );
      await box.put(item.id, updated);
      debugPrint('[ItemService] Updated item: ${item.id}');
      return updated;
    } catch (e) {
      debugPrint('[ItemService] Error updating item: $e');
      return null;
    }
  }

  /// Delete an item
  static Future<bool> deleteItem(String id) async {
    try {
      final box = StorageService.itemsBox;
      if (!box.containsKey(id)) {
        debugPrint('[ItemService] Item not found: $id');
        return false;
      }
      await box.delete(id);
      debugPrint('[ItemService] Deleted item: $id');
      return true;
    } catch (e) {
      debugPrint('[ItemService] Error deleting item: $e');
      return false;
    }
  }

  /// Move an item to a different container
  static Future<bool> moveItem(String itemId, String newContainerId) async {
    try {
      final item = getItem(itemId);
      if (item == null) {
        debugPrint('[ItemService] Item not found: $itemId');
        return false;
      }

      final updated = item.copyWith(containerId: newContainerId);
      await updateItem(updated);
      debugPrint('[ItemService] Moved item $itemId to container $newContainerId');
      return true;
    } catch (e) {
      debugPrint('[ItemService] Error moving item: $e');
      return false;
    }
  }

  /// Search items by text (name, description, tags)
  static List<Item> searchItems(String query) {
    if (query.isEmpty) {
      return getAllItems();
    }

    try {
      final box = StorageService.itemsBox;
      final lowerQuery = query.toLowerCase();
      
      return box.values.where((item) {
        // Search by name
        if (item.name.toLowerCase().contains(lowerQuery)) {
          return true;
        }

        // Search by description
        if (item.description != null &&
            item.description!.toLowerCase().contains(lowerQuery)) {
          return true;
        }

        // Search by tags
        for (final tag in item.tags) {
          if (tag.toLowerCase().contains(lowerQuery)) {
            return true;
          }
        }

        return false;
      }).toList();
    } catch (e) {
      debugPrint('[ItemService] Error searching items: $e');
      return [];
    }
  }

  /// Search items by tags
  static List<Item> searchItemsByTags(List<String> tags) {
    if (tags.isEmpty) {
      return getAllItems();
    }

    try {
      final box = StorageService.itemsBox;
      final lowerTags = tags.map((t) => t.toLowerCase()).toSet();
      
      return box.values.where((item) {
        final itemTags = item.tags.map((t) => t.toLowerCase()).toSet();
        return lowerTags.intersection(itemTags).isNotEmpty;
      }).toList();
    } catch (e) {
      debugPrint('[ItemService] Error searching items by tags: $e');
      return [];
    }
  }

  /// Search items in a specific container
  static List<Item> searchItemsInContainer(String containerId, String query) {
    final containerItems = getItemsByContainer(containerId);
    if (query.isEmpty) {
      return containerItems;
    }

    final lowerQuery = query.toLowerCase();
    return containerItems.where((item) {
      // Search by name
      if (item.name.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // Search by description
      if (item.description != null &&
          item.description!.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // Search by tags
      for (final tag in item.tags) {
        if (tag.toLowerCase().contains(lowerQuery)) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  /// Get items by multiple container IDs
  static List<Item> getItemsByContainers(List<String> containerIds) {
    try {
      final box = StorageService.itemsBox;
      final containerIdSet = containerIds.toSet();
      return box.values
          .where((item) => containerIdSet.contains(item.containerId))
          .toList();
    } catch (e) {
      debugPrint('[ItemService] Error getting items by containers: $e');
      return [];
    }
  }

  /// Delete all items in a container
  static Future<int> deleteItemsInContainer(String containerId) async {
    try {
      final items = getItemsByContainer(containerId);
      int deletedCount = 0;
      for (final item in items) {
        if (await deleteItem(item.id)) {
          deletedCount++;
        }
      }
      debugPrint('[ItemService] Deleted $deletedCount items from container $containerId');
      return deletedCount;
    } catch (e) {
      debugPrint('[ItemService] Error deleting items in container: $e');
      return 0;
    }
  }

  /// Bulk update items (e.g., add tag to multiple items)
  static Future<int> bulkUpdateItems(
    List<String> itemIds,
    Item Function(Item) updateFunction,
  ) async {
    int updatedCount = 0;
    for (final itemId in itemIds) {
      final item = getItem(itemId);
      if (item != null) {
        final updated = updateFunction(item);
        if (await updateItem(updated) != null) {
          updatedCount++;
        }
      }
    }
    return updatedCount;
  }
}
