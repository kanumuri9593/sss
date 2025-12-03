import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// File utilities for handling file operations
class FileUtils {
  /// Get the application documents directory
  static Future<Directory> getDocumentsDirectory() async {
    if (Platform.isAndroid) {
      return await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    } else {
      return await getApplicationDocumentsDirectory();
    }
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

