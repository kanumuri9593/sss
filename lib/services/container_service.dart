import 'package:flutter/foundation.dart';
import '../models/container.dart';
import '../models/item.dart';
import 'storage_service.dart';
import 'item_service.dart';
import 'cache_service.dart';

/// Container Service for managing containers
///
/// Provides CRUD operations, search functionality, nesting support,
/// and QR/NFC linking capabilities.
class ContainerService {
  /// Create a new container
  static Future<Container> createContainer(Container container) async {
    try {
      final box = StorageService.containersBox;
      await box.put(container.id, container);
      // Invalidate cache for parent container (if any) and self
      if (container.parentContainerId != null) {
        CacheService.invalidateContainer(container.parentContainerId!);
      }
      CacheService.invalidateContainer(container.id);
      // Ensure data is persisted to disk
      await box.flush();
      debugPrint('[ContainerService] Created container: ${container.id} (total: ${box.length})');
      return container;
    } catch (e) {
      debugPrint('[ContainerService] Error creating container: $e');
      rethrow;
    }
  }

  /// Get a container by ID
  static Container? getContainer(String id) {
    try {
      final box = StorageService.containersBox;
      return box.get(id);
    } catch (e) {
      debugPrint('[ContainerService] Error getting container: $e');
      return null;
    }
  }

  /// Get all containers
  static List<Container> getAllContainers() {
    try {
      final box = StorageService.containersBox;
      final containers = box.values.toList();
      debugPrint('[ContainerService] Retrieved ${containers.length} containers from storage');
      return containers;
    } catch (e) {
      debugPrint('[ContainerService] Error getting all containers: $e');
      return [];
    }
  }

  /// Get root containers (containers without a parent)
  static List<Container> getRootContainers() {
    try {
      final box = StorageService.containersBox;
      return box.values
          .where((container) => container.parentContainerId == null)
          .toList();
    } catch (e) {
      debugPrint('[ContainerService] Error getting root containers: $e');
      return [];
    }
  }

  /// Get child containers (containers within a parent container)
  static List<Container> getChildContainers(String parentContainerId) {
    try {
      final box = StorageService.containersBox;
      return box.values
          .where((container) => container.parentContainerId == parentContainerId)
          .toList();
    } catch (e) {
      debugPrint('[ContainerService] Error getting child containers: $e');
      return [];
    }
  }

  /// Update a container
  static Future<Container?> updateContainer(Container container) async {
    try {
      final box = StorageService.containersBox;
      if (!box.containsKey(container.id)) {
        debugPrint('[ContainerService] Container not found: ${container.id}');
        return null;
      }
      final updated = container.copyWith(
        updatedAt: DateTime.now().toIso8601String(),
      );
      await box.put(container.id, updated);
      // Invalidate cache for this container and its parent (if any)
      CacheService.invalidateContainer(container.id);
      if (container.parentContainerId != null) {
        CacheService.invalidateContainer(container.parentContainerId!);
      }
      // Ensure data is persisted to disk
      await box.flush();
      debugPrint('[ContainerService] Updated container: ${container.id}');
      return updated;
    } catch (e) {
      debugPrint('[ContainerService] Error updating container: $e');
      return null;
    }
  }

  /// Delete a container
  ///
  /// Also deletes all items in the container and child containers.
  /// Returns true if successful, false otherwise.
  static Future<bool> deleteContainer(String id) async {
    try {
      final box = StorageService.containersBox;
      if (!box.containsKey(id)) {
        debugPrint('[ContainerService] Container not found: $id');
        return false;
      }

      // Get container to access parent ID before deletion
      final container = box.get(id);
      final parentId = container?.parentContainerId;

      // Get all child containers recursively
      final childContainers = _getAllChildContainers(id);

      // Delete all child containers first
      for (final child in childContainers) {
        await deleteContainer(child.id);
      }

      // Delete all items in this container
      final items = ItemService.getItemsByContainer(id);
      for (final item in items) {
        await ItemService.deleteItem(item.id);
      }

      // Delete the container itself
      await box.delete(id);
      // Invalidate cache for this container and its parent (if any)
      CacheService.invalidateContainer(id);
      if (parentId != null) {
        CacheService.invalidateContainer(parentId);
      }
      // Ensure deletion is persisted to disk
      await box.flush();
      debugPrint('[ContainerService] Deleted container: $id');
      return true;
    } catch (e) {
      debugPrint('[ContainerService] Error deleting container: $e');
      return false;
    }
  }

  /// Get all child containers recursively
  static List<Container> _getAllChildContainers(String parentId) {
    final children = getChildContainers(parentId);
    final allChildren = <Container>[...children];
    for (final child in children) {
      allChildren.addAll(_getAllChildContainers(child.id));
    }
    return allChildren;
  }

  /// Get items in a container
  static List<Item> getItemsInContainer(String containerId) {
    return ItemService.getItemsByContainer(containerId);
  }

  /// Search containers by name, tags, or linked QR/NFC
  static Future<List<Container>> searchContainers(String query) async {
    if (query.isEmpty) {
      return getAllContainers();
    }

    try {
      final box = StorageService.containersBox;
      final containers = box.values.toList();
      
      return await compute(_filterContainers, {
        'containers': containers,
        'query': query,
      });
    } catch (e) {
      debugPrint('[ContainerService] Error searching containers: $e');
      return [];
    }
  }

