import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Model for stored NFC tag registration linked to a container
class NFCTagStoredRegistration {
  final String id;
  final String tagId; // Physical NFC tag ID
  final String? containerId; // Linked container ID
  final String? containerName; // Cached container name
  final String title;
  final String description;
  final List<String> tags;
  final String deepLink; // Generated deep link
  final DateTime createdAt;
  final DateTime? lastModified;
  final NFCTagStatus status;

  NFCTagStoredRegistration({
    required this.id,
    required this.tagId,
    this.containerId,
    this.containerName,
    required this.title,
    required this.description,
    required this.tags,
    required this.deepLink,
    required this.createdAt,
    this.lastModified,
    this.status = NFCTagStatus.active,
  });

  factory NFCTagStoredRegistration.fromJson(Map<String, dynamic> json) {
    return NFCTagStoredRegistration(
      id: json['id'] as String,
      tagId: json['tagId'] as String,
      containerId: json['containerId'] as String?,
      containerName: json['containerName'] as String?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      deepLink: json['deepLink'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
      status: NFCTagStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => NFCTagStatus.active,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tagId': tagId,
      'containerId': containerId,
      'containerName': containerName,
      'title': title,
      'description': description,
      'tags': tags,
      'deepLink': deepLink,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
      'status': status.name,
    };
  }

  NFCTagStoredRegistration copyWith({
    String? id,
    String? tagId,
    String? containerId,
    String? containerName,
    String? title,
    String? description,
    List<String>? tags,
    String? deepLink,
    DateTime? createdAt,
    DateTime? lastModified,
    NFCTagStatus? status,
    bool clearContainerId = false,
  }) {
    return NFCTagStoredRegistration(
      id: id ?? this.id,
      tagId: tagId ?? this.tagId,
      containerId: clearContainerId ? null : (containerId ?? this.containerId),
      containerName: clearContainerId
          ? null
          : (containerName ?? this.containerName),
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      deepLink: deepLink ?? this.deepLink,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      status: status ?? this.status,
    );
  }
}

/// Status of an NFC tag registration
enum NFCTagStatus {
  active, // Tag is in use
  inactive, // Tag is disabled but not deleted
  pending, // Tag is pending write
  error, // Tag has an error
}

/// Service for storing and managing NFC tag registrations
class NFCTagStorageService {
  static const String _boxName = 'nfc_tags';
  static Box<String>? _box;

  /// Initialize the storage service.
  /// Returns true if initialization was successful, false otherwise.
  static Future<bool> initialize() async {
    try {
      if (_box != null && _box!.isOpen) {
        return true;
      }
      if (!Hive.isBoxOpen(_boxName)) {
        _box = await Hive.openBox<String>(_boxName);
      } else {
        _box = Hive.box<String>(_boxName);
      }
      debugPrint('[NFCTagStorage] Initialized with ${_box?.length ?? 0} tags');
      return true;
    } catch (e) {
      debugPrint('[NFCTagStorage] Error initializing: $e');
      return false;
    }
  }

