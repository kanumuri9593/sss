import 'dart:io';
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
        }
        return downloadsDir;
      }
      // Fallback to external storage root
      return externalDir ?? await getApplicationDocumentsDirectory();
    } else {
      // On iOS, use documents directory (accessible via Files app)
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Get the application documents directory for stable persistent storage
  ///
  /// Uses getApplicationDocumentsDirectory() on both platforms to ensure
  /// data persists across app relaunches and is not affected by external
  /// storage volatility on Android.
  static Future<Directory> getDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// Get a file path in the downloads directory
  static Future<String> getDownloadFilePath(String fileName) async {
    final directory = await getDownloadsDirectory();
    return '${directory.path}/$fileName';
  }

  /// Get a file path in the documents directory
  static Future<String> getFilePath(String fileName) async {
    final directory = await getDocumentsDirectory();
    return '${directory.path}/$fileName';
  }

  /// Check if a file exists
  static Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  /// Delete a file if it exists
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get file size in bytes
  static Future<int?> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get a directory for storing container/item photos
  static Future<Directory> getPhotosDirectory() async {
    final documentsDir = await getDocumentsDirectory();
    final photosDir = Directory('${documentsDir.path}/photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    return photosDir;
  }

  /// Get a file path for a photo
  static Future<String> getPhotoFilePath(String fileName) async {
    final directory = await getPhotosDirectory();
    return '${directory.path}/$fileName';
  }

  /// Copy a file to the photos directory
  static Future<String?> savePhoto(File sourceFile, String fileName) async {
    try {
      final destPath = await getPhotoFilePath(fileName);
      await sourceFile.copy(destPath);
      return destPath;
    } catch (e) {
      return null;
    }
  }
}

