import 'package:flutter/material.dart';

/// Custom Page Transitions
///
/// Smooth, playful page transitions for a premium feel.
/// Inspired by iOS navigation and modern app experiences.

// ============================================================================
// SLIDE FADE TRANSITION - Pages slide in with fade
// ============================================================================

class SlideFadeTransition<T> extends PageRoute<T> {
  final Widget page;
  final Duration duration;
  final Curve curve;
  final Offset beginOffset;

  SlideFadeTransition({
    required this.page,
    this.duration = const Duration(milliseconds: 350),
    this.curve = Curves.easeOutCubic,
    this.beginOffset = const Offset(0.0, 0.1),
  });

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return page;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: curve));

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(position: slideAnimation, child: child),
    );
  }
}

// ============================================================================
// SCALE FADE TRANSITION - Modal-style with scale
// ============================================================================

class ScaleFadeTransition<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Curve curve;
  final double beginScale;

  ScaleFadeTransition({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.beginScale = 0.95,
  }) : super(
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final scaleAnimation = Tween<double>(
             begin: beginScale,
             end: 1.0,
           ).animate(CurvedAnimation(parent: animation, curve: curve));

           final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
             CurvedAnimation(
               parent: animation,
               curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
             ),
           );

           return FadeTransition(
             opacity: fadeAnimation,
             child: ScaleTransition(scale: scaleAnimation, child: child),
           );
         },
       );
}

// ============================================================================
// SHARED ELEMENT HERO TRANSITION - Cards expand into detail views
// ============================================================================

class SharedAxisTransition<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final SharedAxisTransitionType transitionType;

  SharedAxisTransition({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
    this.transitionType = SharedAxisTransitionType.horizontal,
  }) : super(
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final fadeAnimation = CurvedAnimation(
             parent: animation,
             curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
           );

           final fadeOutAnimation = CurvedAnimation(
             parent: animation,
             curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
           );

           final slideOffset = switch (transitionType) {
             SharedAxisTransitionType.horizontal => const Offset(0.1, 0.0),
             SharedAxisTransitionType.vertical => const Offset(0.0, 0.1),
             SharedAxisTransitionType.scaled => Offset.zero,
           };

           final slideAnimation =
               Tween<Offset>(begin: slideOffset, end: Offset.zero).animate(
                 CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
               );

           if (transitionType == SharedAxisTransitionType.scaled) {
             return FadeTransition(
               opacity: fadeOutAnimation,
               child: ScaleTransition(
                 scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                   CurvedAnimation(
                     parent: animation,
                     curve: Curves.easeOutCubic,
                   ),
                 ),
                 child: child,
               ),
             );
           }

           return FadeTransition(
             opacity: fadeOutAnimation,
             child: SlideTransition(position: slideAnimation, child: child),
           );
         },
       );
}

enum SharedAxisTransitionType { horizontal, vertical, scaled }

// ============================================================================
// BLUR TRANSITION - Scale with blur effect
// ============================================================================

class BlurTransition<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  BlurTransition({
    required this.page,
    this.duration = const Duration(milliseconds: 350),
  }) : super(
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         opaque: false,
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
             CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
           );

           final fadeAnimation = CurvedAnimation(
             parent: animation,
             curve: Curves.easeOut,
           );

           return FadeTransition(
             opacity: fadeAnimation,
             child: ScaleTransition(
               scale: scaleAnimation,
               alignment: Alignment.center,
               child: child,
             ),
           );
         },
       );
}

// ============================================================================
// STAGGERED CONTENT TRANSITION - Content animates in sequence
// ============================================================================

class StaggeredTransition extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration staggerDelay;
  final Duration duration;
  final Offset slideOffset;

  const StaggeredTransition({
    super.key,
    required this.child,
    required this.index,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
    this.slideOffset = const Offset(0, 20),
  });

  @override
  State<StaggeredTransition> createState() => _StaggeredTransitionState();
}

class _StaggeredTransitionState extends State<StaggeredTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.staggerDelay * widget.index, () {
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
// HERO DIALOG ROUTE - For modal-like transitions
// ============================================================================

class HeroDialogRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  @override
  final bool barrierDismissible;
  @override
  final Color barrierColor;
  @override
  final String barrierLabel;

  HeroDialogRoute({
    required this.builder,
    this.barrierDismissible = true,
    this.barrierColor = const Color(0x80000000),
    this.barrierLabel = 'Dismiss',
  });

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  bool get maintainState => true;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }
}

// ============================================================================
// NAVIGATION HELPERS
// ============================================================================

/// Navigate with slide fade transition
Future<T?> navigateSlide<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(SlideFadeTransition<T>(page: page));
}

/// Navigate with scale fade transition (modal-like)
Future<T?> navigateScale<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(ScaleFadeTransition<T>(page: page));
}

/// Navigate with shared axis transition
Future<T?> navigateSharedAxis<T>(
  BuildContext context,
  Widget page, {
  SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
}) {
  return Navigator.of(
    context,
  ).push<T>(SharedAxisTransition<T>(page: page, transitionType: type));
}

/// Navigate with blur transition
Future<T?> navigateBlur<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(BlurTransition<T>(page: page));
}

/// Navigate and replace with slide fade transition
Future<T?> navigateReplaceSlide<T>(BuildContext context, Widget page) {
  return Navigator.of(
    context,
  ).pushReplacement<T, T>(SlideFadeTransition<T>(page: page));
}
