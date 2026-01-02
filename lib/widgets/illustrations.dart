import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/tokens/app_colors.dart';
import 'spring_animations.dart';

/// Custom Illustrations for Empty States
///
/// Playful, animated illustrations inspired by Duolingo and modern apps.
/// Uses CustomPaint for scalable vector graphics with animations.

// ============================================================================
// NO CONTAINERS - Cute animated box character
// ============================================================================

class NoContainersIllustration extends StatefulWidget {
  final double size;
  final Color? primaryColor;

  const NoContainersIllustration({
    super.key,
    this.size = 180,
    this.primaryColor,
  });

  @override
  State<NoContainersIllustration> createState() =>
      _NoContainersIllustrationState();
}

class _NoContainersIllustrationState extends State<NoContainersIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _floatAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeInOut),
        reverseCurve: const Interval(0.5, 1, curve: Curves.easeInOut),
      ),
    );

    _blinkAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1), weight: 90),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.1), weight: 5),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 1), weight: 5),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = widget.primaryColor ?? theme.colorScheme.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -_floatAnimation.value + 5),
            child: CustomPaint(
              painter: _BoxCharacterPainter(
                primaryColor: primary,
                blinkValue: _blinkAnimation.value,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BoxCharacterPainter extends CustomPainter {
  final Color primaryColor;
  final double blinkValue;

  _BoxCharacterPainter({required this.primaryColor, required this.blinkValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final boxSize = size.width * 0.6;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.height * 0.85),
        width: boxSize * 0.8,
        height: boxSize * 0.15,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.1),
    );

    // Box body
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: boxSize, height: boxSize),
      const Radius.circular(16),
    );

    // Box gradient
    final boxPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryColor.withValues(alpha: 0.8), primaryColor],
      ).createShader(boxRect.outerRect);

    canvas.drawRRect(boxRect, boxPaint);

    // Box lid (slightly open)
    final lidPath = Path()
      ..moveTo(center.dx - boxSize / 2 - 5, center.dy - boxSize / 2 + 10)
      ..lineTo(center.dx, center.dy - boxSize / 2 - 15)
      ..lineTo(center.dx + boxSize / 2 + 5, center.dy - boxSize / 2 + 10)
      ..close();

    canvas.drawPath(
      lidPath,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill,
    );

    // Eyes
    final eyeY = center.dy - boxSize * 0.05;
    final eyeRadius = boxSize * 0.08;
    final eyeSpacing = boxSize * 0.2;

    // Left eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - eyeSpacing, eyeY),
        width: eyeRadius * 2,
        height: eyeRadius * 2 * blinkValue,
      ),
      Paint()..color = Colors.white,
    );

    // Right eye
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + eyeSpacing, eyeY),
        width: eyeRadius * 2,
        height: eyeRadius * 2 * blinkValue,
      ),
      Paint()..color = Colors.white,
    );

    // Pupils
    if (blinkValue > 0.5) {
      final pupilRadius = eyeRadius * 0.5;
      canvas.drawCircle(
        Offset(center.dx - eyeSpacing, eyeY),
        pupilRadius,
        Paint()..color = const Color(0xFF1F2937),
      );
      canvas.drawCircle(
        Offset(center.dx + eyeSpacing, eyeY),
        pupilRadius,
        Paint()..color = const Color(0xFF1F2937),
      );
    }

    // Curious mouth (small 'o')
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + boxSize * 0.15),
        width: boxSize * 0.15,
        height: boxSize * 0.12,
      ),
      0,
      math.pi,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Question mark floating above
    final textPainter = TextPainter(
      text: TextSpan(
        text: '?',
        style: TextStyle(
          fontSize: boxSize * 0.25,
          fontWeight: FontWeight.bold,
          color: primaryColor.withValues(alpha: 0.6),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx + boxSize / 2 + 5, center.dy - boxSize / 2 - 25),
    );
  }

  @override
  bool shouldRepaint(covariant _BoxCharacterPainter oldDelegate) {
    return oldDelegate.blinkValue != blinkValue;
  }
}

