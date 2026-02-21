import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Permission Service
///
/// Centralized permission management for the app.
/// Handles requesting, checking, and managing all app permissions.
class PermissionService {
  // Cache permission statuses
  static final Map<ph.Permission, ph.PermissionStatus> _permissionCache = {};
  static DateTime? _lastCacheUpdate;

  /// Get permission status (with caching)
  static Future<ph.PermissionStatus> getPermissionStatus(ph.Permission permission) async {
    // Refresh cache if older than 5 seconds
    if (_lastCacheUpdate == null ||
        DateTime.now().difference(_lastCacheUpdate!) > const Duration(seconds: 5)) {
      await refreshPermissionCache();
    }
    return _permissionCache[permission] ?? ph.PermissionStatus.denied;
  }

  /// Refresh all permission statuses
  static Future<void> refreshPermissionCache() async {
    _permissionCache[ph.Permission.camera] = await ph.Permission.camera.status;
    _permissionCache[ph.Permission.storage] = await ph.Permission.storage.status;
    _permissionCache[ph.Permission.photos] = await ph.Permission.photos.status;
    _lastCacheUpdate = DateTime.now();
    debugPrint('[PermissionService] Cache refreshed');
  }

  /// Request a permission
  ///
  /// Returns the new status after request
  static Future<ph.PermissionStatus> requestPermission(ph.Permission permission) async {
    debugPrint('[PermissionService] Requesting permission: $permission');
    
    try {
      // Check current status first
      final currentStatus = await permission.status;
      debugPrint('[PermissionService] Current status for $permission: $currentStatus');
      
      // Only request if not already granted or permanently denied
      if (currentStatus.isGranted) {
        debugPrint('[PermissionService] Permission $permission already granted');
        _permissionCache[permission] = currentStatus;
        return currentStatus;
      }
      
      if (currentStatus.isPermanentlyDenied) {
        debugPrint('[PermissionService] Permission $permission permanently denied');
        _permissionCache[permission] = currentStatus;
        return currentStatus;
      }
      
      // Request the permission
      debugPrint('[PermissionService] Actually requesting $permission...');
      final status = await permission.request();
      _permissionCache[permission] = status;
      _lastCacheUpdate = DateTime.now();
      
      debugPrint('[PermissionService] Permission $permission request result: $status');
      debugPrint('[PermissionService] isGranted: ${status.isGranted}');
      debugPrint('[PermissionService] isDenied: ${status.isDenied}');
      debugPrint('[PermissionService] isPermanentlyDenied: ${status.isPermanentlyDenied}');
      debugPrint('[PermissionService] isLimited: ${status.isLimited}');
      debugPrint('[PermissionService] isRestricted: ${status.isRestricted}');
      
      return status;
    } catch (e, stackTrace) {
      debugPrint('[PermissionService] Error requesting $permission: $e');
      debugPrint('[PermissionService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Request camera permission proactively
  ///
  /// This should be called early in app lifecycle to ensure
  /// the app appears in iOS Settings even if user hasn't used camera yet
  static Future<ph.PermissionStatus> requestCameraPermission() async {
    return await requestPermission(ph.Permission.camera);
  }

  /// Request photos permission proactively
  static Future<ph.PermissionStatus> requestPhotosPermission() async {
    return await requestPermission(ph.Permission.photos);
  }

  /// Request storage permission (Android)
  static Future<ph.PermissionStatus> requestStoragePermission() async {
    return await requestPermission(ph.Permission.storage);
  }

  /// Check if permission is granted
  static Future<bool> isGranted(ph.Permission permission) async {
    final status = await getPermissionStatus(permission);
    return status.isGranted;
  }

  /// Check if permission is permanently denied
  static Future<bool> isPermanentlyDenied(ph.Permission permission) async {
    final status = await getPermissionStatus(permission);
    return status.isPermanentlyDenied;
  }

  /// Check if permission has been requested before
  static Future<bool> hasBeenRequested(ph.Permission permission) async {
    final status = await getPermissionStatus(permission);
    // If status is not "denied" (which means not asked), it has been requested
    return status != ph.PermissionStatus.denied;
  }

  /// Open app settings
  static Future<bool> openAppSettings() async {
    debugPrint('[PermissionService] Opening app settings');
    // Use the openAppSettings function from permission_handler package
    return await ph.openAppSettings();
  }

  /// Get all permission statuses
  static Future<Map<ph.Permission, ph.PermissionStatus>> getAllPermissionStatuses() async {
    await refreshPermissionCache();
    return Map.from(_permissionCache);
  }

  /// Request all required permissions proactively
  ///
  /// This should be called during app initialization to ensure
  /// permissions appear in Settings even if user hasn't used features yet
  static Future<Map<ph.Permission, ph.PermissionStatus>> requestAllPermissions() async {
    debugPrint('[PermissionService] Requesting all permissions proactively');
    
    final results = <ph.Permission, ph.PermissionStatus>{};
    
    // Request camera permission
    results[ph.Permission.camera] = await requestCameraPermission();
    
    // Request photos permission (iOS)
    if (!kIsWeb) {
      results[ph.Permission.photos] = await requestPhotosPermission();
    }
    
    // Request storage permission (Android)
    if (!kIsWeb) {
      results[ph.Permission.storage] = await requestStoragePermission();
    }
    
    return results;
  }

  /// Reset permission cache (useful for testing or after settings changes)
  static void clearCache() {
    _permissionCache.clear();
    _lastCacheUpdate = null;
    debugPrint('[PermissionService] Cache cleared');
  }
}
