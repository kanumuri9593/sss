import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import '../models/app_settings.dart';
import '../services/preferences_service.dart';
import '../services/storage_service.dart';
import '../services/container_service.dart';
import '../services/item_service.dart';
import '../theme/app_theme_mode.dart';
import '../theme/tokens/app_spacing.dart';
import '../widgets/glass_components.dart';
import '../widgets/spring_animations.dart';
import '../widgets/animated_widgets.dart';
import '../presentation/providers/service_providers.dart';
import '../presentation/providers/initialization_provider.dart';
import '../presentation/controllers/settings_controller.dart';
import '../presentation/states/settings_state.dart';
import '../services/permission_service.dart';

/// Profile Screen - Award-Winning UI Redesign
///
/// Comprehensive settings page with glass morphism design:
/// - Glass header card with app stats
/// - Animated theme previews
/// - Settings in expandable glass sections
/// - Fun illustrations for each section
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _storagePath = '';
  String _cacheSizeDisplay = 'Calculating...';
  Map<Permission, PermissionStatus> _permissions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storagePath = await PreferencesService.getStoragePath();
    final cacheBytes = await PreferencesService.getImageCacheSizeBytes();
    final cacheSizeDisplay = PreferencesService.formatBytes(cacheBytes);
    
    // Use PermissionService for centralized permission management
    await PermissionService.refreshPermissionCache();
    final allPermissions = await PermissionService.getAllPermissionStatuses();

    if (mounted) {
      setState(() {
        _storagePath = storagePath;
        _cacheSizeDisplay = cacheSizeDisplay;
        _permissions = allPermissions;
        _isLoading = false;
      });
    }
  }
  
  /// Refresh permission statuses
  Future<void> _refreshPermissions() async {
    await PermissionService.refreshPermissionCache();
    final allPermissions = await PermissionService.getAllPermissionStatuses();
    if (mounted) {
      setState(() {
        _permissions = allPermissions;
      });
    }
  }

  void _updateSettings(AppSettings newSettings) async {
    HapticFeedback.selectionClick();
    // Update through the controller which will update state immediately
    final controller = ref.read(settingsControllerProvider.notifier);
    final success = await controller.updateSettings(newSettings);
    // Also update PreferencesService for backward compatibility
    if (PreferencesService.isInitialized) {
      await PreferencesService.updateSettings(newSettings);
    }
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wait for initialization
    final initialization = ref.watch(initializationProvider);
    final settingsState = ref.watch(settingsControllerProvider);
    
    if (initialization.isLoading || settingsState is SettingsLoading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (initialization.hasError || settingsState is SettingsError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${initialization.hasError ? initialization.error : (settingsState as SettingsError).message}'),
            ],
          ),
        ),
      );
    }
    
    final settings = settingsState is SettingsLoaded 
        ? settingsState.settings 
        : AppSettings.defaultSettings();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top:
                          MediaQuery.of(context).padding.top +
                          kToolbarHeight +
                          16,
                    ),
                    child: Column(
                      children: [
                        // Profile Header with animation
                        SpringSlide(
                          beginOffset: const Offset(0, 30),
                          child: _buildProfileHeader(colorScheme),
                        ),
                        AppSpacing.verticalGapLG,

                        // Appearance Section
                        SpringSlide(
                          beginOffset: const Offset(0, 30),
                          delay: const Duration(milliseconds: 100),
                          child: _buildGlassSection(
                            context,
                            title: 'Appearance',
                            icon: Icons.palette_rounded,
                            emoji: '🎨',
                            children: [
                              _buildThemeSelector(colorScheme, settings),
                              _buildGlassDivider(),
                              _buildFontScaleSelector(colorScheme, settings),
                              _buildGlassDivider(),
                              _buildDynamicTypeToggle(settings),
                            ],
                          ),
                        ),
                        AppSpacing.verticalGapMD,

                        // Image Recognition Section
                        SpringSlide(
                          beginOffset: const Offset(0, 30),
                          delay: const Duration(milliseconds: 200),
                          child: _buildGlassSection(
                            context,
                            title: 'Image Recognition',
                            icon: Icons.image_search_rounded,
                            emoji: '🔍',
                            children: [
                              _buildProviderSelector(colorScheme, settings),
                              _buildGlassDivider(),
                              _buildConfidenceSlider(settings),
                              _buildGlassDivider(),
                              _buildHeuristicFallbackToggle(settings),
                            ],
                          ),
                        ),
                        AppSpacing.verticalGapMD,

                        // Storage & Data Section
                        SpringSlide(
                          beginOffset: const Offset(0, 30),
                          delay: const Duration(milliseconds: 300),
                          child: _buildGlassSection(
                            context,
                            title: 'Storage & Data',
                            icon: Icons.storage_rounded,
                            emoji: '💾',
                            children: [
                              _buildStorageLocation(),
                              _buildGlassDivider(),
                              _buildImageCacheSettings(colorScheme, settings),
                              _buildGlassDivider(),
                              _buildClearCacheButton(colorScheme),
                              _buildGlassDivider(),
                              _buildClearAllDataButton(colorScheme, settings),
                            ],
                          ),
                        ),
                        AppSpacing.verticalGapMD,

                        // Permissions Section
                        SpringSlide(
                          beginOffset: const Offset(0, 30),
                          delay: const Duration(milliseconds: 400),
                          child: _buildGlassSection(
                            context,
                            title: 'Permissions',
                            icon: Icons.security_rounded,
                            emoji: '🔐',
                            children: [
                              _buildPermissionTile(
                                Permission.camera,
                                'Camera',
                                'Required for QR scanning and photo capture',
                                Icons.camera_alt_rounded,
                              ),
                              _buildGlassDivider(),
                              _buildPermissionTile(
                                Permission.storage,
                                'Storage',
                                'Required for saving and exporting data',
                                Icons.folder_rounded,
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.verticalGapMD,

                        // Help & Guides Section
                        SpringSlide(
                          beginOffset: const Offset(0, 30),
                          delay: const Duration(milliseconds: 450),
                          child: _buildGlassSection(
                            context,
                            title: 'Help & Guides',
                            icon: Icons.help_outline_rounded,
                            emoji: '📖',
                            children: [
                              _buildHelpTile(
                                'FAQs & How-To Guides',
                                'Get help with QR codes, NFC tags, and more',
                                Icons.library_books_rounded,
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.verticalGapMD,

                        // About Section
                        SpringSlide(
                          beginOffset: const Offset(0, 30),
                          delay: const Duration(milliseconds: 500),
                          child: _buildGlassSection(
                            context,
                            title: 'About',
                            icon: Icons.info_rounded,
                            emoji: 'ℹ️',
                            children: [
                              _buildAboutTile('Version', '1.0.0'),
                              _buildGlassDivider(),
                              _buildResetButton(colorScheme, settings),
                            ],
                          ),
                        ),
                        AppSpacing.verticalGapXL,
                        AppSpacing.verticalGapXL,
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGlassDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
    );
  }

  // ========== Glass Section Card ==========

  Widget _buildGlassSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String emoji,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      blur: 15,
      opacity: isDark ? 0.12 : 0.6,
      margin: AppSpacing.horizontalMD,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.1),
                  colorScheme.secondary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Children
          ...children,
          const SizedBox(height: 8),
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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      blur: 20,
      opacity: isDark ? 0.15 : 0.7,
      margin: AppSpacing.horizontalMD,
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // App Icon with glow
          PulseGlow(
            glowColor: colorScheme.primary,
            glowRadius: 30,
            enabled: true,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
          ),
          AppSpacing.verticalGapMD,

          // App Name
          Text(
            'SSS - Search & Scan',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.verticalGapXS,

          Text(
            'Organize your world',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          AppSpacing.verticalGapLG,

          // Stats with animation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAnimatedStatPill(
                Icons.inventory_2_rounded,
                containerCount,
                'containers',
                colorScheme.primary,
              ),
              AppSpacing.horizontalGapMD,
              _buildAnimatedStatPill(
                Icons.category_rounded,
                itemCount,
                'items',
                colorScheme.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStatPill(
    IconData icon,
    int count,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          CountUp(
            value: count,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 13),
          ),
        ],
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

  Widget _buildThemeSelector(ColorScheme colorScheme, AppSettings settings) {
    return ListTile(
      title: const Text('Theme'),
      subtitle: Text(settings.themeMode.displayName),
      onTap: () => _showThemeDialog(colorScheme, settings),
    );
  }

  void _showThemeDialog(ColorScheme colorScheme, AppSettings settings) async {
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
                groupValue: settings.themeMode,
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
      _updateSettings(settings.copyWith(themeMode: result));
    }
  }

  Widget _buildFontScaleSelector(ColorScheme colorScheme, AppSettings settings) {
    return ListTile(
      title: const Text('Font Size'),
      subtitle: Text(settings.fontScale.displayName),
      onTap: () => _showFontScaleDialog(settings),
    );
  }

  void _showFontScaleDialog(AppSettings settings) async {
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
              groupValue: settings.fontScale,
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
      _updateSettings(settings.copyWith(fontScale: result));
    }
  }

  Widget _buildDynamicTypeToggle(AppSettings settings) {
    return SwitchListTile(
      title: const Text('Use System Font Size'),
      subtitle: const Text('Follow device accessibility settings'),
      value: settings.useDynamicType,
      onChanged: (value) {
        _updateSettings(settings.copyWith(useDynamicType: value));
      },
    );
  }

  // ========== Image Recognition Settings ==========

  Widget _buildProviderSelector(ColorScheme colorScheme, AppSettings settings) {
    return ListTile(
      title: const Text('Recognition Provider'),
      subtitle: Text(
        _getProviderDisplayName(settings.imageRecognitionProvider),
      ),
      onTap: () => _showProviderDialog(settings),
    );
  }

  void _showProviderDialog(AppSettings settings) async {
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
              groupValue: settings.imageRecognitionProvider,
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
              groupValue: settings.imageRecognitionProvider,
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
      _updateSettings(settings.copyWith(imageRecognitionProvider: result));
    }
  }

  Widget _buildConfidenceSlider(AppSettings settings) {
    return ListTile(
      title: const Text('Confidence Threshold'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${(settings.confidenceThreshold * 100).toInt()}%',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          Slider(
            value: settings.confidenceThreshold,
            min: 0.1,
            max: 0.9,
            divisions: 8,
            label: '${(settings.confidenceThreshold * 100).toInt()}%',
            onChanged: (value) {
              _updateSettings(settings.copyWith(confidenceThreshold: value));
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

  Widget _buildHeuristicFallbackToggle(AppSettings settings) {
    return SwitchListTile(
      title: const Text('Use Heuristic Fallback'),
      subtitle: const Text('Generate basic tags when ML fails'),
      value: settings.useHeuristicFallback,
      onChanged: (value) {
        _updateSettings(settings.copyWith(useHeuristicFallback: value));
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
      onTap: () {
        // Copy path to clipboard
        Clipboard.setData(ClipboardData(text: _storagePath));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Path copied to clipboard')),
        );
      },
    );
  }

  Widget _buildImageCacheSettings(ColorScheme colorScheme, AppSettings settings) {
    return ListTile(
      title: const Text('Image Cache Size Limit'),
      subtitle: Text(settings.imageCacheSize.displayName),
      onTap: () => _showCacheSizeDialog(settings),
    );
  }

  void _showCacheSizeDialog(AppSettings settings) async {
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
              groupValue: settings.imageCacheSize,
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
      _updateSettings(settings.copyWith(imageCacheSize: result));
    }
  }

  Widget _buildClearCacheButton(ColorScheme colorScheme) {
    return ListTile(
      title: const Text('Clear Image Cache'),
      subtitle: Text('Current size: $_cacheSizeDisplay'),
      onTap: () async {
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
    );
  }

  Widget _buildClearAllDataButton(ColorScheme colorScheme, AppSettings settings) {
    return ListTile(
      title: Text('Clear All Data', style: TextStyle(color: colorScheme.error)),
      subtitle: const Text('Remove all containers, items, and settings'),
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
          final settingsService = ref.read(settingsServiceProvider);
          await settingsService.resetToDefaults();
          // Also update PreferencesService for backward compatibility
          if (PreferencesService.isInitialized) {
            await PreferencesService.resetToDefaults();
          }
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
    String actionText;

    if (status.isGranted) {
      statusColor = Colors.green;
      statusText = 'Granted';
      statusIcon = Icons.check_circle;
      actionText = 'Tap to open Settings';
    } else if (status.isPermanentlyDenied) {
      statusColor = colorScheme.error;
      statusText = 'Denied';
      statusIcon = Icons.cancel;
      actionText = 'Tap to open Settings';
    } else {
      // status.isDenied means permission hasn't been asked yet
      statusColor = Colors.orange;
      statusText = 'Not Asked';
      statusIcon = Icons.help_outline;
      actionText = 'Tap to request permission';
    }

    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description),
          const SizedBox(height: 4),
          Text(
            actionText,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      onTap: () async {
        if (status.isPermanentlyDenied) {
          // Open Settings if permanently denied
          await openAppSettings();
          await Future.delayed(const Duration(seconds: 1));
          await _refreshPermissions();
        } else {
          // Request permission if not granted (includes "denied" which means not asked yet)
          debugPrint('[ProfileScreen] Requesting $title permission. Current status: $status');
          
          // Show loading indicator
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Requesting permission...'),
                duration: Duration(seconds: 1),
              ),
            );
          }
          
          final newStatus = await PermissionService.requestPermission(permission);
          await _refreshPermissions();
          
          // Show feedback
          if (mounted) {
            String message;
            if (newStatus.isGranted) {
              message = '$title permission granted! ✅';
            } else if (newStatus.isPermanentlyDenied) {
              message = '$title permission denied. Tap "Open Settings" to enable it.';
            } else if (newStatus.isDenied) {
              message = '$title permission not granted. The app should now appear in Settings.';
            } else {
              message = '$title permission status: $newStatus';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                duration: const Duration(seconds: 4),
                action: newStatus.isPermanentlyDenied
                    ? SnackBarAction(
                        label: 'Open Settings',
                        onPressed: () async {
                          await openAppSettings();
                          await Future.delayed(const Duration(seconds: 1));
                          await _refreshPermissions();
                        },
                      )
                    : null,
              ),
            );
          }
        }
      },
    );
  }

  // ========== Help & Guides ==========

  Widget _buildHelpTile(
    String title,
    String description,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title),
      subtitle: Text(description),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.primary),
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/faq');
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

  Widget _buildResetButton(ColorScheme colorScheme, AppSettings settings) {
    return ListTile(
      title: const Text('Reset to Defaults'),
      subtitle: const Text('Restore all settings to default values'),
      onTap: () async {
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
          final settingsService = ref.read(settingsServiceProvider);
          await settingsService.resetToDefaults();
          // Also update PreferencesService for backward compatibility
          if (PreferencesService.isInitialized) {
            await PreferencesService.resetToDefaults();
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings reset to defaults')),
            );
          }
        }
      },
    );
  }
}
