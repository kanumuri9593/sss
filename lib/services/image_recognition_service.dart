import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

/// Image Recognition Service using Google ML Kit
///
/// Provides on-device image labeling for categorizing items and suggesting tags.
/// Low-cost, on-device processing with no cloud dependencies.
class ImageRecognitionService {
  static ImageLabeler? _labeler;

  /// Initialize the image labeler
  static Future<void> initialize() async {
    try {
      final options = ImageLabelerOptions(
        confidenceThreshold: 0.5, // Only return labels with 50%+ confidence
      );
      _labeler = ImageLabeler(options: options);
      debugPrint('[ImageRecognition] Image labeler initialized');
    } catch (e) {
      debugPrint('[ImageRecognition] Error initializing labeler: $e');
    }
  }

  /// Check if the service is initialized
  static bool get isInitialized => _labeler != null;

  /// Process an image file and return suggested tags
  ///
  /// Returns a list of tag suggestions based on detected objects/features in the image.
  /// Tags are formatted as lowercase strings suitable for use in the tagging system.
  static Future<List<String>> processImage(String imagePath) async {
    if (_labeler == null) {
      await initialize();
    }

    if (_labeler == null) {
      debugPrint('[ImageRecognition] Labeler not available');
      return [];
    }

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('[ImageRecognition] Image file not found: $imagePath');
        return [];
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final labels = await _labeler!.processImage(inputImage);

      // Extract tag suggestions from labels
      final suggestions = <String>[];
      for (final label in labels) {
        final labelText = label.label.toLowerCase().trim();
        if (labelText.isNotEmpty) {
          // Convert label to tag format (remove spaces, special chars)
          final tag = _formatTag(labelText);
          if (tag.isNotEmpty && !suggestions.contains(tag)) {
            suggestions.add(tag);
          }
        }
      }

      debugPrint('[ImageRecognition] Found ${suggestions.length} tag suggestions');
      return suggestions;
    } catch (e) {
      debugPrint('[ImageRecognition] Error processing image: $e');
      return [];
    }
  }

  /// Process an image file and return detailed label information
  ///
  /// Returns a list of ImageLabel objects with confidence scores.
  static Future<List<ImageLabel>> processImageDetailed(String imagePath) async {
    if (_labeler == null) {
      await initialize();
    }

    if (_labeler == null) {
      debugPrint('[ImageRecognition] Labeler not available');
      return [];
    }

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('[ImageRecognition] Image file not found: $imagePath');
        return [];
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final labels = await _labeler!.processImage(inputImage);

      debugPrint('[ImageRecognition] Found ${labels.length} labels');
      return labels;
    } catch (e) {
      debugPrint('[ImageRecognition] Error processing image: $e');
      return [];
    }
  }

  /// Get top N tag suggestions from an image
  ///
  /// Returns the top N most confident tag suggestions.
  static Future<List<String>> getTopTagSuggestions(
    String imagePath,
    int topN,
  ) async {
    final labels = await processImageDetailed(imagePath);

    // Sort by confidence (highest first)
    labels.sort((a, b) => b.confidence.compareTo(a.confidence));

    // Take top N and format as tags
    final suggestions = <String>[];
    for (final label in labels.take(topN)) {
      final tag = _formatTag(label.label.toLowerCase().trim());
      if (tag.isNotEmpty && !suggestions.contains(tag)) {
        suggestions.add(tag);
      }
    }

    return suggestions;
  }

  /// Format a label into a tag (lowercase, replace spaces with hyphens)
  static String _formatTag(String label) {
    return label
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove special chars except hyphens
        .replaceAll(RegExp(r'\s+'), '-') // Replace spaces with hyphens
        .replaceAll(RegExp(r'-+'), '-') // Replace multiple hyphens with single
        .replaceAll(RegExp(r'^-|-$'), ''); // Remove leading/trailing hyphens
  }

  /// Close the image labeler (free resources)
  static Future<void> close() async {
    await _labeler?.close();
    _labeler = null;
    debugPrint('[ImageRecognition] Service closed');
  }
}
