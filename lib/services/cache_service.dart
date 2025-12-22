import 'package:flutter/foundation.dart';
import 'item_service.dart';
import 'container_service.dart';

/// Cache Service for performance optimization
///
/// Maintains in-memory cache of expensive-to-compute values like item counts
/// and child container counts to avoid O(n) database queries in ListView builders.
///
/// The cache is automatically invalidated when items or containers are
/// created, updated, or deleted.
class CacheService {
  // Cache for item counts per container
  static final Map<String, int> _itemCounts = {};

  // Cache for child container counts per container
  static final Map<String, int> _childContainerCounts = {};

  // Track initialization state
  static bool _isInitialized = false;

  // Maximum cache size to prevent memory bloat
  static const int _maxCacheSize = 1000;

  /// Initialize the cache by pre-computing all counts
  ///
  /// This should be called once when the app starts or when entering
  /// screens that display lists of containers.
  static void initialize() {
    if (_isInitialized) {
      return; // Already initialized
    }

    debugPrint('[CacheService] Initializing cache...');
    final startTime = DateTime.now();

    try {
      // Get all containers to compute counts
      final allContainers = ContainerService.getAllContainers();

      // Pre-compute item counts for all containers
      for (final container in allContainers) {
        final itemCount = ItemService.getItemsByContainer(container.id).length;
        _itemCounts[container.id] = itemCount;

        final childCount = ContainerService.getChildContainers(container.id).length;
        _childContainerCounts[container.id] = childCount;
      }

      _isInitialized = true;

      final duration = DateTime.now().difference(startTime);
      debugPrint('[CacheService] Cache initialized in ${duration.inMilliseconds}ms');
      debugPrint('[CacheService] Cached ${_itemCounts.length} container counts');
    } catch (e) {
      debugPrint('[CacheService] Error initializing cache: $e');
    }
  }

  /// Get the number of items in a container (cached)
  ///
  /// Returns 0 if the container is not in cache (will trigger lazy computation).
  static int getItemCount(String containerId) {
    // Lazy initialization if cache miss
    if (!_itemCounts.containsKey(containerId)) {
      final count = ItemService.getItemsByContainer(containerId).length;
      _itemCounts[containerId] = count;
      _evictIfNeeded();
      return count;
    }

    return _itemCounts[containerId]!;
  }

  /// Get the number of child containers (cached)
  ///
  /// Returns 0 if the container is not in cache (will trigger lazy computation).
  static int getChildContainerCount(String containerId) {
    // Lazy initialization if cache miss
    if (!_childContainerCounts.containsKey(containerId)) {
      final count = ContainerService.getChildContainers(containerId).length;
      _childContainerCounts[containerId] = count;
      _evictIfNeeded();
      return count;
    }

    return _childContainerCounts[containerId]!;
  }

  /// Invalidate cache for a specific container
  ///
  /// This should be called whenever:
  /// - An item is added/removed/moved to/from this container
  /// - A child container is added/removed from this container
  /// - The container itself is modified
  static void invalidateContainer(String containerId) {
    _itemCounts.remove(containerId);
    _childContainerCounts.remove(containerId);
    debugPrint('[CacheService] Invalidated cache for container: $containerId');
  }

  /// Invalidate the entire cache
  ///
  /// Useful for testing or when bulk operations have been performed.
  static void invalidateAll() {
    _itemCounts.clear();
    _childContainerCounts.clear();
    _isInitialized = false;
    debugPrint('[CacheService] Cleared all cache');
  }

  /// Evict old entries if cache grows too large
  ///
  /// Simple LRU-like eviction: removes first entry when max size reached.
  /// This prevents memory bloat in apps with many containers.
  static void _evictIfNeeded() {
    if (_itemCounts.length > _maxCacheSize) {
      // Remove oldest entry (first key)
      if (_itemCounts.isNotEmpty) {
        final firstKey = _itemCounts.keys.first;
        _itemCounts.remove(firstKey);
        debugPrint('[CacheService] Evicted item count cache for: $firstKey');
      }
    }

    if (_childContainerCounts.length > _maxCacheSize) {
      // Remove oldest entry (first key)
      if (_childContainerCounts.isNotEmpty) {
        final firstKey = _childContainerCounts.keys.first;
        _childContainerCounts.remove(firstKey);
        debugPrint('[CacheService] Evicted child count cache for: $firstKey');
      }
    }
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getStats() {
    return {
      'initialized': _isInitialized,
      'itemCountsCached': _itemCounts.length,
      'childCountsCached': _childContainerCounts.length,
      'maxCacheSize': _maxCacheSize,
    };
  }

  /// Get both counts in one call (optimization for widgets that need both)
  static ({int itemCount, int childCount}) getCounts(String containerId) {
    return (
      itemCount: getItemCount(containerId),
      childCount: getChildContainerCount(containerId),
    );
  }
}
