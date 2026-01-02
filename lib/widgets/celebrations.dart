import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/tokens/app_colors.dart';

/// Celebration Animations
///
/// Delight users with feedback animations for successful actions.
/// Inspired by Duolingo's celebratory animations.

// ============================================================================
// CONFETTI BURST - Celebrate container creation
// ============================================================================

class ConfettiBurst extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final Duration duration;
  final VoidCallback? onComplete;

  const ConfettiBurst({
    super.key,
    required this.child,
    this.trigger = false,
    this.duration = const Duration(milliseconds: 1500),
    this.onComplete,
  });

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(ConfettiBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _startConfetti();
    }
  }

  void _startConfetti() {
    HapticFeedback.mediumImpact();
    _particles.clear();

    // Generate confetti particles
    for (int i = 0; i < 50; i++) {
      _particles.add(
        _ConfettiParticle(
          color: AppColors
              .confettiColors[_random.nextInt(AppColors.confettiColors.length)],
          x: _random.nextDouble() * 2 - 1, // -1 to 1
          y: _random.nextDouble() * -0.5, // Start above
          vx: _random.nextDouble() * 4 - 2, // Velocity X
          vy: _random.nextDouble() * -8 - 4, // Initial upward velocity
          rotation: _random.nextDouble() * math.pi * 2,
          rotationSpeed: _random.nextDouble() * 10 - 5,
          size: _random.nextDouble() * 8 + 4,
          shape: _random.nextInt(3), // 0: square, 1: circle, 2: star
        ),
      );
    }

    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_controller.isAnimating || _controller.value > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      particles: _particles,
                      progress: _controller.value,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiParticle {
  final Color color;
  final double x;
  final double y;
  final double vx;
  final double vy;
  final double rotation;
  final double rotationSpeed;
  final double size;
  final int shape;

  _ConfettiParticle({
    required this.color,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.shape,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final gravity = 20.0;
    final time = progress * 2;

    for (final particle in particles) {
      // Physics simulation
      final x = center.dx + (particle.x * 100 + particle.vx * time * 50);
      final y =
          center.dy +
          (particle.y * 100 +
              particle.vy * time * 30 +
              gravity * time * time * 20);

      // Fade out
      final opacity = 1.0 - progress;
      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final rotation = particle.rotation + particle.rotationSpeed * time;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      switch (particle.shape) {
        case 0: // Square
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size,
            ),
            paint,
          );
          break;
        case 1: // Circle
          canvas.drawCircle(Offset.zero, particle.size / 2, paint);
          break;
        case 2: // Star
          _drawStar(canvas, particle.size, paint);
          break;
      }

      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 144 - 90) * math.pi / 180;
      final point = Offset(
        math.cos(angle) * size / 2,
        math.sin(angle) * size / 2,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================================
// SPARKLE TRAIL - First item added celebration
// ============================================================================

class SparkleTrail extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final Duration duration;

  const SparkleTrail({
    super.key,
    required this.child,
    this.trigger = false,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  State<SparkleTrail> createState() => _SparkleTrailState();
}

class _SparkleTrailState extends State<SparkleTrail>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Sparkle> _sparkles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didUpdateWidget(SparkleTrail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _startSparkle();
    }
  }

  void _startSparkle() {
    HapticFeedback.lightImpact();
    _sparkles.clear();

    for (int i = 0; i < 15; i++) {
      _sparkles.add(
        _Sparkle(
          x: _random.nextDouble() * 2 - 1,
          y: _random.nextDouble() * 2 - 1,
          delay: _random.nextDouble() * 0.3,
          size: _random.nextDouble() * 10 + 5,
          color: _random.nextBool()
              ? AppColors.celebrationGold
              : AppColors.celebrationSparkle,
        ),
      );
    }

    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_controller.isAnimating || _controller.value > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _SparklePainter(
                      sparkles: _sparkles,
                      progress: _controller.value,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _Sparkle {
  final double x;
  final double y;
  final double delay;
  final double size;
  final Color color;

  _Sparkle({
    required this.x,
    required this.y,
    required this.delay,
    required this.size,
    required this.color,
  });
}

class _SparklePainter extends CustomPainter {
  final List<_Sparkle> sparkles;
  final double progress;

  _SparklePainter({required this.sparkles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final sparkle in sparkles) {
      final adjustedProgress = (progress - sparkle.delay).clamp(0.0, 1.0);
      if (adjustedProgress <= 0) continue;

      final opacity = math.sin(adjustedProgress * math.pi);
      final scale = adjustedProgress < 0.5 ? adjustedProgress * 2 : 1.0;

      final x = center.dx + sparkle.x * size.width * 0.4;
      final y = center.dy + sparkle.y * size.height * 0.4;

      _drawSparkle(
        canvas,
        Offset(x, y),
        sparkle.size * scale,
        sparkle.color.withValues(alpha: opacity),
      );
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Four-pointed star
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size * 0.3, center.dy);
    path.lineTo(center.dx, center.dy + size);
    path.lineTo(center.dx - size * 0.3, center.dy);
    path.close();

    path.moveTo(center.dx - size, center.dy);
    path.lineTo(center.dx, center.dy - size * 0.3);
    path.lineTo(center.dx + size, center.dy);
    path.lineTo(center.dx, center.dy + size * 0.3);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================================
// SUCCESS CHECKMARK - Scan success animation
// ============================================================================

class SuccessCheckmark extends StatefulWidget {
  final double size;
  final Color? color;
  final Duration duration;
  final VoidCallback? onComplete;

  const SuccessCheckmark({
    super.key,
    this.size = 80,
    this.color,
    this.duration = const Duration(milliseconds: 800),
    this.onComplete,
  });

  @override
  State<SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<SuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _circleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _circleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.1), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    HapticFeedback.mediumImpact();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? AppColors.success;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: CustomPaint(
              painter: _CheckmarkPainter(
                color: color,
                circleProgress: _circleAnimation.value,
                checkProgress: _checkAnimation.value,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final Color color;
  final double circleProgress;
  final double checkProgress;

  _CheckmarkPainter({
    required this.color,
    required this.circleProgress,
    required this.checkProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = color.withValues(alpha: 0.2),
    );

    // Animated circle outline
    if (circleProgress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        circleProgress * math.pi * 2,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }

    // Checkmark
    if (checkProgress > 0) {
      final checkPath = Path();
      final startX = center.dx - radius * 0.35;
      final startY = center.dy;
      final midX = center.dx - radius * 0.05;
      final midY = center.dy + radius * 0.25;
      final endX = center.dx + radius * 0.4;
      final endY = center.dy - radius * 0.25;

      // Animate the path drawing
      if (checkProgress < 0.5) {
        final t = checkProgress * 2;
        checkPath.moveTo(startX, startY);
        checkPath.lineTo(
          startX + (midX - startX) * t,
          startY + (midY - startY) * t,
        );
      } else {
        final t = (checkProgress - 0.5) * 2;
        checkPath.moveTo(startX, startY);
        checkPath.lineTo(midX, midY);
        checkPath.lineTo(midX + (endX - midX) * t, midY + (endY - midY) * t);
      }

      canvas.drawPath(
        checkPath,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.circleProgress != circleProgress ||
        oldDelegate.checkProgress != checkProgress;
  }
}

// ============================================================================
// RIPPLE EFFECT - Button feedback
// ============================================================================

class RippleEffect extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final Color? color;
  final Duration duration;

  const RippleEffect({
    super.key,
    required this.child,
    this.trigger = false,
    this.color,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didUpdateWidget(RippleEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rippleColor = widget.color ?? theme.colorScheme.primary;

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _RipplePainter(
                    color: rippleColor,
                    progress: _controller.value,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RipplePainter extends CustomPainter {
  final Color color;
  final double progress;

  _RipplePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.max(size.width, size.height);
    final radius = maxRadius * progress;
    final opacity = 1.0 - progress;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: opacity * 0.3)
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: opacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================================
// ACHIEVEMENT BADGE - Complete organization celebration
// ============================================================================

class AchievementBadge extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final VoidCallback? onComplete;

  const AchievementBadge({
    super.key,
    required this.icon,
    required this.title,
    this.color,
    this.onComplete,
  });

  @override
  State<AchievementBadge> createState() => _AchievementBadgeState();
}

class _AchievementBadgeState extends State<AchievementBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.5), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0.8), weight: 30),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    HapticFeedback.heavyImpact();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = widget.color ?? AppColors.celebrationGold;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [badgeColor, badgeColor.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withValues(
                      alpha: _glowAnimation.value * 0.5,
                    ),
                    blurRadius: 20 + (_glowAnimation.value * 20),
                    spreadRadius: _glowAnimation.value * 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
