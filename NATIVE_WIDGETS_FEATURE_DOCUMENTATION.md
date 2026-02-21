# Native Widgets & OS Integration Feature Documentation

This document describes the native widgets and OS-level search integrations implemented for the SSS (Search & Scan Storage) app.

## Overview

The SSS app now includes deep native platform integrations that allow users to:
- **Home Screen Widgets**: Quick access to containers and search from home screen
- **Siri Shortcuts (iOS)**: Voice commands to search and access containers
- **Spotlight Search (iOS)**: Find containers and items from system search
- **Google Assistant/Gemini (Android)**: Voice-activated actions and search
- **App Shortcuts (Android)**: Quick actions from app icon long-press

## Features

### 1. Home Screen Widgets

#### iOS Widgets (WidgetKit)

Three widget sizes are available:

| Widget | Size | Description |
|--------|------|-------------|
| Quick Search | Small (2x2) | Quick access to search with container/item counts |
| Recent Containers | Medium (4x2) | Shows 3 most recent containers |
| Storage Stats | Large (4x3) | Full statistics overview |

**Location**: `ios/SSSWidget/SSSWidget.swift`

#### Android Widgets (AppWidget)

| Widget | Size | Description |
|--------|------|-------------|
| Quick Search | 2x2 cells | Search and QR scan access |
| Recent Containers | 4x2 cells | Shows 3 recent containers |
| Storage Stats | 4x3 cells | Statistics and breakdown |

**Location**: `android/app/src/main/kotlin/com/example/sss/SSSWidgetProvider.kt`

### 2. iOS Siri Integration

#### Siri Shortcuts

Users can set up voice commands for:
- "Search my containers" - Opens search screen
- "Scan storage QR" - Opens QR scanner
- "Scan storage tag" - Opens NFC scanner
- "Open [Container Name]" - Opens specific container

#### Siri Predictions

The app donates user activities to Siri, allowing iOS to predict and suggest:
- Recently viewed containers
- Frequently accessed search queries
- Common actions

**Service**: `lib/services/siri_spotlight_service.dart`

### 3. iOS Spotlight Search

All containers and items are indexed for system-wide search:

- **Containers**: Searchable by name, type, description, and tags
- **Items**: Searchable by name, description, and parent container

Users can find SSS content directly from:
- iOS Spotlight (swipe down on home screen)
- Siri suggestions
- Universal search

### 4. Android Google Assistant/Gemini Integration

#### App Actions

The app supports Android App Actions for voice commands:

| Intent | Example Phrases |
|--------|-----------------|
| `OPEN_APP_FEATURE` | "Open SSS search", "Scan QR with SSS" |
| `GET_THING` | "Find [item] in SSS", "Where is my [container]" |

#### Dynamic Shortcuts

Recent containers are exposed as dynamic shortcuts:
- Long-press app icon to see recent containers
- Shortcuts appear in Google Assistant suggestions
- Gemini can access these for AI-powered queries

**Service**: `lib/services/google_assistant_service.dart`

### 5. Deep Linking

Extended deep link support for widget and OS integration:

| URL Scheme | Description |
|------------|-------------|
| `sss://container/{id}` | Open specific container |
| `sss://search` | Open search screen |
| `sss://search?q={query}` | Search with query |
| `sss://scan/qr` | Open QR scanner |
| `sss://scan/nfc` | Open NFC scanner |
| `sss://stats` | Show statistics |
| `sss://containers` | Show container list |

## Implementation Details

### Flutter Services

```
lib/services/
├── widget_service.dart          # Home screen widget data management
├── siri_spotlight_service.dart  # iOS Siri & Spotlight integration
└── google_assistant_service.dart # Android Assistant integration
```

### iOS Native Code

```
ios/SSSWidget/
├── SSSWidget.swift         # Widget views and providers
├── Info.plist              # Widget extension config
└── SSSWidget.entitlements  # App group entitlements

ios/Runner/
├── Runner.entitlements     # Updated with App Groups & Siri
└── Info.plist              # Updated with Siri usage description
```

### Android Native Code

