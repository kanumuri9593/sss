import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/preferences_service.dart';

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

              // Placeholder for future settings sections
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

              const SizedBox(height: 24),
            ]),
          ),
        ],
      ),
    );
  }
}