// ============================================================================
// NO ITEMS - Empty shelf with sparkles
// ============================================================================

class NoItemsIllustration extends StatefulWidget {
  final double size;
  final Color? primaryColor;

  const NoItemsIllustration({super.key, this.size = 180, this.primaryColor});

  @override
  State<NoItemsIllustration> createState() => _NoItemsIllustrationState();
}

class _NoItemsIllustrationState extends State<NoItemsIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = widget.primaryColor ?? theme.colorScheme.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _EmptyShelfPainter(
              primaryColor: primary,
              sparklePhase: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _EmptyShelfPainter extends CustomPainter {
  final Color primaryColor;
  final double sparklePhase;

  _EmptyShelfPainter({required this.primaryColor, required this.sparklePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final shelfWidth = size.width * 0.8;
    final shelfHeight = size.height * 0.12;

    // Shelf shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + shelfHeight + 5),
          width: shelfWidth * 0.9,
          height: shelfHeight * 0.3,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.1),
    );

    // Shelf
    final shelfRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + shelfHeight / 2),
        width: shelfWidth,
        height: shelfHeight,
      ),
      const Radius.circular(8),
    );

    final shelfPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.3),
          primaryColor.withValues(alpha: 0.5),
        ],
      ).createShader(shelfRect.outerRect);

    canvas.drawRRect(shelfRect, shelfPaint);

    // Draw floating sparkles
    _drawSparkle(
      canvas,
      Offset(center.dx - 30, center.dy - 30),
      12,
      primaryColor,
      (sparklePhase + 0.0) % 1.0,
    );
    _drawSparkle(
      canvas,
      Offset(center.dx + 35, center.dy - 20),
      10,
      AppColors.vibrantYellow,
      (sparklePhase + 0.3) % 1.0,
    );
    _drawSparkle(
      canvas,
      Offset(center.dx + 10, center.dy - 45),
      8,
      AppColors.vibrantPink,
      (sparklePhase + 0.6) % 1.0,
    );
    _drawSparkle(
      canvas,
      Offset(center.dx - 40, center.dy - 15),
      6,
      AppColors.vibrantCyan,
      (sparklePhase + 0.8) % 1.0,
    );
  }

  void _drawSparkle(
    Canvas canvas,
    Offset center,
    double size,
    Color color,
    double phase,
  ) {
    final opacity = math.sin(phase * math.pi);
    final scale = 0.5 + opacity * 0.5;
    final adjustedSize = size * scale;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity * 0.8)
      ..style = PaintingStyle.fill;

    // Four-pointed star
    final path = Path();
    path.moveTo(center.dx, center.dy - adjustedSize);
    path.lineTo(center.dx + adjustedSize * 0.3, center.dy);
    path.lineTo(center.dx, center.dy + adjustedSize);
    path.lineTo(center.dx - adjustedSize * 0.3, center.dy);
    path.close();

    path.moveTo(center.dx - adjustedSize, center.dy);
    path.lineTo(center.dx, center.dy - adjustedSize * 0.3);
    path.lineTo(center.dx + adjustedSize, center.dy);
    path.lineTo(center.dx, center.dy + adjustedSize * 0.3);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _EmptyShelfPainter oldDelegate) {
    return oldDelegate.sparklePhase != sparklePhase;
  }
}

// ============================================================================
// SEARCH NO RESULTS - Magnifying glass with expression
// ============================================================================

class SearchNoResultsIllustration extends StatelessWidget {
  final double size;
  final Color? primaryColor;

  const SearchNoResultsIllustration({
    super.key,
    this.size = 180,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = primaryColor ?? theme.colorScheme.primary;

    return Float(
      distance: 5,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _SearchNotFoundPainter(primaryColor: primary),
        ),
      ),
    );
  }
}

class _SearchNotFoundPainter extends CustomPainter {
  final Color primaryColor;

