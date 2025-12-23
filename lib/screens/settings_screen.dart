import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/preferences_service.dart';

/// Settings Screen
///
/// Allows users to configure image recognition provider and other app settings.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Image Recognition'),

          ListTile(
            title: const Text('Recognition Provider'),
            subtitle: Text(_getProviderDisplayName(_settings.imageRecognitionProvider)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showProviderDialog,
          ),

          SwitchListTile(
            title: const Text('Use Heuristic Fallback'),
            subtitle: const Text('Generate basic tags when ML fails'),
            value: _settings.useHeuristicFallback,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(useHeuristicFallback: value));
            },
          ),

          ListTile(
            title: const Text('Confidence Threshold'),
            subtitle: Text(
              '${(_settings.confidenceThreshold * 100).toInt()}% - Higher values = fewer but more accurate tags',
            ),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                value: _settings.confidenceThreshold,
                min: 0.1,
                max: 0.9,
                divisions: 8,
                label: '${(_settings.confidenceThreshold * 100).toInt()}%',
                onChanged: (value) {
                  _updateSettings(_settings.copyWith(confidenceThreshold: value));
                },
              ),
            ),
          ),

          const Divider(),

          _buildInfoCard(),
        ],
      ),
    );
  }

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

  Widget _buildInfoCard() {
    final provider = _settings.imageRecognitionProvider;
    final isTFLite = provider == ImageRecognitionProvider.tensorflowLite;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isTFLite ? Icons.offline_bolt : Icons.cloud,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isTFLite ? 'Offline Mode' : 'Cloud Mode',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isTFLite
                  ? 'TensorFlow Lite runs completely offline using on-device ML. No internet required, no usage limits.'
                  : 'Google ML Kit uses cloud processing for improved accuracy. Requires internet connection and has usage limits.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
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
              title: const Text('TensorFlow Lite'),
              subtitle: const Text('Offline, free, 1000 classes'),
              value: ImageRecognitionProvider.tensorflowLite,
              groupValue: _settings.imageRecognitionProvider,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<ImageRecognitionProvider>(
              title: const Text('Google ML Kit'),
              subtitle: const Text('Cloud-based, better accuracy'),
              value: ImageRecognitionProvider.mlKit,
              groupValue: _settings.imageRecognitionProvider,
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      _updateSettings(_settings.copyWith(imageRecognitionProvider: result));
    }
  }

  void _updateSettings(AppSettings newSettings) async {
    setState(() {
      _settings = newSettings;
    });
    await PreferencesService.updateSettings(newSettings);
  }

  String _getProviderDisplayName(ImageRecognitionProvider provider) {
    switch (provider) {
      case ImageRecognitionProvider.tensorflowLite:
        return 'TensorFlow Lite (Offline)';
      case ImageRecognitionProvider.mlKit:
        return 'Google ML Kit (Cloud)';
    }
  }
}
