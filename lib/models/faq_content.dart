import 'package:flutter/material.dart';

/// FAQ Topic Categories
enum FAQTopic {
  gettingStarted,
  qrCodes,
  nfcTags,
  permissions,
  settings,
}

/// Extension for FAQTopic
extension FAQTopicExtension on FAQTopic {
  String get id {
    switch (this) {
      case FAQTopic.gettingStarted:
        return 'getting-started';
      case FAQTopic.qrCodes:
        return 'qr';
      case FAQTopic.nfcTags:
        return 'nfc';
      case FAQTopic.permissions:
        return 'permissions';
      case FAQTopic.settings:
        return 'settings';
    }
  }

  String get displayName {
    switch (this) {
      case FAQTopic.gettingStarted:
        return 'Getting Started';
      case FAQTopic.qrCodes:
        return 'QR Codes';
      case FAQTopic.nfcTags:
        return 'NFC Tags';
      case FAQTopic.permissions:
        return 'Permissions';
      case FAQTopic.settings:
        return 'Settings & Preferences';
    }
  }

  String get description {
    switch (this) {
      case FAQTopic.gettingStarted:
        return 'Learn the basics of using the app';
      case FAQTopic.qrCodes:
        return 'Generate and scan QR codes for containers';
      case FAQTopic.nfcTags:
        return 'Write and read NFC tags for quick access';
      case FAQTopic.permissions:
        return 'Manage app permissions and settings';
      case FAQTopic.settings:
        return 'Customize your app experience';
    }
  }

  IconData get icon {
    switch (this) {
      case FAQTopic.gettingStarted:
        return Icons.rocket_launch_rounded;
      case FAQTopic.qrCodes:
        return Icons.qr_code_rounded;
      case FAQTopic.nfcTags:
        return Icons.nfc_rounded;
      case FAQTopic.permissions:
        return Icons.shield_rounded;
      case FAQTopic.settings:
        return Icons.settings_rounded;
    }
  }

  String get emoji {
    switch (this) {
      case FAQTopic.gettingStarted:
        return '🚀';
      case FAQTopic.qrCodes:
        return '📱';
      case FAQTopic.nfcTags:
        return '📡';
      case FAQTopic.permissions:
        return '🛡️';
      case FAQTopic.settings:
        return '⚙️';
    }
  }

  static FAQTopic? fromId(String id) {
    for (final topic in FAQTopic.values) {
      if (topic.id == id) {
        return topic;
      }
    }
    return null;
  }
}

/// FAQ Action Type
enum FAQActionType {
  navigate, // In-app navigation
  openAppSettings, // Open system app settings
  openNFCSettings, // Open NFC settings (Android only)
  external, // External URL
}

/// FAQ Action Model
class FAQAction {
  final FAQActionType type;
  final String label;
  final String? route; // For navigate type
  final String? url; // For external type

  const FAQAction({
    required this.type,
    required this.label,
    this.route,
    this.url,
  });

  factory FAQAction.navigate(String label, String route) {
    return FAQAction(
      type: FAQActionType.navigate,
      label: label,
      route: route,
    );
  }

  factory FAQAction.openAppSettings(String label) {
    return FAQAction(
      type: FAQActionType.openAppSettings,
      label: label,
    );
  }

  factory FAQAction.openNFCSettings(String label) {
    return FAQAction(
      type: FAQActionType.openNFCSettings,
      label: label,
    );
  }

  factory FAQAction.external(String label, String url) {
    return FAQAction(
      type: FAQActionType.external,
      label: label,
      url: url,
    );
  }

  factory FAQAction.fromJson(Map<String, dynamic> json) {
    return FAQAction(
      type: FAQActionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FAQActionType.navigate,
      ),
      label: json['label'] ?? '',
      route: json['route'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'label': label,
      if (route != null) 'route': route,
      if (url != null) 'url': url,
    };
  }

  FAQAction copyWith({
    FAQActionType? type,
    String? label,
    String? route,
    String? url,
  }) {
    return FAQAction(
      type: type ?? this.type,
      label: label ?? this.label,
      route: route ?? this.route,
      url: url ?? this.url,
    );
  }
}

/// FAQ Guide Step Model
class FAQGuideStep {
  final int stepNumber;
  final String title;
  final String description;
  final IconData icon;
  final FAQAction? action;

