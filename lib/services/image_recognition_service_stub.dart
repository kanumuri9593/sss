import 'dart:io';
import 'package:flutter/foundation.dart';

/// Stub implementation when ML Kit is not available
/// This allows the app to compile and run without image recognition
class ImageRecognitionService {
  /// Initialize the image labeler (stub - always returns false)
  static Future<void> initialize() async {
    debugPrint('[ImageRecognition] Image recognition not available (dependency disabled for compatibility)');
  }

  /// Check if the service is initialized (stub - always returns false)
  static bool get isInitialized => false;

  /// Process an image file and return suggested tags (stub - returns empty list)
  static Future<List<String>> processImage(String imagePath) async {
    debugPrint('[ImageRecognition] Image recognition not available');
    return [];
  }

  /// Process an image file and return detailed label information (stub)
  static Future<List<dynamic>> processImageDetailed(String imagePath) async {
    debugPrint('[ImageRecognition] Image recognition not available');
    return [];
  }

  /// Get top N tag suggestions from an image (stub)
  static Future<List<String>> getTopTagSuggestions(
    String imagePath,
    int topN,
  ) async {
    debugPrint('[ImageRecognition] Image recognition not available');
    return [];
  }

  /// Close the image labeler (stub)
  static Future<void> close() async {
    debugPrint('[ImageRecognition] Service closed');
  }
}
