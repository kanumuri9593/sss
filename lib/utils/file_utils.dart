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

  /// Get the application documents directory
  static Future<Directory> getDocumentsDirectory() async {
    if (Platform.isAndroid) {
      return await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    } else {
      return await getApplicationDocumentsDirectory();
    }
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
}