```
android/app/src/main/
├── kotlin/com/example/sss/
│   ├── MainActivity.kt          # Updated for intent handling
│   ├── SSSWidgetProvider.kt     # Widget providers
│   └── AssistantActionHandler.kt # Google Assistant handler
├── res/
│   ├── layout/
│   │   ├── widget_quick_search.xml
│   │   ├── widget_recent_containers.xml
│   │   └── widget_stats.xml
│   ├── drawable/
│   │   ├── widget_background_*.xml  # Widget backgrounds
│   │   └── ic_*.xml                  # Icons
│   └── xml/
│       ├── widget_*_info.xml        # Widget configurations
│       └── shortcuts.xml             # App shortcuts & actions
└── AndroidManifest.xml               # Updated with widgets & intents
```

## Setup Requirements

### iOS

1. **App Group**: Enable App Groups capability with `group.com.example.sss`
2. **Siri Capability**: Enable Siri capability in Xcode
3. **Widget Extension**: Add the SSSWidget target in Xcode

#### Adding Widget Extension in Xcode:
1. Open `ios/Runner.xcworkspace` in Xcode
2. File → New → Target → Widget Extension
3. Name it "SSSWidget"
4. Copy the Swift code from `ios/SSSWidget/`
5. Add to the same App Group

### Android

1. **Minimum SDK**: API 21+ (for widgets), API 25+ (for shortcuts)
2. **Build Configuration**: Ensure Kotlin is configured properly
3. **App Actions**: Create `shortcuts.xml` (already provided)

## Data Flow

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Flutter App   │────▶│  Widget Service  │────▶│  Native Widget  │
│                 │     │                  │     │   (iOS/Android) │
└─────────────────┘     └──────────────────┘     └─────────────────┘
        │                        │
        │                        ▼
        │               ┌──────────────────┐
        │               │    UserDefaults  │  (iOS App Group)
        │               │  SharedPrefs     │  (Android)
        │               └──────────────────┘
        │
        ▼
┌─────────────────┐     ┌──────────────────┐
│ Siri/Spotlight  │────▶│   Deep Links     │
│ Google Assist   │     │                  │
└─────────────────┘     └──────────────────┘
```

## Widget Data Updates

Widgets are updated:
1. **On app pause/resume**: Automatically refreshes widget data
2. **After CRUD operations**: Container/item changes trigger updates
3. **Periodic refresh**: Every 15 minutes (configurable)

## Testing

### iOS Widget Testing
```bash
# Run on iOS simulator
flutter run -d ios

# Add widget from home screen long-press
# Or use Control Center → Edit Home Screen
```

### Android Widget Testing
```bash
# Run on Android emulator/device
flutter run -d android

# Add widget: Long-press home screen → Widgets → SSS
```

### Siri Testing (iOS)
1. Open Settings → Siri & Search → SSS
2. Add shortcuts or use "Hey Siri, search my containers"

### Google Assistant Testing (Android)
1. Say "Hey Google, open SSS search"
2. Long-press app icon to see shortcuts
3. Use "OK Google, find [item] in SSS"

## Troubleshooting

### Widgets Not Updating
- Ensure App Group is configured correctly (iOS)
- Check SharedPreferences access (Android)
- Verify `WidgetService.updateAllWidgets()` is called

### Siri Not Working
- Check Siri capability is enabled
- Verify activity types in Info.plist
- Ensure `NSSiriUsageDescription` is set

### Google Assistant Not Responding
- Verify shortcuts.xml is properly configured
- Check intent filters in AndroidManifest.xml
- Ensure capability bindings are correct

## Dependencies

```yaml
# pubspec.yaml additions
dependencies:
  home_widget: ^0.8.1              # Home screen widgets
  flutter_siri_suggestions: ^2.1.0 # Siri integration
  flutter_core_spotlight: ^1.0.4   # Spotlight search
```

## Security Considerations

- Widget data is stored in App Group shared storage (iOS) or SharedPreferences (Android)
- Deep links validate container existence before navigation
- No sensitive data is exposed through widgets or shortcuts
- All OS integrations respect app authentication if implemented

## Future Enhancements

1. **Interactive Widgets (iOS 17+)**: Add buttons directly in widgets
2. **Lock Screen Widgets**: Display on lock screen (iOS 16+)
3. **Glance Widgets (Android)**: Jetpack Compose-based widgets
4. **Widget Configuration**: User-configurable widget content
5. **Gemini Extensions**: Deeper AI integration for natural language queries
