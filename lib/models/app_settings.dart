/// Image Recognition Provider Options
enum ImageRecognitionProvider {
  tensorflowLite,
  mlKit,
}

/// Application Settings Model
///
/// Stores user preferences for image recognition and other app features.
class AppSettings {
  final ImageRecognitionProvider imageRecognitionProvider;
  final double confidenceThreshold;
  final int maxTags;
  final bool useHeuristicFallback;
  final String createdAt;
  final String updatedAt;

  AppSettings({
    this.imageRecognitionProvider = ImageRecognitionProvider.tensorflowLite,
    this.confidenceThreshold = 0.3,
    this.maxTags = 5,
    this.useHeuristicFallback = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppSettings.defaultSettings() {
    final now = DateTime.now().toIso8601String();
    return AppSettings(createdAt: now, updatedAt: now);
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      imageRecognitionProvider: ImageRecognitionProvider.values.firstWhere(
        (e) => e.toString() == json['imageRecognitionProvider'],
        orElse: () => ImageRecognitionProvider.tensorflowLite,
      ),
      confidenceThreshold: json['confidenceThreshold'] ?? 0.3,
      maxTags: json['maxTags'] ?? 5,
      useHeuristicFallback: json['useHeuristicFallback'] ?? true,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageRecognitionProvider': imageRecognitionProvider.toString(),
      'confidenceThreshold': confidenceThreshold,
      'maxTags': maxTags,
      'useHeuristicFallback': useHeuristicFallback,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  AppSettings copyWith({
    ImageRecognitionProvider? imageRecognitionProvider,
    double? confidenceThreshold,
    int? maxTags,
    bool? useHeuristicFallback,
  }) {
    return AppSettings(
      imageRecognitionProvider: imageRecognitionProvider ?? this.imageRecognitionProvider,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      maxTags: maxTags ?? this.maxTags,
      useHeuristicFallback: useHeuristicFallback ?? this.useHeuristicFallback,
      createdAt: createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }
}
