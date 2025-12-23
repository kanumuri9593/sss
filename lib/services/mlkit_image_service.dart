import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

/// Google ML Kit Image Recognition Service
///
/// Provides cloud-based image labeling using Google ML Kit.
/// Only available on iOS and Android platforms.
class MLKitImageService {
  static ImageLabeler? _labeler;
  static bool _isInitialized = false;
  static bool _isAvailable = false;

  /// Initialize ML Kit Image Labeler
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Check platform support (mobile only)
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('[MLKit] Platform not supported (web/desktop not supported)');
      _isAvailable = false;
      _isInitialized = true;
      return;
    }

    try {
      final options = ImageLabelerOptions(confidenceThreshold: 0.5);
      _labeler = ImageLabeler(options: options);
      _isAvailable = true;
      _isInitialized = true;
      debugPrint('[MLKit] Initialized successfully');
    } catch (e) {
      debugPrint('[MLKit] Initialization failed: $e');
      _isAvailable = false;
      _isInitialized = true;
    }
  }

  /// Check if ML Kit is available
  static bool get isAvailable => _isAvailable;

  /// Check if ML Kit is initialized
  static bool get isInitialized => _isInitialized;

  /// Process image and return tags
  static Future<List<String>> processImage(
    String imagePath, {
    double confidenceThreshold = 0.5,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isAvailable || _labeler == null) {
      debugPrint('[MLKit] Not available, returning empty list');
      return [];
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final labels = await _labeler!.processImage(inputImage);

      // Filter by confidence and convert to tags
      final tags = labels
          .where((label) => label.confidence >= confidenceThreshold)
          .map((label) => label.label.toLowerCase())
          .take(5)
          .toList();

      debugPrint('[MLKit] Generated ${tags.length} tags: $tags');
      return tags;
    } catch (e) {
      debugPrint('[MLKit] Error processing image: $e');
      return [];
    }
  }

  /// Get detailed label information with confidence scores
  static Future<List<Map<String, dynamic>>> processImageDetailed(
    String imagePath,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isAvailable || _labeler == null) {
      return [];
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final labels = await _labeler!.processImage(inputImage);

      return labels
          .map((label) => {
                'label': label.label.toLowerCase(),
                'confidence': label.confidence,
                'index': label.index,
              })
          .toList();
    } catch (e) {
      debugPrint('[MLKit] Error in detailed processing: $e');
      return [];
    }
  }

  /// Close the labeler and free resources
  static Future<void> close() async {
    await _labeler?.close();
    _labeler = null;
    _isInitialized = false;
    _isAvailable = false;
    debugPrint('[MLKit] Service closed');
  }
}
