import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// File utilities for handling file operations
class FileUtils {
  /// Get the downloads directory for saving files
  static Future<Directory> getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // On Android, try to use Downloads folder in external storage
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        // Navigate to Downloads folder
        final downloadsDir = Directory('${externalDir.path}/../Download');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
          debugPrint('[FileUtils] Created downloads directory: ${downloadsDir.path}');
        }
        debugPrint('[FileUtils] Using downloads directory: ${downloadsDir.path}');
        return downloadsDir;
      }
      // Fallback to external storage root
      final fallbackDir = externalDir ?? await getApplicationDocumentsDirectory();
      debugPrint('[FileUtils] Using fallback downloads directory: ${fallbackDir.path}');
      return fallbackDir;
    } else {
      // On iOS, use documents directory (accessible via Files app)
      final dir = await getApplicationDocumentsDirectory();
      debugPrint('[FileUtils] Using iOS documents directory: ${dir.path}');
      return dir;
    }
  }

  /// Get the application documents directory for stable persistent storage
  ///
  /// Uses getApplicationDocumentsDirectory() on both platforms to ensure
  /// data persists across app relaunches and is not affected by external
  /// storage volatility on Android.
  static Future<Directory> getDocumentsDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    debugPrint('[FileUtils] Documents directory: ${dir.path}');
    return dir;
  }

  /// Get a file path in the downloads directory
  static Future<String> getDownloadFilePath(String fileName) async {
    final directory = await getDownloadsDirectory();
    final path = '${directory.path}/$fileName';
    debugPrint('[FileUtils] Download file path: $path');
    return path;
  }

  /// Get a file path in the documents directory
  static Future<String> getFilePath(String fileName) async {
    final directory = await getDocumentsDirectory();
    final path = '${directory.path}/$fileName';
    debugPrint('[FileUtils] File path resolved: $path');
    return path;
  }

  /// Check if a file exists
  static Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    final exists = await file.exists();
    debugPrint('[FileUtils] File exists check: $filePath -> $exists');
    return exists;
  }

  /// Delete a file if it exists
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('[FileUtils] Deleted file: $filePath');
        return true;
      }
      debugPrint('[FileUtils] File not found for deletion: $filePath');
      return false;
    } catch (e) {
      debugPrint('[FileUtils] Error deleting file: $filePath, error: $e');
      return false;
    }
  }

  /// Get file size in bytes
  static Future<int?> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final size = await file.length();
        debugPrint('[FileUtils] File size: $filePath -> $size bytes');
        return size;
      }
      debugPrint('[FileUtils] File not found for size check: $filePath');
      return null;
    } catch (e) {
      debugPrint('[FileUtils] Error getting file size: $filePath, error: $e');
      return null;
    }
  }

  /// Get a directory for storing container/item photos
  static Future<Directory> getPhotosDirectory() async {
    final documentsDir = await getDocumentsDirectory();
    final photosDir = Directory('${documentsDir.path}/photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
      debugPrint('[FileUtils] Created photos directory: ${photosDir.path}');
    }
    debugPrint('[FileUtils] Photos directory: ${photosDir.path}');
    return photosDir;
  }

  /// Get a file path for a photo
  static Future<String> getPhotoFilePath(String fileName) async {
    final directory = await getPhotosDirectory();
    final path = '${directory.path}/$fileName';
    debugPrint('[FileUtils] Photo file path resolved: $path');
    return path;
  }

  /// Copy a file to the photos directory
  static Future<String?> savePhoto(File sourceFile, String fileName) async {
    try {
      debugPrint('[FileUtils] Saving photo: $fileName from ${sourceFile.path}');
      final destPath = await getPhotoFilePath(fileName);
      final sourceExists = await sourceFile.exists();
      debugPrint('[FileUtils] Source file exists: $sourceExists');
      if (!sourceExists) {
        debugPrint('[FileUtils] Error: Source file does not exist: ${sourceFile.path}');
        return null;
      }
      await sourceFile.copy(destPath);
      final destFile = File(destPath);
      final destExists = await destFile.exists();
      debugPrint('[FileUtils] Photo saved: $destPath (verified: $destExists)');
      return destPath;
    } catch (e) {
      debugPrint('[FileUtils] Error saving photo: $fileName, error: $e');
      return null;
    }
  }
}