  const FAQGuideStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
    this.action,
  });

  factory FAQGuideStep.fromJson(Map<String, dynamic> json) {
    return FAQGuideStep(
      stepNumber: json['stepNumber'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: IconData(
        json['iconCodePoint'] ?? Icons.help_rounded.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      action: json['action'] != null ? FAQAction.fromJson(json['action']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stepNumber': stepNumber,
      'title': title,
      'description': description,
      'iconCodePoint': icon.codePoint,
      if (action != null) 'action': action!.toJson(),
    };
  }

  FAQGuideStep copyWith({
    int? stepNumber,
    String? title,
    String? description,
    IconData? icon,
    FAQAction? action,
  }) {
    return FAQGuideStep(
      stepNumber: stepNumber ?? this.stepNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      action: action ?? this.action,
    );
  }
}

/// FAQ Content Model
class FAQContent {
  final FAQTopic topic;
  final List<FAQGuideStep> steps;

  const FAQContent({
    required this.topic,
    required this.steps,
  });

  factory FAQContent.fromJson(Map<String, dynamic> json) {
    return FAQContent(
      topic: FAQTopic.values.firstWhere(
        (e) => e.name == json['topic'],
        orElse: () => FAQTopic.gettingStarted,
      ),
      steps: (json['steps'] as List<dynamic>?)
              ?.map((step) => FAQGuideStep.fromJson(step))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topic': topic.name,
      'steps': steps.map((step) => step.toJson()).toList(),
    };
  }

  FAQContent copyWith({
    FAQTopic? topic,
    List<FAQGuideStep>? steps,
  }) {
    return FAQContent(
      topic: topic ?? this.topic,
      steps: steps ?? this.steps,
    );
  }

  /// Static FAQ Content Definitions
  static final List<FAQContent> allContent = [
    _gettingStartedContent,
    _qrCodesContent,
    _nfcTagsContent,
    _permissionsContent,
    _settingsContent,
  ];

  static FAQContent? getContentForTopic(FAQTopic topic) {
    try {
      return allContent.firstWhere((content) => content.topic == topic);
    } catch (e) {
      return null;
    }
  }

  static FAQContent? getContentById(String topicId) {
    final topic = FAQTopicExtension.fromId(topicId);
    if (topic == null) return null;
    return getContentForTopic(topic);
  }

  /// Getting Started Content
  static const FAQContent _gettingStartedContent = FAQContent(
    topic: FAQTopic.gettingStarted,
    steps: [
      FAQGuideStep(
        stepNumber: 1,
        title: 'Welcome to SSS',
        description:
            'Search & Scan is your digital organization assistant. Store items in containers, tag them with QR codes or NFC tags, and find them instantly.',
        icon: Icons.waving_hand_rounded,
      ),
      FAQGuideStep(
        stepNumber: 2,
        title: 'Create Your First Container',
        description:
            'Tap the + button on the home screen to create a container. Give it a name and description, then start adding items.',
        icon: Icons.add_box_rounded,
        action: const FAQAction(
          type: FAQActionType.navigate,
          label: 'Go to Home',
          route: '/',
        ),
      ),
      FAQGuideStep(
        stepNumber: 3,
        title: 'Add Items to Containers',
        description:
            'Open a container and tap "Add Item" to create entries. Use the camera to capture images and let AI suggest tags automatically.',
        icon: Icons.inventory_2_rounded,
      ),
      FAQGuideStep(
        stepNumber: 4,
        title: 'Search Your Items',
        description:
            'Use the search bar to find items across all containers. Search by name, tags, or description for instant results.',
        icon: Icons.search_rounded,
        action: const FAQAction(
          type: FAQActionType.navigate,
          label: 'Open Search',
          route: '/search',
        ),
      ),
    ],
  );

  /// QR Codes Content
  static const FAQContent _qrCodesContent = FAQContent(
    topic: FAQTopic.qrCodes,
    steps: [
      FAQGuideStep(
        stepNumber: 1,
        title: 'What are QR Codes?',
        description:
            'QR codes are scannable barcodes that store information. In SSS, each container can have a QR code for quick access.',
        icon: Icons.qr_code_2_rounded,
      ),
      FAQGuideStep(
        stepNumber: 2,
        title: 'Generate a Container QR Code',
        description:
            'Open any container, tap the QR icon, and generate a unique code. You can save or print this code to attach to physical containers.',
        icon: Icons.qr_code_scanner_rounded,
      ),
      FAQGuideStep(
        stepNumber: 3,
        title: 'Scan QR Codes',
        description:
            'Tap the scan button on the home screen or use the camera permission to scan QR codes and instantly open the linked container.',
        icon: Icons.camera_alt_rounded,
        action: const FAQAction(
          type: FAQActionType.navigate,
          label: 'Open Scanner',
          route: '/scan',
        ),
      ),
      FAQGuideStep(
        stepNumber: 4,
        title: 'Share QR Codes',
        description:
            'Share container QR codes with family or colleagues via messaging apps, email, or by printing them out.',
        icon: Icons.share_rounded,
      ),
    ],
  );

  /// NFC Tags Content
  static const FAQContent _nfcTagsContent = FAQContent(
    topic: FAQTopic.nfcTags,
    steps: [
      FAQGuideStep(
        stepNumber: 1,
        title: 'What is NFC?',
        description:
            'NFC (Near Field Communication) lets you tap your phone on physical tags to instantly access containers. It\'s like a digital shortcut.',
        icon: Icons.contactless_rounded,
      ),
      FAQGuideStep(
        stepNumber: 2,
        title: 'Check Device Support',
        description:
            'Most modern Android phones have NFC. iPhones (7+) support reading NFC tags. Check your device settings to confirm.',
        icon: Icons.phone_android_rounded,
      ),
      FAQGuideStep(
        stepNumber: 3,
        title: 'Enable NFC',
        description:
            'On Android, go to Settings > Connected Devices > Connection Preferences > NFC and turn it on. On iOS, NFC is always enabled.',
        icon: Icons.settings_rounded,
        action: const FAQAction(
          type: FAQActionType.openNFCSettings,
          label: 'Open NFC Settings',
        ),
      ),
      FAQGuideStep(
        stepNumber: 4,
        title: 'Write Container Info to NFC Tag',
        description:
            'Open a container, tap the NFC icon, and hold your phone near a blank NFC tag. The container link will be written to the tag.',
        icon: Icons.nfc_rounded,
      ),
      FAQGuideStep(
        stepNumber: 5,
        title: 'Read NFC Tags',
        description:
            'Simply tap your phone on a programmed NFC tag to instantly open the linked container. No app opening required!',
        icon: Icons.touch_app_rounded,
      ),
    ],
  );

  /// Permissions Content
  static const FAQContent _permissionsContent = FAQContent(
    topic: FAQTopic.permissions,
    steps: [
      FAQGuideStep(
        stepNumber: 1,
        title: 'Why Permissions Matter',
        description:
            'SSS needs certain permissions to provide full functionality. Camera for QR scanning, storage for images, and NFC for tag reading.',
        icon: Icons.verified_user_rounded,
      ),
      FAQGuideStep(
        stepNumber: 2,
        title: 'Camera Permission',
        description:
            'Required for scanning QR codes and capturing item images. You\'ll be prompted when first using these features.',
        icon: Icons.camera_rounded,
      ),
      FAQGuideStep(
        stepNumber: 3,
        title: 'Storage Permission',
        description:
            'Needed to save and load item images. Modern Android uses scoped storage for enhanced privacy.',
        icon: Icons.folder_rounded,
      ),
      FAQGuideStep(
        stepNumber: 4,
        title: 'Manage Permissions',
        description:
            'You can review and change app permissions anytime in your device settings. Tap below to open app settings.',
        icon: Icons.admin_panel_settings_rounded,
        action: const FAQAction(
          type: FAQActionType.openAppSettings,
          label: 'Open App Settings',
        ),
      ),
    ],
  );

  /// Settings & Preferences Content
  static const FAQContent _settingsContent = FAQContent(
    topic: FAQTopic.settings,
    steps: [
      FAQGuideStep(
        stepNumber: 1,
        title: 'Theme Settings',
        description:
            'Choose between light, dark, or system theme. The app adapts to your preference with beautiful glassmorphism design.',
        icon: Icons.palette_rounded,
        action: const FAQAction(
          type: FAQActionType.navigate,
          label: 'Open Settings',
          route: '/profile',
        ),
      ),
      FAQGuideStep(
        stepNumber: 2,
        title: 'Image Recognition Settings',
        description:
            'Configure AI tag suggestions, confidence threshold, and max tags per item. Choose between TensorFlow Lite or ML Kit.',
        icon: Icons.psychology_rounded,
        action: const FAQAction(
          type: FAQActionType.navigate,
          label: 'Open Settings',
          route: '/profile',
        ),
      ),
      FAQGuideStep(
        stepNumber: 3,
        title: 'Storage Management',
        description:
            'Set image cache size, choose default export paths, and manage storage usage. Clear cache to free up space.',
        icon: Icons.storage_rounded,
        action: const FAQAction(
          type: FAQActionType.navigate,
          label: 'Open Settings',
          route: '/profile',
        ),
      ),
      FAQGuideStep(
        stepNumber: 4,
        title: 'Accessibility',
        description:
            'Adjust font sizes for better readability. Choose from Small, Normal, Large, or Extra Large text scaling.',
        icon: Icons.accessibility_new_rounded,
        action: const FAQAction(
          type: FAQActionType.navigate,
          label: 'Open Settings',
          route: '/profile',
        ),
      ),
    ],
  );
}
