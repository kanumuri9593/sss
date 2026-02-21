import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom Curved Bottom Navigation Bar
///
/// A floating, frosted glass navigation bar with animated icon transitions.
/// Inspired by Apple's design language and modern app navigation patterns.

class CurvedNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<CurvedNavBarItem> items;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final double blur;
  final double elevation;
  final bool showLabels;
  final Widget? centerButton;
  final VoidCallback? onCenterButtonTap;

  const CurvedNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.blur = 25.0,
    this.elevation = 20.0,
    this.showLabels = true,
    this.centerButton,
    this.onCenterButtonTap,
  });

  @override
  State<CurvedNavBar> createState() => _CurvedNavBarState();
}

class _CurvedNavBarState extends State<CurvedNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ?? theme.colorScheme.surface;
    final selectedColor = widget.selectedColor ?? theme.colorScheme.primary;
    final unselectedColor =
        widget.unselectedColor ??
        theme.colorScheme.onSurface.withValues(alpha: 0.5);

    final hasCenter = widget.centerButton != null;
    final itemCount = widget.items.length + (hasCenter ? 1 : 0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: selectedColor.withValues(alpha: 0.15),
            blurRadius: widget.elevation,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: isDark ? 0.8 : 0.92),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.1,
                ),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(itemCount, (index) {
                // Center button
                if (hasCenter && index == itemCount ~/ 2) {
                  return _CenterButton(
                    onTap: widget.onCenterButtonTap,
                    color: selectedColor,
                    child: widget.centerButton!,
                  );
                }

                // Adjust index for items after center
                final itemIndex = hasCenter && index > itemCount ~/ 2
                    ? index - 1
                    : index;

                if (itemIndex >= widget.items.length) return const SizedBox();

                final item = widget.items[itemIndex];
                final isSelected = itemIndex == widget.currentIndex;

                return _NavBarItem(
                  item: item,
                  isSelected: isSelected,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  showLabel: widget.showLabels,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onTap(itemIndex);
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// NAV BAR ITEM
// ============================================================================

class _NavBarItem extends StatefulWidget {
  final CurvedNavBarItem item;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final bool showLabel;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.showLabel,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected
        ? widget.selectedColor
        : widget.unselectedColor;
    final icon = widget.isSelected ? widget.item.activeIcon : widget.item.icon;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? widget.selectedColor.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glow effect when selected
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (widget.isSelected)
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.selectedColor.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          icon,
                          key: ValueKey(widget.isSelected),
                          color: color,
                          size: widget.isSelected ? 26 : 24,
                        ),
                      ),
                    ],
                  ),
                  if (widget.showLabel) ...[
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: widget.isSelected ? 11 : 10,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: color,
                      ),
                      child: Text(widget.item.label),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// CENTER BUTTON - Floating center action button
// ============================================================================

class _CenterButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color color;

  const _CenterButton({required this.child, this.onTap, required this.color});

  @override
  State<_CenterButton> createState() => _CenterButtonState();
}

class _CenterButtonState extends State<_CenterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        HapticFeedback.mediumImpact();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.color, widget.color.withValues(alpha: 0.8)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ============================================================================
// NAV BAR ITEM MODEL
// ============================================================================

class CurvedNavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const CurvedNavBarItem({
    required this.icon,
    IconData? activeIcon,
    required this.label,
  }) : activeIcon = activeIcon ?? icon;
}

// ============================================================================
// MORPHING FAB - FAB that morphs based on context
// ============================================================================

class MorphingFAB extends StatefulWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;
  final Color? color;
  final bool extended;

  const MorphingFAB({
    super.key,
    required this.icon,
    this.label,
    this.onTap,
    this.color,
    this.extended = false,
  });

  @override
  State<MorphingFAB> createState() => _MorphingFABState();
}

class _MorphingFABState extends State<MorphingFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _widthAnimation = Tween<double>(
      begin: 56.0,
      end: 140.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.extended) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(MorphingFAB oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.extended != oldWidget.extended) {
      if (widget.extended) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
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
    final color = widget.color ?? theme.colorScheme.primary;

    return GestureDetector(
      onTapDown: (_) => HapticFeedback.lightImpact(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: widget.extended ? 140 : 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withValues(alpha: 0.85)],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Center(
                    child: widget.extended && widget.label != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.icon,
                                color: theme.colorScheme.onPrimary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.label!,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Icon(widget.icon, color: theme.colorScheme.onPrimary),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
