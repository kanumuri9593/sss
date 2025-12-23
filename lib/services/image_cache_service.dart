import 'dart:io';
import 'package:flutter/material.dart';

/// Image Cache Service for performance optimization
///
/// Provides memory-efficient image loading by:
/// 1. Eliminating synchronous file I/O from build methods
/// 2. Caching file existence checks to avoid repeated disk access
/// 3. Using Flutter's built-in ImageCache for decoded images
///
/// This service dramatically improves scroll performance by preventing
/// UI thread blocking from File.existsSync() calls.
class ImageCacheService {
  // Cache for file existence checks (path -> exists)
  static final Map<String, bool> _fileExistenceCache = {};

  // Maximum number of file existence results to cache
  static const int _maxCacheSize = 500;

  // Track the last eviction time to avoid excessive evictions
  static DateTime? _lastEviction;

  /// Get an ImageProvider for the given file path with optional caching
  ///
  /// Returns null if the path is null or empty.
  /// Uses optimistic rendering - assumes file exists and handles errors gracefully.
  ///
  /// The [cacheWidth] parameter can be used to limit decoded image resolution
  /// for better memory performance.
  static ImageProvider? getImageProvider(
    String? path, {
    int? cacheWidth,
    int? cacheHeight,
  }) {
    if (path == null || path.isEmpty) {
      return null;
    }

    // Optimistic approach: return FileImage and let error handlers deal with missing files
    // This avoids blocking the UI thread with synchronous file checks
    final file = File(path);

    if (cacheWidth != null || cacheHeight != null) {
      return ResizeImage(
        FileImage(file),
        width: cacheWidth,
        height: cacheHeight,
        allowUpscaling: false,
      );
    }

    return FileImage(file);
  }

  /// Asynchronously check if a file exists and cache the result
  ///
  /// Use this for pre-validation scenarios where you want to check
  /// file existence before displaying UI.
  static Future<bool> fileExists(String path) async {
    // Check cache first
    if (_fileExistenceCache.containsKey(path)) {
      return _fileExistenceCache[path]!;
    }

    // Perform async check
    final exists = await File(path).exists();

    // Cache the result
    _fileExistenceCache[path] = exists;

    // Evict if needed
    _evictIfNeeded();

    return exists;
  }

  /// Pre-validate multiple image paths asynchronously
  ///
  /// Useful for list screens where you want to batch-check file existence
  /// before rendering. This warms up the cache without blocking the UI.
  static Future<void> prevalidateImages(List<String> paths) async {
    final uncachedPaths = paths.where(
      (path) => !_fileExistenceCache.containsKey(path),
    ).toList();

    if (uncachedPaths.isEmpty) {
      return;
    }

    // Check all files in parallel
    final results = await Future.wait(
      uncachedPaths.map((path) => File(path).exists()),
    );

    // Cache results
    for (var i = 0; i < uncachedPaths.length; i++) {
      _fileExistenceCache[uncachedPaths[i]] = results[i];
    }

    _evictIfNeeded();
  }

  /// Clear the file existence cache
  ///
  /// Useful when files have been added/removed and you want to force
  /// re-validation.
  static void clear() {
    _fileExistenceCache.clear();
    debugPrint('[ImageCacheService] Cleared file existence cache');
  }

  /// Clear cached entry for a specific path
  ///
  /// Use this when you know a specific file has been added/removed.
  static void invalidatePath(String path) {
    _fileExistenceCache.remove(path);
  }

  /// Evict old entries if cache grows too large
  ///
  /// Uses simple FIFO eviction to prevent memory bloat.
  static void _evictIfNeeded() {
    if (_fileExistenceCache.length <= _maxCacheSize) {
      return;
    }

    // Only evict once per second to avoid performance overhead
    final now = DateTime.now();
    if (_lastEviction != null &&
        now.difference(_lastEviction!).inSeconds < 1) {
      return;
    }

    // Remove oldest 20% of entries
    final entriesToRemove = (_maxCacheSize * 0.2).ceil();
    final keysToRemove = _fileExistenceCache.keys.take(entriesToRemove).toList();

    for (final key in keysToRemove) {
      _fileExistenceCache.remove(key);
    }

    _lastEviction = now;
    debugPrint('[ImageCacheService] Evicted $entriesToRemove old entries');
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getStats() {
    return {
      'cachedPaths': _fileExistenceCache.length,
      'maxCacheSize': _maxCacheSize,
      'existingFiles': _fileExistenceCache.values.where((e) => e).length,
      'missingFiles': _fileExistenceCache.values.where((e) => !e).length,
    };
  }

  /// Get a cached FileImage with error handling
  ///
  /// This is a convenience method that combines getImageProvider with
  /// automatic error handling.
  static Widget buildCachedImage(
    String? path, {
    required Widget placeholder,
    BoxFit fit = BoxFit.cover,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    final imageProvider = getImageProvider(
      path,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );

    if (imageProvider == null) {
      return placeholder;
    }

    return Image(
      image: imageProvider,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return placeholder;
      },
    );
  }
}
