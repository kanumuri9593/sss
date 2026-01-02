# Specification: Simple Unique Profile/Settings Screen

## Overview

Build a simple yet visually unique profile and settings screen for the SSS (Search & Scan) Flutter application. This screen will serve as a centralized hub where users can view their profile information, customize app preferences, and manage settings. The design should be distinctive and modern while maintaining consistency with the existing app theme system. Since there's already a basic settings screen focused on image recognition (`settings_screen.dart`), this new screen will consolidate all settings into a comprehensive profile experience with unique visual elements like gradient headers, animated cards, and a cohesive user profile section.

## Workflow Type

**Type**: feature

**Rationale**: This is a net-new feature that adds user-facing functionality to the app. It requires creating new UI components, potentially extending the data model, and integrating with existing navigation patterns. The task involves multiple new files and integration points.

## Task Scope

### Services Involved
- **sss (flutter)** (primary) - Main Flutter application codebase

### This Task Will:
- [ ] Create a new `ProfileScreen` widget in `lib/screens/`
- [ ] Design a unique profile header with user avatar/initials and gradient background
- [ ] Add profile-related settings (display name, theme preference, notifications)
- [ ] Integrate existing image recognition settings from `settings_screen.dart`
- [ ] Add app info section (version, about, feedback)
- [ ] Create visually distinctive UI elements (gradient cards, animated sections)
- [ ] Update navigation to include profile access (likely in main tab or app bar)
- [ ] Extend `AppSettings` model if needed for new user preferences

### Out of Scope:
- Backend user authentication/login system
- Cloud sync of user preferences
- User account management (signup/login)
- Push notification infrastructure (just settings toggle)
- Profile picture upload to cloud storage

## Service Context

### SSS Flutter App

**Tech Stack:**
- Language: Dart
- Framework: Flutter 3.x with Material Design 3
- State Management: StatefulWidget (local state)
- Storage: Hive (local persistence)
- Key directories: `lib/screens/`, `lib/services/`, `lib/models/`, `lib/theme/`, `lib/widgets/`

**Entry Point:** `lib/main.dart`

**How to Run:**
```bash
flutter run
```

**Port:** N/A (Mobile app - runs on emulator/device)

## Files to Modify

| File | Service | What to Change |
|------|---------|---------------|
| `lib/screens/profile_screen.dart` | sss | Create new profile screen with unique UI |
| `lib/models/app_settings.dart` | sss | Add profile-related fields (displayName, themeMode, notificationsEnabled) |
| `lib/models/app_settings_adapter.dart` | sss | Update Hive adapter for new fields |
| `lib/services/preferences_service.dart` | sss | Add methods for profile-specific operations |
| `lib/screens/main_tab_screen.dart` | sss | Add profile tab or navigation action |
| `lib/main.dart` | sss | Ensure PreferencesService is initialized |

## Files to Reference

These files show patterns to follow:

| File | Pattern to Copy |
|------|----------------|
| `lib/screens/settings_screen.dart` | Settings screen structure, PreferencesService usage, ListTile patterns |
| `lib/screens/container_detail_screen.dart` | Detail screen layout, card structures |
| `lib/theme/app_theme.dart` | Theme color access, gradient definitions |
| `lib/theme/tokens/app_gradients.dart` | Gradient patterns for unique visual elements |
| `lib/models/app_settings.dart` | Model structure with copyWith, Hive integration |
| `lib/widgets/container_card.dart` | Card widget patterns, gradient decorations |

## Patterns to Follow

### Screen Structure Pattern

From `lib/screens/settings_screen.dart`:

```dart
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = PreferencesService.settings;
  }

  void _updateSettings(AppSettings newSettings) async {
    setState(() {
      _settings = newSettings;
    });
    await PreferencesService.updateSettings(newSettings);
  }
  // ...
}
```

**Key Points:**
- Use StatefulWidget for managing settings state
- Load settings from PreferencesService in initState
- Update both local state and persistent storage together
- Use copyWith pattern for immutable updates

### Section Header Pattern

From `lib/screens/settings_screen.dart`:

```dart
Widget _buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
```

**Key Points:**
- Consistent padding for section headers
- Use theme text styles with primary color
- Bold weight for visual hierarchy

### Model copyWith Pattern

From `lib/models/app_settings.dart`:

```dart
AppSettings copyWith({
  ImageRecognitionProvider? imageRecognitionProvider,
  double? confidenceThreshold,
  // ...
}) {
  return AppSettings(
    imageRecognitionProvider: imageRecognitionProvider ?? this.imageRecognitionProvider,
    // ...
    updatedAt: DateTime.now().toIso8601String(),
  );
}
```

**Key Points:**
- Use nullable parameters with ?? fallback
- Auto-update timestamp on changes
- Preserve unchanged fields

## Requirements

### Functional Requirements

1. **Profile Header Display**
   - Description: Show a visually unique header with user avatar/initials, display name, and gradient background
   - Acceptance: Header renders with proper gradient from theme, displays user's name or "User" default

