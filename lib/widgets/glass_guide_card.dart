import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/faq_content.dart';
import 'glass_components.dart';
import 'spring_animations.dart';

/// Glassmorphism Guide Card
///
/// A reusable widget for displaying FAQ guide steps with actions.
/// Features step numbers, icons, descriptions, and optional action buttons.

// ============================================================================
// GLASS GUIDE CARD - Step-by-step guide display
// ============================================================================

class GlassGuideCard extends StatelessWidget {
  final FAQGuideStep step;
  final VoidCallback? onActionTap;
  final EdgeInsetsGeometry? margin;
  final bool enableAnimation;

  const GlassGuideCard({
    super.key,
    required this.step,
    this.onActionTap,
    this.margin,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final card = GlassCard(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number badge
          _buildStepBadge(context, colorScheme, isDark),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and Title
                Row(
                  children: [
                    Icon(
                      step.icon,
                      size: 24,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  step.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.black.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),

                // Action button (if present)
                if (step.action != null) ...[
                  const SizedBox(height: 16),
                  _buildActionButton(context, colorScheme, isDark),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    // Wrap with animation if enabled
    if (enableAnimation) {
      return SpringSlide(
        beginOffset: const Offset(0, 20),
        delay: Duration(milliseconds: 100 * step.stepNumber),
        child: card,
      );
    }

    return card;
  }

  /// Build step number badge
  Widget _buildStepBadge(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      width: 40,
      height: 40,
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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${step.stepNumber}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Build action button
  Widget _buildActionButton(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final action = step.action!;

    return SpringScale(
      onTap: onActionTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              _getActionIcon(action.type),
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              action.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get icon for action type
  IconData _getActionIcon(FAQActionType type) {
    switch (type) {
      case FAQActionType.navigate:
        return Icons.arrow_forward_rounded;
      case FAQActionType.openAppSettings:
        return Icons.settings_rounded;
      case FAQActionType.openNFCSettings:
        return Icons.nfc_rounded;
      case FAQActionType.external:
        return Icons.open_in_new_rounded;
    }
  }
}

// ============================================================================
// GLASS GUIDE LIST - Vertical list of guide steps
// ============================================================================

class GlassGuideList extends StatelessWidget {
  final List<FAQGuideStep> steps;
  final void Function(FAQAction action)? onActionTap;
  final EdgeInsetsGeometry? padding;
  final bool enableAnimations;

  const GlassGuideList({
    super.key,
    required this.steps,
    this.onActionTap,
    this.padding,
    this.enableAnimations = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        return GlassGuideCard(
          step: step,
          enableAnimation: enableAnimations,
          onActionTap: step.action != null
              ? () => onActionTap?.call(step.action!)
              : null,
        );
      },
    );
  }
}

// ============================================================================
// GLASS TOPIC CARD - Tappable card for FAQ topics
// ============================================================================

class GlassTopicCard extends StatelessWidget {
  final FAQTopic topic;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const GlassTopicCard({
    super.key,
    required this.topic,
    this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SpringScale(
      onTap: onTap,
      child: GlassCard(
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(20),
        onTap: onTap,
        child: Row(
          children: [
            // Topic emoji/icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.2),
                    colorScheme.primary.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  topic.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Topic info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    topic.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Arrow indicator
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
