import 'dart:convert';

/// Model for NFC tag registration data
class NFCTagRegistration {
  final String title;
  final List<String> tags;
  final String description;
  final List<String> checklistItems;
  final DateTime createdAt;
  final DateTime? lastModified;

  NFCTagRegistration({
    required this.title,
    required this.tags,
    required this.description,
    required this.checklistItems,
    required this.createdAt,
    this.lastModified,
  });

  /// Convert to JSON string (to write to NFC tag)
  String toJsonString() {
    final map = {
      'title': title,
      'tags': tags,
      'description': description,
      'checklist': checklistItems,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
      'version': '1.0',
      'app': 'SSS',
    };
    return jsonEncode(map);
  }

  /// Create from JSON string (read from NFC tag)
  factory NFCTagRegistration.fromJsonString(String jsonString) {
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return NFCTagRegistration(
        title: map['title'] as String? ?? 'Untitled',
        tags: (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        description: map['description'] as String? ?? '',
        checklistItems: (map['checklist'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : DateTime.now(),
        lastModified: map['lastModified'] != null
            ? DateTime.parse(map['lastModified'] as String)
            : null,
      );
    } catch (e) {
      // If parsing fails, treat the entire string as a title
      return NFCTagRegistration(
        title: jsonString,
        tags: [],
        description: '',
        checklistItems: [],
        createdAt: DateTime.now(),
      );
    }
  }

  /// Create a copy with updated fields
  NFCTagRegistration copyWith({
    String? title,
    List<String>? tags,
    String? description,
    List<String>? checklistItems,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return NFCTagRegistration(
      title: title ?? this.title,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      checklistItems: checklistItems ?? this.checklistItems,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  /// Check if this appears to be our app's data format
  static bool isAppFormat(String data) {
    try {
      final map = jsonDecode(data) as Map<String, dynamic>;
      return map['app'] == 'SSS' && map['version'] != null;
    } catch (e) {
      return false;
    }
  }
}