  static List<Container> _filterContainers(Map<String, dynamic> params) {
    final containers = params['containers'] as List<Container>;
    final lowerQuery = (params['query'] as String).toLowerCase();

    return containers.where((container) {
      // Search by name
      if (container.name.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // Search by description
      if (container.description != null &&
          container.description!.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // Search by tags
      for (final tag in container.tags) {
        if (tag.toLowerCase().contains(lowerQuery)) {
          return true;
        }
      }

      // Search by QR code ID
      if (container.qrCodeId != null &&
          container.qrCodeId!.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // Search by NFC tag ID
      if (container.nfcTagId != null &&
          container.nfcTagId!.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      return false;
    }).toList();
  }

  /// Search containers by tags
  static Future<List<Container>> searchContainersByTags(List<String> tags) async {
    if (tags.isEmpty) {
      return getAllContainers();
    }

    try {
      final box = StorageService.containersBox;
      final containers = box.values.toList();
      
      return await compute(_filterContainersByTags, {
        'containers': containers,
        'tags': tags,
      });
    } catch (e) {
      debugPrint('[ContainerService] Error searching containers by tags: $e');
      return [];
    }
  }

  static List<Container> _filterContainersByTags(Map<String, dynamic> params) {
    final containers = params['containers'] as List<Container>;
    final tags = params['tags'] as List<String>;
    final lowerTags = tags.map((t) => t.toLowerCase()).toSet();
    
    return containers.where((container) {
      final containerTags = container.tags.map((t) => t.toLowerCase()).toSet();
      return lowerTags.intersection(containerTags).isNotEmpty;
    }).toList();
  }

  /// Link a QR code to a container
  static Future<bool> linkQRCode(String containerId, String qrCodeId) async {
    try {
      final container = getContainer(containerId);
      if (container == null) {
        debugPrint('[ContainerService] Container not found: $containerId');
        return false;
      }

      final updated = container.copyWith(qrCodeId: qrCodeId);
      await updateContainer(updated);
      debugPrint('[ContainerService] Linked QR code $qrCodeId to container $containerId');
      return true;
    } catch (e) {
      debugPrint('[ContainerService] Error linking QR code: $e');
      return false;
    }
  }

  /// Link an NFC tag to a container
  static Future<bool> linkNFCTag(String containerId, String nfcTagId) async {
    try {
      final container = getContainer(containerId);
      if (container == null) {
        debugPrint('[ContainerService] Container not found: $containerId');
        return false;
      }

      final updated = container.copyWith(nfcTagId: nfcTagId);
      await updateContainer(updated);
      debugPrint('[ContainerService] Linked NFC tag $nfcTagId to container $containerId');
      return true;
    } catch (e) {
      debugPrint('[ContainerService] Error linking NFC tag: $e');
      return false;
    }
  }

  /// Unlink QR code from a container
  static Future<bool> unlinkQRCode(String containerId) async {
    try {
      final container = getContainer(containerId);
      if (container == null) {
        debugPrint('[ContainerService] Container not found: $containerId');
        return false;
      }

      final updated = container.copyWith(clearQrCodeId: true);
      await updateContainer(updated);
      debugPrint('[ContainerService] Unlinked QR code from container $containerId');
      return true;
    } catch (e) {
      debugPrint('[ContainerService] Error unlinking QR code: $e');
      return false;
    }
  }

  /// Unlink NFC tag from a container
  static Future<bool> unlinkNFCTag(String containerId) async {
    try {
      final container = getContainer(containerId);
      if (container == null) {
        debugPrint('[ContainerService] Container not found: $containerId');
        return false;
      }

      final updated = container.copyWith(clearNfcTagId: true);
      await updateContainer(updated);
      debugPrint('[ContainerService] Unlinked NFC tag from container $containerId');
      return true;
    } catch (e) {
      debugPrint('[ContainerService] Error unlinking NFC tag: $e');
      return false;
    }
  }

  /// Get container by QR code ID
  static Container? getContainerByQRCode(String qrCodeId) {
    try {
      final box = StorageService.containersBox;
      return box.values.firstWhere(
        (container) => container.qrCodeId == qrCodeId,
        orElse: () => throw StateError('Container not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get container by NFC tag ID
  static Container? getContainerByNFCTag(String nfcTagId) {
    try {
      final box = StorageService.containersBox;
      return box.values.firstWhere(
        (container) => container.nfcTagId == nfcTagId,
        orElse: () => throw StateError('Container not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if a container can be nested in another (prevents circular references)
  static bool canNestContainer(String containerId, String parentContainerId) {
    if (containerId == parentContainerId) {
      return false; // Can't nest container in itself
    }

    // Check if parent is a child of container (would create circular reference)
    final parent = getContainer(parentContainerId);
    if (parent == null) {
      return true; // Parent doesn't exist, so it's safe
    }

    // Check all ancestors of parent
    String? currentParentId = parent.parentContainerId;
    while (currentParentId != null) {
      if (currentParentId == containerId) {
        return false; // Circular reference detected
      }
      final currentParent = getContainer(currentParentId);
      currentParentId = currentParent?.parentContainerId;
    }

    return true;
  }

  /// Move a container to a new parent (or make it root)
  static Future<bool> moveContainer(String containerId, String? newParentContainerId) async {
    try {
      if (newParentContainerId != null &&
          !canNestContainer(containerId, newParentContainerId)) {
        debugPrint('[ContainerService] Cannot nest container: circular reference');
        return false;
      }

      final container = getContainer(containerId);
      if (container == null) {
        debugPrint('[ContainerService] Container not found: $containerId');
        return false;
      }

      final updated = container.copyWith(parentContainerId: newParentContainerId);
      await updateContainer(updated);
      debugPrint('[ContainerService] Moved container $containerId to parent $newParentContainerId');
      return true;
    } catch (e) {
      debugPrint('[ContainerService] Error moving container: $e');
      return false;
    }
  }
}