2. **Theme Selection**
   - Description: Allow users to switch between light, dark, and system themes
   - Acceptance: Theme changes persist and apply immediately when selected

3. **Display Name Edit**
   - Description: Users can set/edit their display name shown in the profile
   - Acceptance: Name persists across app restarts, shown in profile header

4. **Settings Integration**
   - Description: Include image recognition settings from existing settings_screen.dart
   - Acceptance: All existing settings functionality works within new profile screen

5. **App Info Section**
   - Description: Show app version, about info, and feedback option
   - Acceptance: Version displays correctly, about dialog shows app information

6. **Unique Visual Elements**
   - Description: Implement distinctive design elements (gradient cards, subtle animations, modern layout)
   - Acceptance: Screen looks visually distinct from other screens while maintaining theme consistency

### Edge Cases

1. **First-time user** - Show sensible defaults (display name = "User", system theme)
2. **Long display name** - Truncate with ellipsis in header, show full in edit dialog
3. **Theme not persisting** - Ensure AppSettings properly saves theme preference
4. **Settings migration** - Handle existing settings without new fields gracefully

## Implementation Notes

### DO
- Follow the pattern in `settings_screen.dart` for settings management
- Reuse `PreferencesService` for all persistence operations
- Use `Theme.of(context).colorScheme` for colors to respect theme
- Use `AppThemeExtension` for gradient access when available
- Keep the design "simple" - avoid over-engineering
- Add subtle animations for the "unique" feel (e.g., fade-in on sections)
- Use existing `AppSpacing`, `AppRadius` tokens from theme system

### DON'T
- Create new storage mechanisms when Hive/PreferencesService works
- Add backend authentication - this is local profile only
- Duplicate settings code - extract to shared widgets if needed
- Use hardcoded colors - always use theme system
- Make overly complex UI - "simple" is a key requirement

## Development Environment

### Start Services

```bash
# Run on iOS Simulator
flutter run

# Run on Android Emulator
flutter run -d emulator-5554

# Run on Chrome (for quick testing)
flutter run -d chrome
```

### Service URLs
- N/A - Mobile application

### Required Environment Variables
- None required for local development

## Success Criteria

The task is complete when:

1. [ ] New `ProfileScreen` is accessible from main navigation
2. [ ] Profile header displays with unique gradient design
3. [ ] User can edit and save display name
4. [ ] Theme preference can be changed (light/dark/system)
5. [ ] Image recognition settings are accessible within profile
6. [ ] App info section shows version and about information
7. [ ] All settings persist across app restarts
8. [ ] No console errors during navigation and interactions
9. [ ] Existing tests still pass
10. [ ] UI is visually distinctive yet consistent with app theme

## QA Acceptance Criteria

**CRITICAL**: These criteria must be verified by the QA Agent before sign-off.

### Unit Tests
| Test | File | What to Verify |
|------|------|----------------|
| AppSettings with new fields | `test/models/app_settings_test.dart` | New fields (displayName, themeMode) serialize/deserialize correctly |
| Profile copyWith | `test/models/app_settings_test.dart` | copyWith preserves existing values and updates specified ones |
| PreferencesService profile ops | `test/services/preferences_service_test.dart` | Profile settings load and save correctly |

### Integration Tests
| Test | Services | What to Verify |
|------|----------|----------------|
| Settings persistence | PreferencesService ↔ Hive | Settings persist after app restart |
| Theme application | ProfileScreen ↔ AppTheme | Theme changes apply to entire app |

### End-to-End Tests
| Flow | Steps | Expected Outcome |
|------|-------|------------------|
| Edit display name | 1. Open profile 2. Tap name edit 3. Enter "John" 4. Save | Name shows "John" in header and persists after restart |
| Change theme | 1. Open profile 2. Select "Dark" theme 3. Close and reopen app | App stays in dark theme |
| View app info | 1. Open profile 2. Scroll to app info 3. Tap "About" | Dialog shows app version and description |

### Browser Verification (if frontend)
| Page/Component | URL | Checks |
|----------------|-----|--------|
| N/A (Mobile App) | N/A | Test on iOS Simulator and Android Emulator |

### Device Verification
| Check | Device | What to Verify |
|-------|--------|----------------|
| Profile header gradient | iOS & Android | Gradient renders correctly on both platforms |
| Theme persistence | iOS & Android | Theme preference persists on both platforms |
| Layout responsiveness | Various screen sizes | UI adapts to different screen sizes |

### Database Verification (if applicable)
| Check | Query/Command | Expected |
|-------|---------------|----------|
| Settings box exists | Check Hive boxes | `app_settings` box contains settings with new fields |
| Migration handling | Open app with old settings | App handles missing fields gracefully |

### QA Sign-off Requirements
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] All E2E tests pass
- [ ] Device verification complete on iOS and Android
- [ ] Settings persist across app restart verified
- [ ] No regressions in existing functionality (QR, NFC, Containers)
- [ ] Code follows established patterns (screen structure, service usage)
- [ ] No security vulnerabilities introduced
- [ ] Profile screen is accessible from navigation
- [ ] Visual design is unique yet consistent with app theme
