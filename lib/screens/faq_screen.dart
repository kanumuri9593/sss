import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/faq_content.dart';
import '../theme/tokens/app_spacing.dart';
import '../widgets/glass_components.dart';
import '../widgets/glass_guide_card.dart';
import '../widgets/spring_animations.dart';

/// FAQ Screen - Help & Guides Hub
///
/// Main FAQ hub displaying all topic categories with glassmorphism design.
/// Each topic is a tappable card that navigates to the detailed guide.
class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text(
          'Help & Guides',
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
                  // Header section
                  SpringSlide(
                    beginOffset: const Offset(0, 30),
                    child: _buildHeader(context, colorScheme, isDark),
                  ),
                  AppSpacing.verticalGapLG,

                  // Topic cards
                  ..._buildTopicCards(context),

                  AppSpacing.verticalGapXL,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build header section with welcome message
  Widget _buildHeader(
    BuildContext context,
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
          // Icon
          Container(
            width: 64,
            height: 64,
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
            child: const Center(
              child: Text(
                '💡',
                style: TextStyle(fontSize: 32),
              ),
            ),
          ),
          AppSpacing.verticalGapMD,

          // Title
          Text(
            'Welcome to Help Center',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          AppSpacing.verticalGapSM,

          // Description
          Text(
            'Find step-by-step guides on how to use SSS features. Tap any topic below to get started.',
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

  /// Build topic cards with staggered animations
  List<Widget> _buildTopicCards(BuildContext context) {
    final topics = FAQTopic.values;

    return List.generate(
      topics.length,
      (index) {
        final topic = topics[index];
        return SpringSlide(
          beginOffset: const Offset(0, 30),
          delay: Duration(milliseconds: 100 + (index * 80)),
          child: GlassTopicCard(
            topic: topic,
            onTap: () => _navigateToTopic(context, topic),
          ),
        );
      },
    );
  }

  /// Navigate to topic detail screen
  void _navigateToTopic(BuildContext context, FAQTopic topic) {
    context.push('/faq/${topic.id}');
  }
}
