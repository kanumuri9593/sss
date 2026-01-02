import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme_mode.dart';

/// Profile Screen with gradient header and avatar section
///
/// Displays user profile information with a visually unique gradient header,
/// avatar section showing user initials, and editable display name.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  /// Get initials from display name (e.g., "John Doe" -> "JD")
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || name.isEmpty) return 'U';

    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }

    return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1))
        .toUpperCase();
  }

  /// Show dialog to edit display name
  void _showEditNameDialog() {
    final controller = TextEditingController(text: _settings.displayName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            hintText: 'Enter your name',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                _updateSettings(_settings.copyWith(displayName: newName));
              }
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Build gradient header with avatar and name
  Widget _buildProfileHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primaryContainer,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
          child: Column(
            children: [
              // Avatar with initials
              CircleAvatar(
                radius: 56,
                backgroundColor: colorScheme.surface,
                child: Text(
                  _getInitials(_settings.displayName),
                  style: textTheme.displayMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Display name with edit button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      _settings.displayName,
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: colorScheme.onPrimary.withOpacity(0.9),
                      size: 20,
                    ),
                    onPressed: _showEditNameDialog,
                    tooltip: 'Edit name',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build section header
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

  /// Build theme selector with visual preview cards
  Widget _buildThemeSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Theme',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: AppThemeMode.values.map((mode) {
                final isSelected = _settings.themeMode == mode;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildThemePreviewCard(
                      mode: mode,
                      isSelected: isSelected,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual theme preview card
  Widget _buildThemePreviewCard({
    required AppThemeMode mode,
    required bool isSelected,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return InkWell(
      onTap: () {
        _updateSettings(_settings.copyWith(themeMode: mode));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? colorScheme.primaryContainer.withOpacity(0.3)
              : colorScheme.surface,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              mode.icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              mode.displayName,
              style: textTheme.labelMedium?.copyWith(
                color:
                    isSelected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient header as sliver
          SliverToBoxAdapter(
            child: _buildProfileHeader(),
          ),

          // Profile content
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),
              _buildSectionHeader('Profile Settings'),

              // Notifications setting
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.notifications_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Notifications'),
                  subtitle: Text(
                    _settings.notificationsEnabled ? 'Enabled' : 'Disabled',
                  ),
                  trailing: Switch(
                    value: _settings.notificationsEnabled,
                    onChanged: (value) {
                      _updateSettings(
                        _settings.copyWith(notificationsEnabled: value),
                      );
                    },
                  ),
                ),
              ),

              // Appearance section
              _buildSectionHeader('Appearance'),
              _buildThemeSelector(),

              // Image Recognition section
              _buildSectionHeader('Image Recognition'),
              _buildImageRecognitionSettings(),

              const SizedBox(height: 24),
            ]),
          ),
        ],
      ),
    );
  }

  /// Build image recognition settings section
  Widget _buildImageRecognitionSettings() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider selection
            Row(
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Provider',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Provider options
            ...ImageRecognitionProvider.values.map((provider) {
              final isSelected = _settings.imageRecognitionProvider == provider;
              final providerName = provider == ImageRecognitionProvider.tensorflowLite
                  ? 'TensorFlow Lite'
                  : 'ML Kit';
              final providerDescription = provider == ImageRecognitionProvider.tensorflowLite
                  ? 'On-device ML with TensorFlow'
                  : 'Google ML Kit framework';

              return RadioListTile<ImageRecognitionProvider>(
                value: provider,
                groupValue: _settings.imageRecognitionProvider,
                onChanged: (value) {
                  if (value != null) {
                    _updateSettings(
                      _settings.copyWith(imageRecognitionProvider: value),
                    );
                  }
                },
                title: Text(providerName),
                subtitle: Text(
                  providerDescription,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),

            const Divider(height: 24),

            // Confidence threshold slider
            Text(
              'Confidence Threshold',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Minimum confidence level for tag recognition (${(_settings.confidenceThreshold * 100).toInt()}%)',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Slider(
              value: _settings.confidenceThreshold,
              min: 0.1,
              max: 0.9,
              divisions: 16,
              label: '${(_settings.confidenceThreshold * 100).toInt()}%',
              onChanged: (value) {
                _updateSettings(
                  _settings.copyWith(confidenceThreshold: value),
                );
              },
            ),

            const Divider(height: 24),

            // Max tags slider
            Text(
              'Maximum Tags',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Maximum number of tags per image (${_settings.maxTags})',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Slider(
              value: _settings.maxTags.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '${_settings.maxTags}',
              onChanged: (value) {
                _updateSettings(
                  _settings.copyWith(maxTags: value.toInt()),
                );
              },
            ),

            const Divider(height: 24),

            // Heuristic fallback toggle
            SwitchListTile(
              value: _settings.useHeuristicFallback,
              onChanged: (value) {
                _updateSettings(
                  _settings.copyWith(useHeuristicFallback: value),
                );
              },
              title: Text(
                'Use Heuristic Fallback',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Use rule-based tagging when ML confidence is low',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