  /// Get the storage box
  static Box<String> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError(
        'NFCTagStorageService not initialized. Call initialize() first.',
      );
    }
    return _box!;
  }

  /// Save a new NFC tag registration
  static Future<NFCTagStoredRegistration> saveTag(
    NFCTagStoredRegistration tag,
  ) async {
    try {
      final json = jsonEncode(tag.toJson());
      await box.put(tag.id, json);
      await box.flush();
      debugPrint('[NFCTagStorage] Saved tag: ${tag.id}');
      return tag;
    } catch (e) {
      debugPrint('[NFCTagStorage] Error saving tag: $e');
      rethrow;
    }
  }

  /// Get a tag by ID
  static NFCTagStoredRegistration? getTagById(String id) {
    try {
      final json = box.get(id);
      if (json == null) return null;
      return NFCTagStoredRegistration.fromJson(jsonDecode(json));
    } catch (e) {
      debugPrint('[NFCTagStorage] Error getting tag by ID: $e');
      return null;
    }
  }

  /// Get a tag by physical NFC tag ID
  static NFCTagStoredRegistration? getTagByPhysicalId(String physicalTagId) {
    try {
      for (final key in box.keys) {
        final json = box.get(key);
        if (json != null) {
          final tag = NFCTagStoredRegistration.fromJson(jsonDecode(json));
          if (tag.tagId == physicalTagId) {
            return tag;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('[NFCTagStorage] Error getting tag by physical ID: $e');
      return null;
    }
  }

  /// Get all tags linked to a container
  static List<NFCTagStoredRegistration> getTagsByContainerId(
    String containerId,
  ) {
    try {
      final tags = <NFCTagStoredRegistration>[];
      for (final key in box.keys) {
        final json = box.get(key);
        if (json != null) {
          final tag = NFCTagStoredRegistration.fromJson(jsonDecode(json));
          if (tag.containerId == containerId) {
            tags.add(tag);
          }
        }
      }
      return tags;
    } catch (e) {
      debugPrint('[NFCTagStorage] Error getting tags by container: $e');
      return [];
    }
  }

  /// Get all registered tags
  static List<NFCTagStoredRegistration> getAllTags() {
    try {
      final tags = <NFCTagStoredRegistration>[];
      for (final key in box.keys) {
        final json = box.get(key);
        if (json != null) {
          tags.add(NFCTagStoredRegistration.fromJson(jsonDecode(json)));
        }
      }
      // Sort by creation date (newest first)
      tags.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tags;
    } catch (e) {
      debugPrint('[NFCTagStorage] Error getting all tags: $e');
      return [];
    }
  }

  /// Update an existing tag
  static Future<NFCTagStoredRegistration?> updateTag(
    NFCTagStoredRegistration tag,
  ) async {
    try {
      if (!box.containsKey(tag.id)) {
        debugPrint('[NFCTagStorage] Tag not found: ${tag.id}');
        return null;
      }
      final updated = tag.copyWith(lastModified: DateTime.now());
      final json = jsonEncode(updated.toJson());
      await box.put(tag.id, json);
      await box.flush();
      debugPrint('[NFCTagStorage] Updated tag: ${tag.id}');
      return updated;
    } catch (e) {
      debugPrint('[NFCTagStorage] Error updating tag: $e');
      return null;
    }
  }

  /// Delete a tag
  static Future<bool> deleteTag(String id) async {
    try {
      if (!box.containsKey(id)) {
        debugPrint('[NFCTagStorage] Tag not found: $id');
        return false;
      }
      await box.delete(id);
      await box.flush();
      debugPrint('[NFCTagStorage] Deleted tag: $id');
      return true;
    } catch (e) {
      debugPrint('[NFCTagStorage] Error deleting tag: $e');
      return false;
    }
  }

  /// Link a tag to a container
  static Future<bool> linkTagToContainer(
    String tagId,
    String containerId,
    String? containerName,
  ) async {
    try {
      final tag = getTagById(tagId);
      if (tag == null) {
        debugPrint('[NFCTagStorage] Tag not found: $tagId');
        return false;
      }
      final updated = tag.copyWith(
        containerId: containerId,
        containerName: containerName,
        lastModified: DateTime.now(),
      );
      await saveTag(updated);
      return true;
    } catch (e) {
      debugPrint('[NFCTagStorage] Error linking tag to container: $e');
      return false;
    }
  }

  /// Unlink a tag from its container
  static Future<bool> unlinkTagFromContainer(String tagId) async {
    try {
      final tag = getTagById(tagId);
      if (tag == null) {
        debugPrint('[NFCTagStorage] Tag not found: $tagId');
        return false;
      }
      final updated = tag.copyWith(
        clearContainerId: true,
        lastModified: DateTime.now(),
      );
      await saveTag(updated);
      return true;
    } catch (e) {
      debugPrint('[NFCTagStorage] Error unlinking tag from container: $e');
      return false;
    }
  }

  /// Check if a physical tag ID is already registered
  static bool isPhysicalTagRegistered(String physicalTagId) {
    return getTagByPhysicalId(physicalTagId) != null;
  }

  /// Generate a unique registration ID
  static String generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toString();
    final randomComponent = (timestamp.hashCode & 0xFFFFFF).toRadixString(16);
    return 'nfc-$timestamp-$randomComponent';
  }
}
