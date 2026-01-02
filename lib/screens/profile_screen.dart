import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/app_settings.dart';
import '../services/preferences_service.dart';
import '../services/storage_service.dart';
import '../services/container_service.dart';
import '../services/item_service.dart';
import '../theme/app_theme_mode.dart';
import '../theme/tokens/app_spacing.dart';

/// Profile Screen
///
/// Comprehensive settings page for user preferences including:
/// - Appearance (theme, font)
/// - Image Recognition settings
/// - Storage & Data management
/// - System permissions
/// - About section
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late AppSettings _settings;
  String _storagePath = '';
  String _cacheSizeDisplay = 'Calculating...';
  Map<Permission, PermissionStatus> _permissions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _settings = PreferencesService.settings;
    _loadData();
  }

  Future<void> _loadData() async {
    // Load storage path
    final storagePath = await PreferencesService.getStoragePath();

    // Load cache size
    final cacheBytes = await PreferencesService.getImageCacheSizeBytes();
    final cacheSizeDisplay = PreferencesService.formatBytes(cacheBytes);

    // Check permissions
    final cameraStatus = await Permission.camera.status;
    final storageStatus = await Permission.storage.status;

    if (mounted) {
      setState(() {
        _storagePath = storagePath;
        _cacheSizeDisplay = cacheSizeDisplay;
        _permissions = {
          Permission.camera: cameraStatus,
          Permission.storage: storageStatus,
        };
        _isLoading = false;
      });
    }
  }

  void _updateSettings(AppSettings newSettings) async {
    setState(() {
      _settings = newSettings;
    });
    await PreferencesService.updateSettings(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppSpacing.paddingMD,
              children: [
                // Profile Header
                _buildProfileHeader(colorScheme),
                AppSpacing.verticalGapLG,

                // Appearance Section
                _buildSectionCard(
                  context,
                  title: 'Appearance',
                  icon: Icons.palette_outlined,
                  children: [
                    _buildThemeSelector(colorScheme),
                    const Divider(height: 1),
                    _buildFontScaleSelector(colorScheme),
                    const Divider(height: 1),
                    _buildDynamicTypeToggle(),
                  ],
                ),
                AppSpacing.verticalGapMD,

                // Image Recognition Section
                _buildSectionCard(
                  context,
                  title: 'Image Recognition',
                  icon: Icons.image_search_outlined,
                  children: [
                    _buildProviderSelector(colorScheme),
                    const Divider(height: 1),
                    _buildConfidenceSlider(),
                    const Divider(height: 1),
                    _buildHeuristicFallbackToggle(),
                  ],
                ),
                AppSpacing.verticalGapMD,

                // Storage & Data Section
                _buildSectionCard(
                  context,
                  title: 'Storage & Data',
                  icon: Icons.storage_outlined,
                  children: [
                    _buildStorageLocation(),
                    const Divider(height: 1),
                    _buildImageCacheSettings(colorScheme),
                    const Divider(height: 1),
                    _buildClearCacheButton(colorScheme),
                    const Divider(height: 1),
                    _buildClearAllDataButton(colorScheme),
                  ],
                ),
                AppSpacing.verticalGapMD,

                // Permissions Section
                _buildSectionCard(
                  context,
                  title: 'Permissions',
                  icon: Icons.security_outlined,
                  children: [
                    _buildPermissionTile(
                      Permission.camera,
                      'Camera',
                      'Required for QR scanning and photo capture',
                      Icons.camera_alt_outlined,
                    ),
                    const Divider(height: 1),
                    _buildPermissionTile(
                      Permission.storage,
                      'Storage',
                      'Required for saving and exporting data',
                      Icons.folder_outlined,
                    ),
                  ],
                ),
                AppSpacing.verticalGapMD,

                // About Section
                _buildSectionCard(
                  context,
                  title: 'About',
                  icon: Icons.info_outline,
                  children: [
                    _buildAboutTile('Version', '1.0.0'),
                    const Divider(height: 1),
                    _buildResetButton(colorScheme),
                  ],
                ),
                AppSpacing.verticalGapXL,
              ],
            ),
    );
  }

  // ========== Profile Header ==========

  Widget _buildProfileHeader(ColorScheme colorScheme) {
    final containerCount = StorageService.isInitialized
        ? ContainerService.getAllContainers().length
        : 0;
    final itemCount = StorageService.isInitialized
        ? ItemService.getAllItems().length
        : 0;

    return Card(
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          children: [
            // App Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.inventory_2,
                size: 40,
                color: Colors.white,
              ),
            ),
            AppSpacing.verticalGapMD,

            // App Name
            Text(
              'SSS - Search & Scan',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.verticalGapXS,

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatChip(
                  Icons.inventory_2_outlined,
                  '$containerCount containers',
                  colorScheme,
                ),
                AppSpacing.horizontalGapMD,
                _buildStatChip(
                  Icons.category_outlined,
                  '$itemCount items',
                  colorScheme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ========== Section Card ==========

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Children
          ...children,
        ],
      ),
    );
  }

  // ========== Appearance Settings ==========

  Widget _buildThemeSelector(ColorScheme colorScheme) {
    return ListTile(
      title: const Text('Theme'),
      subtitle: Text(_settings.themeMode.displayName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(colorScheme),
    );
  }

  void _showThemeDialog(ColorScheme colorScheme) async {
    final result = await showDialog<AppThemeMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: AppThemeMode.values.length,
            itemBuilder: (context, index) {
              final mode = AppThemeMode.values[index];
              return RadioListTile<AppThemeMode>(
                title: Row(
                  children: [
                    Icon(mode.icon, size: 20),
                    const SizedBox(width: 12),
                    Text(mode.displayName),
                  ],
                ),
                subtitle: Text(mode.description),
                value: mode,
                groupValue: _settings.themeMode,
                onChanged: (value) => Navigator.pop(context, value),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null) {
      _updateSettings(_settings.copyWith(themeMode: result));
    }
  }

  Widget _buildFontScaleSelector(ColorScheme colorScheme) {
    return ListTile(
      title: const Text('Font Size'),
      subtitle: Text(_settings.fontScale.displayName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showFontScaleDialog(),
    );
  }

  void _showFontScaleDialog() async {
    final result = await showDialog<FontScaleOption>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Font Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: FontScaleOption.values.map((option) {
            return RadioListTile<FontScaleOption>(
              title: Text(option.displayName),
              subtitle: Text('${(option.scale * 100).toInt()}% of normal'),
              value: option,
              groupValue: _settings.fontScale,
              onChanged: (value) => Navigator.pop(context, value),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null) {
      _updateSettings(_settings.copyWith(fontScale: result));
    }
  }

  Widget _buildDynamicTypeToggle() {
    return SwitchListTile(
      title: const Text('Use System Font Size'),
      subtitle: const Text('Follow device accessibility settings'),
      value: _settings.useDynamicType,
      onChanged: (value) {
        _updateSettings(_settings.copyWith(useDynamicType: value));
      },
    );
  }

  // ========== Image Recognition Settings ==========

  Widget _buildProviderSelector(ColorScheme colorScheme) {
    return ListTile(
      title: const Text('Recognition Provider'),
      subtitle: Text(
        _getProviderDisplayName(_settings.imageRecognitionProvider),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showProviderDialog(),
    );
  }

  void _showProviderDialog() async {
    final result = await showDialog<ImageRecognitionProvider>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Recognition Provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ImageRecognitionProvider>(
              title: const Row(
                children: [
                  Icon(Icons.offline_bolt, size: 20),
                  SizedBox(width: 12),
                  Text('TensorFlow Lite'),
                ],
              ),
              subtitle: const Text('Offline, free, 1000 classes'),
              value: ImageRecognitionProvider.tensorflowLite,
              groupValue: _settings.imageRecognitionProvider,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<ImageRecognitionProvider>(
              title: const Row(
                children: [
                  Icon(Icons.cloud, size: 20),
                  SizedBox(width: 12),
                  Text('Google ML Kit'),
                ],
              ),
              subtitle: const Text('Cloud-based, better accuracy'),
              value: ImageRecognitionProvider.mlKit,
              groupValue: _settings.imageRecognitionProvider,
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null) {
      _updateSettings(_settings.copyWith(imageRecognitionProvider: result));
    }
  }

  Widget _buildConfidenceSlider() {
    return ListTile(
      title: const Text('Confidence Threshold'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${(_settings.confidenceThreshold * 100).toInt()}%',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          Slider(
            value: _settings.confidenceThreshold,
            min: 0.1,
            max: 0.9,
            divisions: 8,
            label: '${(_settings.confidenceThreshold * 100).toInt()}%',
            onChanged: (value) {
              _updateSettings(_settings.copyWith(confidenceThreshold: value));
            },
          ),
          Text(
            'Higher values = fewer but more accurate tags',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildHeuristicFallbackToggle() {
    return SwitchListTile(
      title: const Text('Use Heuristic Fallback'),
      subtitle: const Text('Generate basic tags when ML fails'),
      value: _settings.useHeuristicFallback,
      onChanged: (value) {
        _updateSettings(_settings.copyWith(useHeuristicFallback: value));
      },
    );
  }

  String _getProviderDisplayName(ImageRecognitionProvider provider) {
    switch (provider) {
      case ImageRecognitionProvider.tensorflowLite:
        return 'TensorFlow Lite (Offline)';
      case ImageRecognitionProvider.mlKit:
        return 'Google ML Kit (Cloud)';
    }
  }

  // ========== Storage Settings ==========

  Widget _buildStorageLocation() {
    return ListTile(
      title: const Text('Storage Location'),
      subtitle: Text(
        _storagePath,
        style: Theme.of(context).textTheme.bodySmall,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.copy),
        onPressed: () {
          // Copy path to clipboard
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Path copied to clipboard')),
          );
        },
        tooltip: 'Copy path',
      ),
    );
  }

  Widget _buildImageCacheSettings(ColorScheme colorScheme) {
    return ListTile(
      title: const Text('Image Cache Size Limit'),
      subtitle: Text(_settings.imageCacheSize.displayName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showCacheSizeDialog(),
    );
  }

  void _showCacheSizeDialog() async {
    final result = await showDialog<ImageCacheSize>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Cache Size Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ImageCacheSize.values.map((size) {
            return RadioListTile<ImageCacheSize>(
              title: Text(size.displayName),
              value: size,
              groupValue: _settings.imageCacheSize,
              onChanged: (value) => Navigator.pop(context, value),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null) {
      _updateSettings(_settings.copyWith(imageCacheSize: result));
    }
  }

  Widget _buildClearCacheButton(ColorScheme colorScheme) {
    return ListTile(
      title: const Text('Clear Image Cache'),
      subtitle: Text('Current size: $_cacheSizeDisplay'),
      trailing: TextButton(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Clear Cache?'),
              content: const Text(
                'This will remove all cached images. They will be reloaded when needed.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Clear'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await PreferencesService.clearImageCache();
            await _loadData();
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Cache cleared')));
            }
          }
        },
        child: const Text('Clear'),
      ),
    );
  }

  Widget _buildClearAllDataButton(ColorScheme colorScheme) {
    return ListTile(
      title: Text('Clear All Data', style: TextStyle(color: colorScheme.error)),
      subtitle: const Text('Remove all containers, items, and settings'),
      trailing: Icon(Icons.warning_amber, color: colorScheme.error),
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Clear All Data?'),
            content: const Text(
              'This will permanently delete all containers, items, and reset all settings. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                child: const Text('Delete Everything'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await StorageService.clearAll();
          await PreferencesService.resetToDefaults();
          setState(() {
            _settings = PreferencesService.settings;
          });
          await _loadData();
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('All data cleared')));
          }
        }
      },
    );
  }

  // ========== Permissions ==========

  Widget _buildPermissionTile(
    Permission permission,
    String title,
    String description,
    IconData icon,
  ) {
    final status = _permissions[permission] ?? PermissionStatus.denied;
    final colorScheme = Theme.of(context).colorScheme;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (status.isGranted) {
      statusColor = Colors.green;
      statusText = 'Granted';
      statusIcon = Icons.check_circle;
    } else if (status.isPermanentlyDenied) {
      statusColor = colorScheme.error;
      statusText = 'Denied';
      statusIcon = Icons.cancel;
    } else {
      statusColor = Colors.orange;
      statusText = 'Not Set';
      statusIcon = Icons.help;
    }

    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title),
      subtitle: Text(description),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 4),
          Text(statusText, style: TextStyle(color: statusColor, fontSize: 12)),
        ],
      ),
      onTap: () async {
        if (status.isPermanentlyDenied) {
          await openAppSettings();
        } else if (!status.isGranted) {
          final newStatus = await permission.request();
          setState(() {
            _permissions[permission] = newStatus;
          });
        }
      },
    );
  }

  // ========== About ==========

  Widget _buildAboutTile(String title, String value) {
    return ListTile(
      title: Text(title),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildResetButton(ColorScheme colorScheme) {
    return ListTile(
      title: const Text('Reset to Defaults'),
      subtitle: const Text('Restore all settings to default values'),
      trailing: TextButton(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Reset Settings?'),
              content: const Text(
                'This will reset all preferences to their default values. Your data will not be affected.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Reset'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await PreferencesService.resetToDefaults();
            setState(() {
              _settings = PreferencesService.settings;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            }
          }
        },
        child: const Text('Reset'),
      ),
    );
  }
}
