import '../theme/app_theme_mode.dart';

/// Image Recognition Provider Options
enum ImageRecognitionProvider { tensorflowLite, mlKit }

/// Font scale options for accessibility
enum FontScaleOption {
  small, // 0.85
  normal, // 1.0
  large, // 1.15
  extraLarge, // 1.3
}

/// Extension for FontScaleOption
extension FontScaleOptionExtension on FontScaleOption {
  double get scale {
    switch (this) {
      case FontScaleOption.small:
        return 0.85;
      case FontScaleOption.normal:
        return 1.0;
      case FontScaleOption.large:
        return 1.15;
      case FontScaleOption.extraLarge:
        return 1.3;
    }
  }

  String get displayName {
    switch (this) {
      case FontScaleOption.small:
        return 'Small';
      case FontScaleOption.normal:
        return 'Normal';
      case FontScaleOption.large:
        return 'Large';
      case FontScaleOption.extraLarge:
        return 'Extra Large';
    }
  }
}

/// Image cache size options
enum ImageCacheSize {
  mb50, // 50 MB
  mb100, // 100 MB
  mb200, // 200 MB
  mb500, // 500 MB
}

/// Extension for ImageCacheSize
extension ImageCacheSizeExtension on ImageCacheSize {
  int get sizeInMB {
    switch (this) {
      case ImageCacheSize.mb50:
        return 50;
      case ImageCacheSize.mb100:
        return 100;
      case ImageCacheSize.mb200:
        return 200;
      case ImageCacheSize.mb500:
        return 500;
    }
  }

  String get displayName {
    switch (this) {
      case ImageCacheSize.mb50:
        return '50 MB';
      case ImageCacheSize.mb100:
        return '100 MB';
      case ImageCacheSize.mb200:
        return '200 MB';
      case ImageCacheSize.mb500:
        return '500 MB';
    }
  }
}

/// Application Settings Model
///
/// Stores user preferences for image recognition, appearance, storage, and other app features.
class AppSettings {
  // Image Recognition Settings
  final ImageRecognitionProvider imageRecognitionProvider;
  final double confidenceThreshold;
  final int maxTags;
  final bool useHeuristicFallback;

  // Appearance Settings
  final AppThemeMode themeMode;
  final FontScaleOption fontScale;
  final bool useDynamicType;

  // Storage Settings
  final String? defaultExportPath;
  final ImageCacheSize imageCacheSize;
  final bool clearCacheOnExit;

  // Timestamps
  final String createdAt;
  final String updatedAt;

  AppSettings({
    // Image Recognition defaults
    this.imageRecognitionProvider = ImageRecognitionProvider.tensorflowLite,
    this.confidenceThreshold = 0.3,
    this.maxTags = 5,
    this.useHeuristicFallback = true,
    // Appearance defaults
    this.themeMode = AppThemeMode.system,
    this.fontScale = FontScaleOption.normal,
    this.useDynamicType = true,
    // Storage defaults
    this.defaultExportPath,
    this.imageCacheSize = ImageCacheSize.mb100,
    this.clearCacheOnExit = false,
    // Timestamps
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppSettings.defaultSettings() {
    final now = DateTime.now().toIso8601String();
    return AppSettings(createdAt: now, updatedAt: now);
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      // Image Recognition
      imageRecognitionProvider: ImageRecognitionProvider.values.firstWhere(
        (e) => e.toString() == json['imageRecognitionProvider'],
        orElse: () => ImageRecognitionProvider.tensorflowLite,
      ),
      confidenceThreshold:
          (json['confidenceThreshold'] as num?)?.toDouble() ?? 0.3,
      maxTags: json['maxTags'] ?? 5,
      useHeuristicFallback: json['useHeuristicFallback'] ?? true,
      // Appearance
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => AppThemeMode.system,
      ),
      fontScale: FontScaleOption.values.firstWhere(
        (e) => e.name == json['fontScale'],
        orElse: () => FontScaleOption.normal,
      ),
      useDynamicType: json['useDynamicType'] ?? true,
      // Storage
      defaultExportPath: json['defaultExportPath'],
      imageCacheSize: ImageCacheSize.values.firstWhere(
        (e) => e.name == json['imageCacheSize'],
        orElse: () => ImageCacheSize.mb100,
      ),
      clearCacheOnExit: json['clearCacheOnExit'] ?? false,
      // Timestamps
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Image Recognition
      'imageRecognitionProvider': imageRecognitionProvider.toString(),
      'confidenceThreshold': confidenceThreshold,
      'maxTags': maxTags,
      'useHeuristicFallback': useHeuristicFallback,
      // Appearance
      'themeMode': themeMode.name,
      'fontScale': fontScale.name,
      'useDynamicType': useDynamicType,
      // Storage
      'defaultExportPath': defaultExportPath,
      'imageCacheSize': imageCacheSize.name,
      'clearCacheOnExit': clearCacheOnExit,
      // Timestamps
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  AppSettings copyWith({
    // Image Recognition
    ImageRecognitionProvider? imageRecognitionProvider,
    double? confidenceThreshold,
    int? maxTags,
    bool? useHeuristicFallback,
    // Appearance
    AppThemeMode? themeMode,
    FontScaleOption? fontScale,
    bool? useDynamicType,
    // Storage
    String? defaultExportPath,
    ImageCacheSize? imageCacheSize,
    bool? clearCacheOnExit,
  }) {
    return AppSettings(
      // Image Recognition
      imageRecognitionProvider:
          imageRecognitionProvider ?? this.imageRecognitionProvider,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      maxTags: maxTags ?? this.maxTags,
      useHeuristicFallback: useHeuristicFallback ?? this.useHeuristicFallback,
      // Appearance
      themeMode: themeMode ?? this.themeMode,
      fontScale: fontScale ?? this.fontScale,
      useDynamicType: useDynamicType ?? this.useDynamicType,
      // Storage
      defaultExportPath: defaultExportPath ?? this.defaultExportPath,
      imageCacheSize: imageCacheSize ?? this.imageCacheSize,
      clearCacheOnExit: clearCacheOnExit ?? this.clearCacheOnExit,
      // Timestamps
      createdAt: createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }
}
