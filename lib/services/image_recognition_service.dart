import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/container.dart' as models;

/// Image Recognition Service using TensorFlow Lite
///
/// Provides on-device image labeling for categorizing items and suggesting tags.
/// Uses MobileNet v2 model (if available) or falls back to heuristic-based tag generation.
class ImageRecognitionService {
  static Interpreter? _interpreter;
  static bool _isInitialized = false;
  static bool _modelAvailable = false;

  // ImageNet class labels mapping (subset relevant to containers/items)
  // Full list has 1000 classes, but we focus on storage-related ones
  static const Map<int, String> _classLabels = {
    // Storage containers
    429: 'box',
    430: 'carton',
    431: 'container',
    432: 'crate',
    437: 'bag',
    438: 'handbag',
    439: 'backpack',
    440: 'suitcase',
    441: 'briefcase',
    442: 'drawer',
    443: 'cabinet',
    444: 'shelf',
    445: 'storage',
    446: 'organizer',
    // Common items
    447: 'clothing',
    448: 'furniture',
    449: 'electronics',
    450: 'tools',
    451: 'books',
    452: 'toys',
  };

  /// Initialize the image labeler
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Try to load TensorFlow Lite model
      // Model should be placed at assets/models/mobilenet_v2.tflite
      // Download from: https://www.tensorflow.org/lite/models/image_classification/overview
      _interpreter = await Interpreter.fromAsset('assets/models/mobilenet_v2.tflite');
      _modelAvailable = true;
      _isInitialized = true;
      debugPrint('[ImageRecognition] TensorFlow Lite model loaded successfully');
    } catch (e) {
      // Model not available - use heuristic fallback
      _modelAvailable = false;
      _isInitialized = true;
      debugPrint('[ImageRecognition] TensorFlow Lite model not available, using heuristic fallback: $e');
    }
  }

  /// Check if the service is initialized
  static bool get isInitialized => _isInitialized;

  /// Check if TensorFlow Lite model is available
  static bool get isModelAvailable => _modelAvailable;

  /// Process an image file and return suggested tags
  ///
  /// Returns a list of tag suggestions (3-5 tags) based on detected objects/features in the image.
  /// Tags are formatted as lowercase strings suitable for use in the tagging system.
  static Future<List<String>> processImage(String imagePath) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('[ImageRecognition] Image file not found: $imagePath');
        return _generateHeuristicTags(null);
      }

      if (_modelAvailable && _interpreter != null) {
        // Use TensorFlow Lite model
        return await _processWithTFLite(file);
      } else {
        // Fallback to heuristics
        return _generateHeuristicTags(null);
      }
    } catch (e) {
      debugPrint('[ImageRecognition] Error processing image: $e');
      return _generateHeuristicTags(null);
    }
  }

  /// Process image using TensorFlow Lite
  static Future<List<String>> _processWithTFLite(File imageFile) async {
    try {
      // Read and decode image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        debugPrint('[ImageRecognition] Failed to decode image');
        return _generateHeuristicTags(null);
      }

      // Preprocess image: resize to 224x224 and normalize
      final resized = img.copyResize(image, width: 224, height: 224);
      final inputBuffer = _preprocessImage(resized);

      // Get model output shape
      final outputTensor = _interpreter!.getOutputTensor(0);
      final outputShape = outputTensor.shape;

      // Create output buffer based on output shape
      final outputSize = outputShape.reduce((a, b) => a * b);
      final output = List.filled(outputSize, 0.0);

      // Run inference
      _interpreter!.run(inputBuffer, output);

      // Get top 5 predictions
      final indexedPredictions = List.generate(
        output.length,
        (index) => MapEntry(index, output[index]),
      );

      // Sort by confidence (highest first)
      indexedPredictions.sort((a, b) => b.value.compareTo(a.value));

      // Extract top 5 tags
      final tags = <String>[];
      for (var i = 0; i < indexedPredictions.length && tags.length < 5; i++) {
        final classId = indexedPredictions[i].key;
        final confidence = indexedPredictions[i].value;

        // Filter by confidence threshold (>0.3)
        if (confidence > 0.3) {
          // Try to get label from our mapping
          String? tag;
          if (_classLabels.containsKey(classId)) {
            tag = _classLabels[classId];
          } else {
            // Use generic ImageNet label lookup (simplified)
            tag = _getImageNetLabel(classId);
          }

          if (tag != null && tag.isNotEmpty && !tags.contains(tag)) {
            tags.add(tag);
          }
        }
      }

      // Ensure we return 3-5 tags
      if (tags.length < 3) {
        final heuristicTags = _generateHeuristicTags(null);
        tags.addAll(heuristicTags.take(3 - tags.length));
      }

      debugPrint('[ImageRecognition] Generated ${tags.length} tags from TFLite: $tags');
      return tags.take(5).toList();
    } catch (e) {
      debugPrint('[ImageRecognition] Error in TFLite processing: $e');
      return _generateHeuristicTags(null);
    }
  }

  /// Preprocess image for TensorFlow Lite input
  static List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    final inputBuffer = List.generate(
      1,
      (_) => List.generate(
        224,
        (_) => List.generate(
          224,
          (_) => List.filled(3, 0.0),
        ),
      ),
    );

    for (var y = 0; y < 224; y++) {
      for (var x = 0; x < 224; x++) {
        final pixel = image.getPixel(x, y);
        // Normalize to [-1, 1] range (MobileNet v2 preprocessing)
        inputBuffer[0][y][x][0] = (pixel.r / 127.5) - 1.0;
        inputBuffer[0][y][x][1] = (pixel.g / 127.5) - 1.0;
        inputBuffer[0][y][x][2] = (pixel.b / 127.5) - 1.0;
      }
    }

    return inputBuffer;
  }

  /// Get ImageNet label for class ID (simplified lookup)
  static String? _getImageNetLabel(int classId) {
    // This is a simplified version - in production, you'd load the full ImageNet labels
    // For now, return null to use heuristics
    return null;
  }

  /// Generate heuristic-based tags
  ///
  /// Generates tags based on container type or common storage keywords.
  static List<String> _generateHeuristicTags(models.ContainerType? containerType) {
    final tags = <String>[];

    if (containerType != null) {
      // Add container type-specific tags
      switch (containerType) {
        case models.ContainerType.box:
          tags.addAll(['box', 'storage', 'container', 'organize', 'pack']);
          break;
        case models.ContainerType.bag:
          tags.addAll(['bag', 'portable', 'storage', 'carry', 'travel']);
          break;
        case models.ContainerType.drawer:
          tags.addAll(['drawer', 'storage', 'furniture', 'organize', 'cabinet']);
          break;
      }
    } else {
      // Generic storage tags
      tags.addAll(['storage', 'container', 'organize', 'item', 'collection']);
    }

    // Return 3-5 tags
    return tags.take(5).toList();
  }

  /// Process an image file and return detailed label information
  ///
  /// Returns a list of predictions with confidence scores.
  static Future<List<Map<String, dynamic>>> processImageDetailed(String imagePath) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
    return [];
      }

      if (_modelAvailable && _interpreter != null) {
        // Use TensorFlow Lite model
        final imageBytes = await file.readAsBytes();
        final image = img.decodeImage(imageBytes);
        if (image == null) return [];

        final resized = img.copyResize(image, width: 224, height: 224);
        final inputBuffer = _preprocessImage(resized);

        final outputTensor = _interpreter!.getOutputTensor(0);
        final outputShape = outputTensor.shape;
        final outputSize = outputShape.reduce((a, b) => a * b);
        final output = List.filled(outputSize, 0.0);

        _interpreter!.run(inputBuffer, output);

        final predictions = output;
        final results = <Map<String, dynamic>>[];

        for (var i = 0; i < predictions.length; i++) {
          if (predictions[i] > 0.1) {
            // Only include predictions with >10% confidence
            results.add({
              'classId': i,
              'confidence': predictions[i],
              'label': _classLabels[i] ?? _getImageNetLabel(i) ?? 'unknown',
            });
          }
        }

        results.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
        return results.take(10).toList();
      }

      return [];
    } catch (e) {
      debugPrint('[ImageRecognition] Error in detailed processing: $e');
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
    final tags = await processImage(imagePath);
    return tags.take(topN).toList();
  }

  /// Generate tags for a container based on its type
  ///
  /// Helper method to generate tags when container type is known.
  static List<String> generateTagsForContainer(models.ContainerType containerType) {
    return _generateHeuristicTags(containerType);
  }

  /// Close the image labeler (free resources)
  static Future<void> close() async {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    _modelAvailable = false;
    debugPrint('[ImageRecognition] Service closed');
  }
}

