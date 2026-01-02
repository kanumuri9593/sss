import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

/// Spring Animation System
///
/// Physics-based animations that feel alive and playful.
/// Inspired by iOS spring animations and Duolingo's playful motion.

// ============================================================================
// SPRING SCALE - Bouncy scale on tap (like iOS buttons)
// ============================================================================

class SpringScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;
  final bool enableHaptics;
  final Duration duration;

  const SpringScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.95,
    this.enableHaptics = true,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<SpringScale> createState() => _SpringScaleState();
}

class _SpringScaleState extends State<SpringScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: const SpringCurve(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
    if (widget.enableHaptics) {
      HapticFeedback.selectionClick();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null || widget.onLongPress != null
          ? _onTapDown
          : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: _onTapCancel,
      onLongPress: widget.onLongPress,
      child: ScaleTransition(scale: _animation, child: widget.child),
    );
  }
}

// ============================================================================
// SPRING SLIDE - Elastic slide transitions
// ============================================================================

class SpringSlide extends StatefulWidget {
  final Widget child;
  final Offset beginOffset;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  const SpringSlide({
    super.key,
    required this.child,
    this.beginOffset = const Offset(0, 50),
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.curve = const SpringCurve(),
  });

  @override
  State<SpringSlide> createState() => _SpringSlideState();
}

class _SpringSlideState extends State<SpringSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value,
          child: Opacity(opacity: _fadeAnimation.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}

// ============================================================================
// SPRING ROTATE - Playful rotation with overshoot
// ============================================================================

class SpringRotate extends StatefulWidget {
  final Widget child;
  final double turns;
  final Duration duration;
  final bool autoStart;
  final VoidCallback? onComplete;

  const SpringRotate({
    super.key,
    required this.child,
    this.turns = 1.0,
    this.duration = const Duration(milliseconds: 800),
    this.autoStart = true,
    this.onComplete,
  });

  @override
  State<SpringRotate> createState() => _SpringRotateState();
}

class _SpringRotateState extends State<SpringRotate>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _rotateAnimation =
        Tween<double>(begin: 0.0, end: widget.turns * 2 * 3.14159).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const SpringCurve(damping: 12, stiffness: 180),
          ),
        );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    if (widget.autoStart) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(angle: _rotateAnimation.value, child: child);
      },
      child: widget.child,
    );
  }
}

// ============================================================================
// WOBBLE - Attention-grabbing wiggle effect
// ============================================================================

class Wobble extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double intensity;
  final bool autoStart;
  final int repeatCount;

  const Wobble({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.intensity = 0.05,
    this.autoStart = true,
    this.repeatCount = 3,
  });

  @override
  State<Wobble> createState() => _WobbleState();
}

class _WobbleState extends State<Wobble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _wobbleAnimation;
  int _currentRepeat = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _wobbleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: widget.intensity),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: widget.intensity, end: -widget.intensity),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -widget.intensity, end: widget.intensity * 0.5),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: widget.intensity * 0.5, end: 0.0),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _currentRepeat++;
        if (_currentRepeat < widget.repeatCount) {
          _controller.forward(from: 0);
        }
      }
    });

    if (widget.autoStart) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void startWobble() {
    _currentRepeat = 0;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(angle: _wobbleAnimation.value, child: child);
      },
      child: widget.child,
    );
  }
}

// ============================================================================
// BOUNCE IN - Entry animation with personality
// ============================================================================

class BounceIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double from;
  final Curve curve;

  const BounceIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.from = 0.0,
    this.curve = const SpringCurve(),
  });

  @override
  State<BounceIn> createState() => _BounceInState();
}

class _BounceInState extends State<BounceIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _scaleAnimation = Tween<double>(
      begin: widget.from,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(opacity: _fadeAnimation.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}

// ============================================================================
// STAGGERED ANIMATION - Animate children in sequence
// ============================================================================

class StaggeredColumn extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDuration;
  final Duration itemDuration;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const StaggeredColumn({
    super.key,
    required this.children,
    this.staggerDuration = const Duration(milliseconds: 100),
    this.itemDuration = const Duration(milliseconds: 400),
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: List.generate(
        children.length,
        (index) => SpringSlide(
          delay: staggerDuration * index,
          duration: itemDuration,
          child: children[index],
        ),
      ),
    );
  }
}

// ============================================================================
// PULSE - Pulsing attention animation
// ============================================================================

class Pulse extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final bool autoStart;

  const Pulse({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.autoStart = true,
  });

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: widget.maxScale),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: widget.maxScale, end: widget.minScale),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: widget.minScale, end: 1.0),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.autoStart) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scaleAnimation, child: widget.child);
  }
}

// ============================================================================
// FLOAT - Gentle floating animation
// ============================================================================

class Float extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double distance;
  final bool autoStart;

  const Float({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2000),
    this.distance = 8.0,
    this.autoStart = true,
  });

  @override
  State<Float> createState() => _FloatState();
}

class _FloatState extends State<Float> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _floatAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -widget.distance),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -widget.distance, end: 0.0),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.autoStart) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ============================================================================
// SPRING CURVE - Custom spring physics curve
// ============================================================================

class SpringCurve extends Curve {
  final double damping;
  final double stiffness;
  final double mass;

  const SpringCurve({this.damping = 15, this.stiffness = 200, this.mass = 1});

  @override
  double transformInternal(double t) {
    final spring = SpringSimulation(
      SpringDescription(mass: mass, stiffness: stiffness, damping: damping),
      0,
      1,
      0,
    );
    return spring.x(t);
  }
}

// ============================================================================
// ELASTIC CURVE - Elastic overshoot curve
// ============================================================================

class ElasticCurve extends Curve {
  final double period;

  const ElasticCurve({this.period = 0.4});

  @override
  double transformInternal(double t) {
    final s = period / 4;
    final postFix = math.pow(2, -10 * t);
    return (postFix * math.sin((t - s) * (2 * math.pi) / period) + 1)
        .toDouble();
  }
}
