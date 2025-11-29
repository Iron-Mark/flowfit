import 'package:flutter/material.dart';

/// A widget that applies a gentle bobbing idle animation to its child.
///
/// This animation creates a continuous 2-second loop with 8px vertical movement
/// using an easeInOut curve to simulate breathing or gentle floating motion.
///
/// Requirements: 9.1, 9.2, 9.3, 9.5
class BuddyIdleAnimation extends StatefulWidget {
  final Widget child;

  const BuddyIdleAnimation({super.key, required this.child});

  @override
  State<BuddyIdleAnimation> createState() => _BuddyIdleAnimationState();
}

class _BuddyIdleAnimationState extends State<BuddyIdleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Create a 2-second animation controller that repeats with reverse
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Create animation with 8px vertical movement and easeInOut curve
    _animation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }

  @override
  void dispose() {
    // Properly dispose animation controller to prevent memory leaks
    _controller.dispose();
    super.dispose();
  }
}
