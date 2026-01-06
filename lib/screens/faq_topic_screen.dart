import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../models/faq_content.dart';
import '../services/permission_service.dart';
import '../theme/tokens/app_spacing.dart';
import '../widgets/glass_components.dart';
import '../widgets/glass_guide_card.dart';
import '../widgets/spring_animations.dart';

/// FAQ Topic Screen - Step-by-Step Guide Detail
///
/// Displays detailed step-by-step instructions for a specific FAQ topic.
/// Handles deeplink actions for in-app navigation and system settings.
class FAQTopicScreen extends StatelessWidget {
  final String topicId;

  const FAQTopicScreen({
    super.key,
    required this.topicId,
  });

  @override
  Widget build(BuildContext context) {
    // Get FAQ content for this topic
    final content = FAQContent.getContentById(topicId);

    // Handle invalid topic ID
    if (content == null) {
      return _buildInvalidTopicScreen(context);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text(
          content.topic.displayName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top +
                    kToolbarHeight +
                    16,
              ),
              child: Column(
                children: [
                  // Topic header
                  SpringSlide(
                    beginOffset: const Offset(0, 30),
                    child: _buildTopicHeader(
                      context,
                      content.topic,
                      colorScheme,
                      isDark,
                    ),
                  ),
                  AppSpacing.verticalGapLG,

                  // Guide steps
                  ..._buildGuideSteps(context, content.steps),

                  AppSpacing.verticalGapXL,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build topic header with icon, title, and description
  Widget _buildTopicHeader(
    BuildContext context,
    FAQTopic topic,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and emoji
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                topic.emoji,
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
          AppSpacing.verticalGapMD,

          // Title
          Text(
            topic.displayName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          AppSpacing.verticalGapSM,

          // Description
          Text(
            topic.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.black.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Build guide step cards with staggered animations
  List<Widget> _buildGuideSteps(
    BuildContext context,
    List<FAQGuideStep> steps,
  ) {
    return List.generate(
      steps.length,
      (index) {
        final step = steps[index];
        return GlassGuideCard(
          step: step,
          enableAnimation: true,
          onActionTap: step.action != null
              ? () => _handleAction(context, step.action!)
              : null,
        );
      },
    );
  }

  /// Handle FAQ action taps
  Future<void> _handleAction(BuildContext context, FAQAction action) async {
    HapticFeedback.selectionClick();

    switch (action.type) {
      case FAQActionType.navigate:
        if (action.route != null) {
          // Navigate to in-app route
          context.push(action.route!);
        }
        break;

      case FAQActionType.openAppSettings:
        // Open system app settings using PermissionService
        final success = await PermissionService.openAppSettings();
        if (!success && context.mounted) {
          _showErrorSnackBar(
            context,
            'Unable to open app settings. Please check your device settings manually.',
          );
        }
        break;

      case FAQActionType.openNFCSettings:
        // NFC settings are Android-specific
        if (Platform.isAndroid) {
          _showNFCSettingsDialog(context);
        } else {
          // iOS doesn't have NFC settings (always enabled on iPhone 7+)
          if (context.mounted) {
            _showInfoSnackBar(
              context,
              'NFC is automatically enabled on iPhone 7 and newer devices.',
            );
          }
        }
        break;

      case FAQActionType.external:
        if (action.url != null) {
          // For external URLs, show a message (or implement URL launcher)
          if (context.mounted) {
            _showInfoSnackBar(
              context,
              'External link: ${action.url}',
            );
          }
        }
        break;
    }
  }

  /// Show NFC settings dialog for Android
  void _showNFCSettingsDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Row(
          children: [
            Icon(Icons.nfc_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Enable NFC'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To enable NFC on your Android device:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildInstructionStep('1. Open device Settings'),
            _buildInstructionStep('2. Go to Connected Devices'),
            _buildInstructionStep('3. Tap Connection Preferences'),
            _buildInstructionStep('4. Toggle NFC on'),
            const SizedBox(height: 12),
            Text(
              'Note: Menu names may vary by device manufacturer.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// Build instruction step for dialog
  Widget _buildInstructionStep(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const Icon(Icons.arrow_right_rounded, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  /// Build invalid topic screen
  Widget _buildInvalidTopicScreen(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text(
          'Topic Not Found',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.error.withValues(alpha: 0.2),
                      colorScheme.error.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.help_outline_rounded,
                    size: 48,
                    color: colorScheme.error,
                  ),
                ),
              ),
              AppSpacing.verticalGapLG,

              // Error message
              Text(
                'Topic Not Found',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.verticalGapSM,
              Text(
                'The requested FAQ topic "${topicId}" doesn\'t exist.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalGapLG,

              // Go back button
              SpringScale(
                onTap: () => context.go('/faq'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Back to FAQ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show info snackbar
  void _showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