  _SearchNotFoundPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final glassRadius = size.width * 0.25;

    // Handle
    final handlePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx + glassRadius * 0.7, center.dy + glassRadius * 0.7),
      Offset(center.dx + glassRadius * 1.4, center.dy + glassRadius * 1.4),
      handlePaint,
    );

    // Glass circle shadow
    canvas.drawCircle(
      Offset(center.dx + 3, center.dy + 3),
      glassRadius,
      Paint()..color = Colors.black.withValues(alpha: 0.1),
    );

    // Glass circle
    canvas.drawCircle(
      center,
      glassRadius,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withValues(alpha: 0.2),
            primaryColor.withValues(alpha: 0.4),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: glassRadius)),
    );

    // Glass circle border
    canvas.drawCircle(
      center,
      glassRadius,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.05,
    );

    // Sad face - eyes
    final eyeY = center.dy - glassRadius * 0.15;
    final eyeSpacing = glassRadius * 0.35;
    final eyeRadius = glassRadius * 0.1;

    canvas.drawCircle(
      Offset(center.dx - eyeSpacing, eyeY),
      eyeRadius,
      Paint()..color = primaryColor,
    );
    canvas.drawCircle(
      Offset(center.dx + eyeSpacing, eyeY),
      eyeRadius,
      Paint()..color = primaryColor,
    );

    // Sad mouth
    final mouthPath = Path();
    mouthPath.moveTo(
      center.dx - glassRadius * 0.25,
      center.dy + glassRadius * 0.35,
    );
    mouthPath.quadraticBezierTo(
      center.dx,
      center.dy + glassRadius * 0.15,
      center.dx + glassRadius * 0.25,
      center.dy + glassRadius * 0.35,
    );

    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// LOADING BOX - Dancing box mascot
// ============================================================================

class LoadingBoxIllustration extends StatefulWidget {
  final double size;
  final Color? primaryColor;

  const LoadingBoxIllustration({super.key, this.size = 100, this.primaryColor});

  @override
  State<LoadingBoxIllustration> createState() => _LoadingBoxIllustrationState();
}

class _LoadingBoxIllustrationState extends State<LoadingBoxIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _squashAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(
      begin: 0,
      end: -20,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _squashAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
        reverseCurve: const Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = widget.primaryColor ?? theme.colorScheme.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scaleY = _squashAnimation.value;
          final scaleX = 2.0 - scaleY; // Inverse squash for stretch

          return Transform.translate(
            offset: Offset(0, _bounceAnimation.value),
            child: Transform.scale(
              scaleX: scaleX > 1.15 ? 1.15 : scaleX,
              scaleY: scaleY,
              alignment: Alignment.bottomCenter,
              child: CustomPaint(
                painter: _LoadingBoxPainter(primaryColor: primary),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoadingBoxPainter extends CustomPainter {
  final Color primaryColor;

  _LoadingBoxPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final boxSize = size.width * 0.7;

    // Box
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: boxSize, height: boxSize),
      const Radius.circular(12),
    );

    canvas.drawRRect(
      boxRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor.withValues(alpha: 0.9), primaryColor],
        ).createShader(boxRect.outerRect),
    );

    // Happy eyes (curved arcs)
    final eyeY = center.dy - boxSize * 0.05;
    final eyeSpacing = boxSize * 0.18;
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx - eyeSpacing, eyeY),
        width: boxSize * 0.15,
        height: boxSize * 0.1,
      ),
      math.pi,
      math.pi,
      false,
      eyePaint,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx + eyeSpacing, eyeY),
        width: boxSize * 0.15,
        height: boxSize * 0.1,
      ),
      math.pi,
      math.pi,
      false,
      eyePaint,
    );

    // Happy smile
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + boxSize * 0.12),
        width: boxSize * 0.3,
        height: boxSize * 0.2,
      ),
      0,
      math.pi,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// EMPTY STATE WRAPPER - Combines illustration with text
// ============================================================================

class EmptyStateWidget extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.illustration,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            illustration,
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
