import 'dart:convert';

/// Container Type Enum
enum ContainerType {
  box,
  bag,
  drawer,
}

/// Container Model
///
/// Represents a physical container (box, bag, or drawer) that can hold items.
/// Supports nesting (containers within containers), QR/NFC linking, and tagging.
class Container {
  /// Unique identifier for this container
  final String id;

  /// Container name (e.g., "Winter Clothes Box")
  final String name;

  /// Type of container (box, bag, or drawer)
  final ContainerType type;

  /// Path to container photo
  final String? photoPath;

  /// Creation timestamp in ISO 8601 format
  final String createdAt;

  /// Last update timestamp in ISO 8601 format
  final String updatedAt;

  /// Optional linked QR code ID
  final String? qrCodeId;

  /// Optional linked NFC tag ID
  final String? nfcTagId;

  /// Optional parent container ID (for nesting)
  final String? parentContainerId;

  /// Optional description
  final String? description;

  /// List of tags for searchability
  final List<String> tags;

  /// Constructor
  Container({
    required this.id,
    required this.name,
    required this.type,
    this.photoPath,
    required this.createdAt,
    required this.updatedAt,
    this.qrCodeId,
    this.nfcTagId,
    this.parentContainerId,
    this.description,
    List<String>? tags,
  }) : tags = tags ?? [];

  /// Create Container from JSON
  factory Container.fromJson(Map<String, dynamic> json) {
    return Container(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ContainerType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ContainerType.box,
      ),
      photoPath: json['photoPath'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      qrCodeId: json['qrCodeId'] as String?,
      nfcTagId: json['nfcTagId'] as String?,
      parentContainerId: json['parentContainerId'] as String?,
      description: json['description'] as String?,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : [],
    );
  }

  /// Convert Container to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      if (photoPath != null) 'photoPath': photoPath,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (qrCodeId != null) 'qrCodeId': qrCodeId,
      if (nfcTagId != null) 'nfcTagId': nfcTagId,
      if (parentContainerId != null) 'parentContainerId': parentContainerId,
      if (description != null) 'description': description,
      'tags': tags,
    };
  }

  /// Convert Container to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create Container with current timestamps
  factory Container.create({
    String? id,
    required String name,
    required ContainerType type,
    String? photoPath,
    String? qrCodeId,
    String? nfcTagId,
    String? parentContainerId,
    String? description,
    List<String>? tags,
  }) {
    final now = DateTime.now().toIso8601String();
    return Container(
      id: id ?? _generateId(),
      name: name,
      type: type,
      photoPath: photoPath,
      createdAt: now,
      updatedAt: now,
      qrCodeId: qrCodeId,
      nfcTagId: nfcTagId,
      parentContainerId: parentContainerId,
      description: description,
      tags: tags,
    );
  }

  /// Create a copy of this container with updated fields
  Container copyWith({
    String? id,
    String? name,
    ContainerType? type,
    String? photoPath,
    String? createdAt,
    String? updatedAt,
    String? qrCodeId,
    String? nfcTagId,
    String? parentContainerId,
    String? description,
    List<String>? tags,
    bool? clearPhotoPath,
    bool? clearQrCodeId,
    bool? clearNfcTagId,
    bool? clearParentContainerId,
    bool? clearDescription,
  }) {
    return Container(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      photoPath: clearPhotoPath == true
          ? null
          : (photoPath ?? this.photoPath),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
      qrCodeId: clearQrCodeId == true
          ? null
          : (qrCodeId ?? this.qrCodeId),
      nfcTagId: clearNfcTagId == true
          ? null
          : (nfcTagId ?? this.nfcTagId),
      parentContainerId: clearParentContainerId == true
          ? null
          : (parentContainerId ?? this.parentContainerId),
      description: clearDescription == true
          ? null
          : (description ?? this.description),
      tags: tags ?? this.tags,
    );
  }

  /// Generate a reasonably unique ID without external dependencies
  static String _generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toString();
    final randomComponent = (timestamp.hashCode & 0xFFFFFF).toRadixString(16);
    return 'container-$timestamp-$randomComponent';
  }

  /// Build a deep link URL of the form: sss://container/[id]
  String buildDeepLink() {
    return 'sss://container/$id';
  }

  /// Check whether a string looks like a container deep link
  static bool isContainerDeepLink(String value) {
    return value.startsWith('sss://container/');
  }

  /// Attempt to extract the container id from a deep link URL
  static String? extractIdFromDeepLink(String value) {
    if (!isContainerDeepLink(value)) {
      return null;
    }
    try {
      final uri = Uri.parse(value);
      if (uri.scheme != 'sss') return null;
      if (uri.host != 'container') return null;
      final segments = uri.pathSegments;
      if (segments.isEmpty) return null;
      return segments.first;
    } catch (_) {
      return null;
    }
  }

  /// Get display icon for container type
  String get typeIcon {
    switch (type) {
      case ContainerType.box:
        return '📦';
      case ContainerType.bag:
        return '👜';
      case ContainerType.drawer:
        return '🗄️';
    }
  }

  /// Get display name for container type
  String get typeDisplayName {
    switch (type) {
      case ContainerType.box:
        return 'Box';
      case ContainerType.bag:
        return 'Bag';
      case ContainerType.drawer:
        return 'Drawer';
    }
  }
}
