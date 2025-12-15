import 'dart:convert';

/// Item Model
///
/// Represents an item stored within a container.
/// Items can have photos, tags, and optional 2D position for future map features.
class Item {
  /// Unique identifier for this item
  final String id;

  /// Item name
  final String name;

  /// Optional description
  final String? description;

  /// Parent container ID
  final String containerId;

  /// List of tags for categorization
  final List<String> tags;

  /// Optional path to item photo
  final String? photoPath;

  /// Creation timestamp in ISO 8601 format
  final String createdAt;

  /// Last update timestamp in ISO 8601 format
  final String updatedAt;

  /// Optional 2D X position (for future map enhancement)
  final double? positionX;

  /// Optional 2D Y position (for future map enhancement)
  final double? positionY;

  /// Constructor
  Item({
    required this.id,
    required this.name,
    this.description,
    required this.containerId,
    List<String>? tags,
    this.photoPath,
    required this.createdAt,
    required this.updatedAt,
    this.positionX,
    this.positionY,
  }) : tags = tags ?? [];

  /// Create Item from JSON
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      containerId: json['containerId'] as String,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : [],
      photoPath: json['photoPath'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      positionX: json['positionX'] != null
          ? (json['positionX'] as num).toDouble()
          : null,
      positionY: json['positionY'] != null
          ? (json['positionY'] as num).toDouble()
          : null,
    );
  }

  /// Convert Item to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'containerId': containerId,
      'tags': tags,
      if (photoPath != null) 'photoPath': photoPath,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (positionX != null) 'positionX': positionX,
      if (positionY != null) 'positionY': positionY,
    };
  }

  /// Convert Item to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create Item with current timestamps
  factory Item.create({
    String? id,
    required String name,
    String? description,
    required String containerId,
    List<String>? tags,
    String? photoPath,
    double? positionX,
    double? positionY,
  }) {
    final now = DateTime.now().toIso8601String();
    return Item(
      id: id ?? _generateId(),
      name: name,
      description: description,
      containerId: containerId,
      tags: tags,
      photoPath: photoPath,
      createdAt: now,
      updatedAt: now,
      positionX: positionX,
      positionY: positionY,
    );
  }

  /// Create a copy of this item with updated fields
  Item copyWith({
    String? id,
    String? name,
    String? description,
    String? containerId,
    List<String>? tags,
    String? photoPath,
    String? createdAt,
    String? updatedAt,
    double? positionX,
    double? positionY,
    bool? clearDescription,
    bool? clearPhotoPath,
    bool? clearPosition,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      description: clearDescription == true
          ? null
          : (description ?? this.description),
      containerId: containerId ?? this.containerId,
      tags: tags ?? this.tags,
      photoPath: clearPhotoPath == true
          ? null
          : (photoPath ?? this.photoPath),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
      positionX: clearPosition == true
          ? null
          : (positionX ?? this.positionX),
      positionY: clearPosition == true
          ? null
          : (positionY ?? this.positionY),
    );
  }

  /// Generate a reasonably unique ID without external dependencies
  static String _generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toString();
    final randomComponent = (timestamp.hashCode & 0xFFFFFF).toRadixString(16);
    return 'item-$timestamp-$randomComponent';
  }
}
